"""Validate the mod's static assets and build an installable ZIP."""
import hashlib
import json
import math
from pathlib import Path
import re
import uuid
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "raze_MapMarkersAndCollectables"
DATA = ROOT / "reframework/data" / PREFIX
EXPECTED_FILES = {"10", "11", "12", "13", "161", "167", "465", "495", "653", "692", "693", "694"}


def build():
    metadata = dict(line.split("=", 1) for line in (ROOT / "modinfo.ini").read_text(encoding="utf-8").splitlines() if "=" in line)
    version = metadata["version"]
    assert re.fullmatch(r"\d+\.\d+(?:\.\d+)?", version), "Invalid release version"
    assert f'imgui.text("v{version} - ' in (ROOT / f"reframework/autorun/{PREFIX}.lua").read_text(encoding="utf-8"), "UI version mismatch"
    assert f'version = "{version}"' in (ROOT / f"reframework/autorun/{PREFIX}/diagnostics.lua").read_text(encoding="utf-8"), "Diagnostics version mismatch"
    assert f"**Current version: {version}.**" in (ROOT / "README.md").read_text(encoding="utf-8"), "README version mismatch"
    datasets = sorted(DATA.glob("*.json"))
    assert {path.stem for path in datasets} == EXPECTED_FILES, "Missing or unexpected location datasets"
    location_count = 0
    with ZipFile(ROOT / "reference/almanac-source.zip") as original:
        for path in datasets:
            raw = path.read_bytes()
            previous = original.read(f"reframework/data/gibbed_Almanac/{path.name}")
            assert hashlib.sha256(raw).digest() == hashlib.sha256(previous).digest(), f"Dataset changed: {path.name}"
            locations = json.loads(raw)["locations"]
            for key, position in locations.items():
                assert str(uuid.UUID(key)) == key, f"Invalid GUID in {path.name}"
                assert all(type(position[axis]) in (int, float) and math.isfinite(position[axis]) for axis in ("x", "y", "z"))
            location_count += len(locations)
    files = [ROOT / "modinfo.ini", ROOT / "README.md", ROOT / "CHANGELOG.md", ROOT / "THIRD_PARTY_NOTICES.md"]
    files += sorted((ROOT / "reframework/autorun").rglob("*.lua"))
    files += datasets
    output = ROOT / f"dist/Map-Markers-and-Collectables-by-Raze-v{version}.zip"
    output.parent.mkdir(exist_ok=True)
    with ZipFile(output, "w", ZIP_DEFLATED) as package:
        for path in files:
            package.write(path, path.relative_to(ROOT).as_posix())
    with ZipFile(output) as package:
        assert package.testzip() is None
        assert len(package.namelist()) == len(files)
        assert not any("gibbed_" in name or "_settings.json" in name for name in package.namelist())
    print(f"Validated {len(datasets)} unchanged datasets with {location_count} locations")
    print(f"Built {output} ({len(files)} files, {output.stat().st_size:,} bytes)")


if __name__ == "__main__":
    build()
