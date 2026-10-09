"""Validate the mod's static assets and build an installable ZIP."""
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import uuid
from zipfile import ZipFile, ZIP_DEFLATED
from icon_assets import validate as validate_icon_assets
from dlc_data import COUNTS as DLC_COUNTS, validate_dlc_availability
from update_chest_data import digest, reconstruct_original

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "raze_MapMarkersAndCollectables"
DATA = ROOT / "reframework/data" / PREFIX
BASE_FILES = {"10", "11", "12", "13", "161", "167", "465", "495", "653", "692", "693", "694"}
EXPECTED_FILES = BASE_FILES | {str(kind) for kind in DLC_COUNTS}
CHEST_METADATA = "chest-availability.json"
DLC_METADATA = "dlc-availability.json"
# Only player-facing runtime files belong in the release, even if debug scripts are staged nearby.
RUNTIME_FILES = [f"reframework/autorun/{PREFIX}.lua"] + [
    f"reframework/autorun/{PREFIX}/{module}.lua"
    for module in ("chest_availability", "chest_game_state", "dlc_collectibles", "first_token", "fog_of_war", "minimap", "nearby", "object_icons", "settings", "sprite_pool")
]
DOCUMENTATION_FILES = ("README.md", "CHANGELOG.md", "THIRD_PARTY_NOTICES.md")


def validate_chest_provenance(dataset, expected):
    locations = dataset['locations']
    assert len(locations) == expected['fresh_count'], 'Chest count differs from verified fresh data'
    assert digest(sorted(locations)) == expected['fresh_guids_sha256'], 'Chest GUIDs differ from verified fresh data'
    if 'base_locations_sha256' in expected:
        added = dataset.get('supplemental_source', {}).get('added_guids', [])
        assert len(added) == len(set(added)) == expected['added_count']
        original = reconstruct_original(locations, added, expected)
        assert len(original) == expected['base_count'] and digest(original) == expected['base_locations_sha256'], 'Original chest provenance changed'


def validate_chest_metadata(metadata, locations_by_type):
    assert metadata.get('schema_version') == 1, 'Unsupported chest availability schema'
    expected = {}
    for kind, locations in locations_by_type.items():
        for guid in locations:
            assert guid not in expected, f'Duplicate chest GUID across types: {guid}'
            expected[guid] = int(kind)
    records = metadata.get('chests')
    assert isinstance(records, dict) and records.keys() == expected.keys(), 'Chest availability coverage mismatch'
    for guid, record in records.items():
        assert record.get('gimmick_id') == expected[guid], f'Wrong chest type in availability: {guid}'
        variants = record.get('variants')
        assert isinstance(variants, list), f'Missing placement variants: {guid}'
        if not variants:
            assert isinstance(record.get('unresolved'), str) and record['unresolved'], f'Unexplained missing availability: {guid}'
        for rule in variants:
            assert rule.get('world') in ('any', 'normal', 'unmoored'), f'Unknown chest world: {guid}'
            assert rule.get('quest_mode', 'and') in ('and', 'or'), f'Unknown quest combination: {guid}'
            assert isinstance(rule.get('quests', []), list)
            for quest in rule.get('quests', []):
                assert type(quest.get('id')) is int and 0 < quest['id'] <= 2147483647
                assert type(quest.get('finish')) is bool
            if 'event_flag' in rule:
                assert rule['event_flag'] in (8, 32, 64), f'Unsupported chest event flag: {guid}'
            if 'unsupported' in rule:
                assert isinstance(rule['unsupported'], str) and rule['unsupported']


