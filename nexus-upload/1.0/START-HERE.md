# Nexus upload kit â€” version 1.0

This folder contains the prepared release files. The package has not been uploaded to Nexus. Source credits and the unresolved publication permissions are documented in [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

## Upload files

- `Map-Markers-and-Collectables-by-Raze-v1.0.zip` â€” main mod download. Upload this ZIP, not the whole kit folder.
- [DESCRIPTION.md](DESCRIPTION.md) â€” Nexus description in Markdown. Use its rendered content in the Nexus rich-text editor; the source file is maintained as Markdown.
- [listing.json](listing.json) â€” title, summary, author, category, requirement, and download details.
- [CHANGELOG.md](CHANGELOG.md) â€” release notes.
- `images/minimap-gameplay.jpg` â€” gameplay capture showing custom minimap markers. Caption: "Nearby collectable markers on the minimap during exploration."
- `SHA256SUMS.txt` and `package-manifest.json` â€” archive checksum and file manifest.

## Page details

| Field | Value |
|---|---|
| Game | Dragon's Dogma 2 |
| Mod name | Map Markers and Collectables by Raze |
| Version | 1.0 |
| Author | Raze |
| Category | User Interface |
| Suggested tags | User Interface, Quality of Life |
| Required mod | [REFramework](https://www.nexusmods.com/dragonsdogma2/mods/8) |
| Download category | Main Files |
| Donation Points | Disabled under the current source terms |

Copy the short summary and file description from `listing.json`, add the Markdown description and changelog, and attach the gameplay image. A full-map screenshot can be added as another example. Resolve publication rights as described in the third-party notice before publishing; preserve the credits at the bottom of the description.

## Package and rebuild

The archive contains seven Lua files, twelve location JSON files, and four metadata/documentation files. It supports manual installation and includes `modinfo.ini` at the root for Fluffy Mod Manager. REFramework, personal preferences, runtime reports, probes, and development files are excluded.

Run `python tests/run.py` and `python scripts/build.py` from the project root. The builder refreshes the main archive, the copy in this folder, the changelog, the checksum, and the file manifest.
