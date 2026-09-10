"""Exercise the release builder without changing published upload packages."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]


class PackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Copy only build inputs into an isolated root; never run against nexus-upload/1.0.
        cls.temp = tempfile.TemporaryDirectory(prefix="map-markers-build-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.root = Path(cls.temp.name).resolve()
        assert cls.root.parent == Path(tempfile.gettempdir()).resolve()
        for directory in ("scripts", "reframework", "natives", "assets"):
            shutil.copytree(ROOT / directory, cls.root / directory,
                            ignore=shutil.ignore_patterns("__pycache__"))
        for name in ("modinfo.ini", "README.md", "CHANGELOG.md", "THIRD_PARTY_NOTICES.md"):
            shutil.copy2(ROOT / name, cls.root / name)
        subprocess.run([sys.executable, str(cls.root / "scripts/build.py")],
                       cwd=cls.root, check=True, capture_output=True, text=True)
        cls.archive = next((cls.root / "dist").glob("*.zip"))

    def test_install_preserves_crowded_cities_files(self):
        # Installed paths from Crowded Cities / MoreNPC 1.0.0's Fluffy manifest.
        existing = {"README.md": b"Crowded Cities documentation",
                    "reframework/autorun/MoreNPC.lua": b"Crowded Cities runtime"}
        game = self.root / "game"
        for name, data in existing.items():
            path = game / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        with ZipFile(self.archive) as package:
            overlaps = set(existing) & set(package.namelist())
            self.assertFalse(overlaps, f"Fluffy would report overwritten files: {overlaps}")
            package.extractall(game)
        for name, data in existing.items():
            self.assertEqual((game / name).read_bytes(), data, f"Another mod was overwritten: {name}")

    def test_documentation_and_credit_link_are_preserved(self):
        with ZipFile(self.archive) as package:
            for name in ("README.md", "CHANGELOG.md", "THIRD_PARTY_NOTICES.md"):
                matches = [entry for entry in package.namelist() if Path(entry).name == name]
                self.assertEqual(len(matches), 1, f"Missing or duplicate documentation: {name}")
                self.assertEqual(package.read(matches[0]), (ROOT / name).read_bytes())
                self.assertGreater(len(Path(matches[0]).parts), 1, "Generic documentation at game root")
            readme = next(entry for entry in package.namelist() if Path(entry).name == "README.md")
            credit_link = (Path(readme).parent / "THIRD_PARTY_NOTICES.md").as_posix()
            self.assertIn(credit_link, package.namelist(), "Packaged README credit link is broken")

    def test_height_indicator_texture_is_packaged_and_referenced(self):
        import struct
        with ZipFile(self.archive) as package:
            texture_path = "natives/stm/raze/mapmarkers/height-arrows.tex.251211553"
            self.assertIn(texture_path, package.namelist(), "Height arrows have no installed texture")
            atlas = package.read("natives/stm/raze/mapmarkers/minimap.uvs.8")
            header = struct.unpack_from("<6I4Q", atlas)
            self.assertEqual((header[1], header[2]), (4, 4))
            texture_table, sequences, patterns, strings = header[6:]
            offset = struct.unpack_from("<Q", atlas, texture_table + 3 * 40 + 8)[0]
            resource = atlas[strings + offset * 2:].decode("utf-16le").split("\0")[0]
            self.assertEqual(resource, "raze/mapmarkers/height-arrows.tex")
            count, first = struct.unpack_from("<2I", atlas, sequences + 3 * 8)
            self.assertEqual(count, 2, "Up and down glyphs must both be available")
            for index, expected_uv in enumerate(((0, 0, 0.5, 1), (0.5, 0, 1, 1))):
                pattern = struct.unpack_from("<Q4f2i", atlas, patterns + (first + index) * 32)
                self.assertEqual(pattern[1:5], expected_uv)
                self.assertEqual(pattern[5], 3, "Indicator uses the wrong texture")
            texture = package.read(texture_path)
            self.assertEqual(struct.unpack_from("<IIHH", texture), (0x00584554, 251211553, 256, 128))
            self.assertEqual(len(texture), 56 + 256 * 128 * 4)

    def test_rejects_shared_or_duplicate_install_paths(self):
        sys.path.insert(0, str(ROOT / "scripts"))
        from build import validate_package_paths
        for name in ("README.md", "docs/README.md", "reframework/autorun/MoreNPC.lua",
                     "docs/raze_MapMarkersAndCollectables/../../README.md"):
            with self.subTest(name=name), self.assertRaises(AssertionError):
                validate_package_paths([name])
        with self.assertRaisesRegex(AssertionError, "Duplicate package path"):
            validate_package_paths(["docs/raze_MapMarkersAndCollectables/README.md",
                                    "docs/raze_MapMarkersAndCollectables/readme.md"])
        for alias in ("docs/raze_MapMarkersAndCollectables/./README.md",
                      "docs/raze_MapMarkersAndCollectables//README.md"):
            with self.subTest(alias=alias), self.assertRaises(AssertionError):
                validate_package_paths(["docs/raze_MapMarkersAndCollectables/README.md", alias])

    def test_plain_text_nexus_description_build(self):
        import json
        version = dict(line.split("=", 1) for line in (self.root / "modinfo.ini").read_text().splitlines())["version"]
        upload = self.root / "nexus-upload" / version
        upload.mkdir(parents=True)
        listing = {
            "version": version,
            "main_file": {"version": version, "archive": self.archive.name, "description": "x" * 250},
            "description_file": "DESCRIPTION.txt"
        }
        (upload / "listing.json").write_text(json.dumps(listing), encoding="utf-8")
        (upload / "DESCRIPTION.txt").write_text("Plain-text Nexus description.\n", encoding="utf-8")
        result = subprocess.run([sys.executable, str(self.root / "scripts/build.py")],
                                cwd=self.root, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((upload / self.archive.name).read_bytes(), self.archive.read_bytes())
        self.assertTrue((upload / "SHA256SUMS.txt").is_file())
        self.assertTrue((upload / "FILE-DESCRIPTION.txt").is_file(), "Missing copy-ready file description")
        self.assertEqual((upload / "FILE-DESCRIPTION.txt").read_text(encoding="utf-8"), "x" * 250)
        # Invalid descriptions must be rejected before any release output is replaced.
        outputs = [self.archive, upload / self.archive.name, upload / "FILE-DESCRIPTION.txt",
                   upload / "SHA256SUMS.txt", upload / "package-manifest.json"]
        before = {path: path.read_bytes() for path in outputs}
        for invalid in ("x" * 251, "", "   ", None, 250):
            with self.subTest(description=repr(invalid)):
                listing["main_file"]["description"] = invalid
                (upload / "listing.json").write_text(json.dumps(listing), encoding="utf-8")
                result = subprocess.run([sys.executable, str(self.root / "scripts/build.py")],
                                        cwd=self.root, capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0, "Invalid file description was accepted")
                self.assertIn("250", result.stderr)
                self.assertEqual({path: path.read_bytes() for path in outputs}, before)


if __name__ == "__main__":
    unittest.main()
