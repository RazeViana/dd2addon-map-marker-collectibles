# Nexus upload kit - version 1.2

This folder contains the 1.2 release package and prepared Nexus page materials. Nexus upload is manual; creating this kit does not update the Nexus page.

## Files to use

- [Map-Markers-and-Collectables-by-Raze-v1.2.zip](Map-Markers-and-Collectables-by-Raze-v1.2.zip) - upload this ZIP as the main download.
- [DESCRIPTION.md](DESCRIPTION.md) - updated page description.
- [listing.json](listing.json) - page summary, version, and download details.
- [RELEASE-NOTES.md](RELEASE-NOTES.md) - version 1.2 release announcement and update instructions.
- [CHANGELOG.md](CHANGELOG.md) - version history.
- [images/logo.png](images/logo.png) and [images/banner.png](images/banner.png) - existing branding.
- [images/minimap-gameplay.jpg](images/minimap-gameplay.jpg) - an existing gameplay image; new height-arrow screenshots can be added separately.
- [SHA256SUMS.txt](SHA256SUMS.txt) and [package-manifest.json](package-manifest.json) - archive checksum and per-file hashes.

## Upload details

| Field | Value |
|---|---|
| Game | Dragon's Dogma 2 |
| Mod name | Map Markers and Collectables by Raze |
| Version | 1.2 |
| Author | Raze |
| Category | User Interface |
| Download category | Main Files |
| Required mod | [REFramework](https://www.nexusmods.com/dragonsdogma2/mods/8) |
| Donation Points | Disabled under the recorded source terms |

Use the summary and file description in `listing.json`, the page text in `DESCRIPTION.md`, and the release notes in `RELEASE-NOTES.md`. Keep the source credits. The existing source and permission record is in [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

The release ZIP includes the new arrow assets. Updating only the Lua script is insufficient. Existing settings can be retained.

## Rebuilding

Run `python tests/run.py` followed by `python scripts/build.py` with the dependencies documented in [DEVELOPMENT.md](../../docs/DEVELOPMENT.md). The builder refreshes this version's ZIP, changelog, checksum, and manifest. It leaves the 1.0 package intact.
