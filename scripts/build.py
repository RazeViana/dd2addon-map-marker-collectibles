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

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "raze_MapMarkersAndCollectables"
DATA = ROOT / "reframework/data" / PREFIX
EXPECTED_FILES = {"10", "11", "12", "13", "161", "167", "465", "495", "653", "692", "693", "694"}
# Only player-facing runtime files belong in the release, even if debug scripts are staged nearby.
RUNTIME_FILES = [f"reframework/autorun/{PREFIX}.lua"] + [
    f"reframework/autorun/{PREFIX}/{module}.lua"
    for module in ("fog_of_war", "minimap", "nearby", "object_icons", "settings", "sprite_pool")
]
DOCUMENTATION_FILES = ("README.md", "CHANGELOG.md", "THIRD_PARTY_NOTICES.md")


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
    datasets = sorted(DATA.glob("*.json"))
    assert {path.stem for path in datasets} == EXPECTED_FILES, "Missing or unexpected location datasets"
    location_count = 0
    catalog = json.loads((ROOT / "scripts/dataset-manifest.json").read_text(encoding="utf-8"))
    assert set(catalog["files"]) == {path.name for path in datasets}, "Dataset manifest mismatch"
    for path in datasets:
        raw = path.read_bytes()
        expected = catalog["files"][path.name]
        assert hashlib.sha256(raw).hexdigest() == expected["sha256"], f"Dataset changed: {path.name}"
        locations = json.loads(raw)["locations"]
        canonical = json.dumps(locations, sort_keys=True, separators=(",", ":")).encode("utf-8")
        assert hashlib.sha256(canonical).hexdigest() == expected["locations_sha256"], f"Locations changed: {path.name}"
        assert len(locations) == expected["count"], f"Location count changed: {path.name}"
        for key, position in locations.items():
            assert str(uuid.UUID(key)) == key, f"Invalid GUID in {path.name}"
            assert all(type(position[axis]) in (int, float) and math.isfinite(position[axis]) for axis in ("x", "y", "z"))
        location_count += len(locations)
    files = [ROOT / "modinfo.ini", ROOT / "README.md", ROOT / "CHANGELOG.md", ROOT / "THIRD_PARTY_NOTICES.md"]
    files += [ROOT / name for name in RUNTIME_FILES]
    files += datasets
    files += validate_icon_assets()
    output = ROOT / f"dist/Map-Markers-and-Collectables-by-Raze-v{version}.zip"
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
    upload_dir = ROOT / "nexus-upload" / version
    if upload_dir.is_dir():
        listing = json.loads((upload_dir / "listing.json").read_text(encoding="utf-8"))
        assert listing["version"] == listing["main_file"]["version"] == version, "Nexus version mismatch"
        assert listing["main_file"]["archive"] == output.name, "Nexus filename mismatch"
        assert (upload_dir / listing["description_file"]).is_file(), "Nexus description missing"
        shutil.copy2(output, upload_dir / output.name)
        shutil.copy2(ROOT / "CHANGELOG.md", upload_dir / "CHANGELOG.md")
        digest = hashlib.sha256(output.read_bytes()).hexdigest()
        (upload_dir / "SHA256SUMS.txt").write_text(f"{digest}  {output.name}\n", encoding="utf-8")
        (upload_dir / "package-manifest.json").write_text(json.dumps(package_manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Validated {len(datasets)} datasets with {location_count} unchanged locations")
    print(f"Built {output} ({len(files)} files, {output.stat().st_size:,} bytes)")


if __name__ == "__main__":
    build()