def validate_package_paths(names):
    """Fluffy copies payload paths into the game; reserve all of ours to this mod."""
    seen = set()
    owned_directories = (f"docs/{PREFIX}/", f"reframework/autorun/{PREFIX}/",
                         f"reframework/data/{PREFIX}/", "natives/stm/raze/mapmarkers/")
    for name in names:
        assert "\\" not in name and all(part not in ("", ".", "..") for part in name.split("/")), \
            f"Invalid package path: {name}"
        key = name.casefold()
        assert key not in seen, f"Duplicate package path: {name}"
        seen.add(key)
        # modinfo.ini is Fluffy's package metadata, not an installed game file.
        assert (name in ("modinfo.ini", f"reframework/autorun/{PREFIX}.lua")
                or name.startswith(owned_directories)), f"Unowned package path: {name}"


def build():
    metadata = dict(line.split("=", 1) for line in (ROOT / "modinfo.ini").read_text(encoding="utf-8").splitlines() if "=" in line)
    version = metadata["version"]
    assert re.fullmatch(r"\d+\.\d+(?:\.\d+)?", version), "Invalid release version"
    assert f'imgui.text("v{version} - ' in (ROOT / f"reframework/autorun/{PREFIX}.lua").read_text(encoding="utf-8"), "UI version mismatch"
    assert f"**Current version: {version}.**" in (ROOT / "README.md").read_text(encoding="utf-8"), "README version mismatch"
    output = ROOT / f"dist/Map-Markers-and-Collectables-by-Raze-v{version}.zip"
    upload_dir = ROOT / "nexus-upload" / version
    listing = None
    if upload_dir.is_dir():
        listing = json.loads((upload_dir / "listing.json").read_text(encoding="utf-8"))
        assert listing["version"] == listing["main_file"]["version"] == version, "Nexus version mismatch"
        assert listing["main_file"]["archive"] == output.name, "Nexus filename mismatch"
        assert (upload_dir / listing["description_file"]).is_file(), "Nexus description missing"
        file_description = listing["main_file"].get("description")
        assert (isinstance(file_description, str) and file_description.strip()
                and len(file_description) <= 250), "Nexus file description must contain 1-250 characters"
    data_files = sorted(DATA.glob("*.json"))
    assert {path.name for path in data_files} == {name + '.json' for name in EXPECTED_FILES} | {CHEST_METADATA, DLC_METADATA}, "Missing or unexpected data files"
    datasets = [path for path in data_files if path.name not in (CHEST_METADATA, DLC_METADATA)]
    location_count = 0
    chest_locations = {}
    dlc_locations = {}
    seen_guids = set()
    catalog = json.loads((ROOT / "scripts/dataset-manifest.json").read_text(encoding="utf-8"))
    assert set(catalog["files"]) == {path.name for path in datasets}, "Dataset manifest mismatch"
    for path in datasets:
        raw = path.read_bytes()
        expected = catalog["files"][path.name]
        assert hashlib.sha256(raw).hexdigest() == expected["sha256"], f"Dataset changed: {path.name}"
        dataset = json.loads(raw)
        locations = dataset["locations"]
        canonical = json.dumps(locations, sort_keys=True, separators=(",", ":")).encode("utf-8")
        assert hashlib.sha256(canonical).hexdigest() == expected["locations_sha256"], f"Locations changed: {path.name}"
        assert len(locations) == expected["count"], f"Location count changed: {path.name}"
        if int(path.stem) in DLC_COUNTS:
            kind = int(path.stem)
            assert dataset.get('source', {}).get('game_version') == '4.0.0.0', f'Wrong DLC source: {path.name}'
            assert len(locations) == expected['fresh_count'] == DLC_COUNTS[kind], f'DLC count differs from audited data: {path.name}'
            assert digest(sorted(locations)) == expected['fresh_guids_sha256'], f'DLC GUIDs differ from audited data: {path.name}'
            dlc_locations[kind] = locations
        elif path.stem not in ('161', '167'):
            chest_locations[int(path.stem)] = locations
            validate_chest_provenance(dataset, expected)
        for key, position in locations.items():
            assert str(uuid.UUID(key)) == key, f"Invalid GUID in {path.name}"
            assert key not in seen_guids, f"Duplicate GUID across datasets: {key}"
            seen_guids.add(key)
            assert all(type(position[axis]) in (int, float) and math.isfinite(position[axis]) for axis in ("x", "y", "z"))
        location_count += len(locations)
    metadata_path = DATA / CHEST_METADATA
    metadata_raw = metadata_path.read_bytes()
    metadata_manifest = catalog['chest_availability']
    assert metadata_manifest['filename'] == CHEST_METADATA
    assert hashlib.sha256(metadata_raw).hexdigest() == metadata_manifest['sha256'], 'Chest availability data changed'
    chest_metadata = json.loads(metadata_raw)
    validate_chest_metadata(chest_metadata, chest_locations)
    assert len(chest_metadata['chests']) == metadata_manifest['count']
    dlc_metadata_path = DATA / DLC_METADATA
    dlc_metadata_raw = dlc_metadata_path.read_bytes()
    dlc_metadata_manifest = catalog['dlc_availability']
    assert dlc_metadata_manifest['filename'] == DLC_METADATA
    assert hashlib.sha256(dlc_metadata_raw).hexdigest() == dlc_metadata_manifest['sha256'], 'DLC availability data changed'
    dlc_metadata = json.loads(dlc_metadata_raw)
    validate_dlc_availability(dlc_metadata, dlc_locations)
    assert len(dlc_metadata['records']) == dlc_metadata_manifest['count']
    files = [ROOT / "modinfo.ini", ROOT / "README.md", ROOT / "CHANGELOG.md", ROOT / "THIRD_PARTY_NOTICES.md"]
    files += [ROOT / name for name in RUNTIME_FILES]
    files += datasets
    files += [metadata_path, dlc_metadata_path]
    files += validate_icon_assets()
    output.parent.mkdir(exist_ok=True)
    entries = [(path, f"docs/{PREFIX}/{path.name}" if path.parent == ROOT
                and path.name in DOCUMENTATION_FILES else path.relative_to(ROOT).as_posix())
               for path in files]
    validate_package_paths([name for _, name in entries])
    with ZipFile(output, "w", ZIP_DEFLATED) as package:
        for path, name in entries:
            package.write(path, name)
    with ZipFile(output) as package:
        assert package.testzip() is None
        assert len(package.namelist()) == len(files)
        names = set(package.namelist())
        assert not any(re.search(r"diagnostic|probe|debug|_settings\.json", name, re.I) for name in names), "Development files in release"
        assert {name for name in names if name.endswith(".lua")} == set(RUNTIME_FILES)
        for name in RUNTIME_FILES:
            source = package.read(name).decode("utf-8")
            for dependency in re.findall(r'''require\(["']([^"']+)["']\)''', source):
                if dependency.startswith(PREFIX + "."):
                    assert "reframework/autorun/" + dependency.replace(".", "/") + ".lua" in names, f"Missing runtime dependency: {dependency}"
        package_manifest = [{"path": name, "bytes": len(package.read(name)),
                             "sha256": hashlib.sha256(package.read(name)).hexdigest()}
                            for name in package.namelist()]
    if listing is not None:
        shutil.copy2(output, upload_dir / output.name)
        shutil.copy2(ROOT / "CHANGELOG.md", upload_dir / "CHANGELOG.md")
        (upload_dir / "FILE-DESCRIPTION.txt").write_text(file_description, encoding="utf-8", newline="\n")
        archive_digest = hashlib.sha256(output.read_bytes()).hexdigest()
        (upload_dir / "SHA256SUMS.txt").write_text(f"{archive_digest}  {output.name}\n", encoding="utf-8")
        (upload_dir / "package-manifest.json").write_text(json.dumps(package_manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Validated {len(datasets)} datasets with {location_count} manifest-verified locations and chest availability metadata")
    print(f"Built {output} ({len(files)} files, {output.stat().st_size:,} bytes)")


if __name__ == "__main__":
    build()
