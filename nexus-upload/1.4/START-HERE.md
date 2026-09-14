# Nexus upload kit - version 1.4

This folder contains the complete v1.4 package and copy-ready Nexus materials. Nexus uploading is manual; publishing the GitHub release does not update the Nexus page.

## Files to use

- [Map-Markers-and-Collectables-by-Raze-v1.4.zip](Map-Markers-and-Collectables-by-Raze-v1.4.zip) - main download.
- [NEXUS-DETAILS.txt](NEXUS-DETAILS.txt) - summary, file description, update instructions and version changelog.
- [FILE-DESCRIPTION.txt](FILE-DESCRIPTION.txt) - main-file description, at most 250 characters.
- [DESCRIPTION.txt](DESCRIPTION.txt) - complete plain-text page description.
- [listing.json](listing.json) - structured upload metadata.
- [RELEASE-NOTES.md](RELEASE-NOTES.md) and [CHANGELOG.md](CHANGELOG.md) - GitHub announcement and full history.
- [images/logo.png](images/logo.png), [images/banner.png](images/banner.png) and [images/minimap-gameplay.jpg](images/minimap-gameplay.jpg) - existing branding and gameplay image. The gameplay image predates v1.4 and does not demonstrate its new features.
- [SHA256SUMS.txt](SHA256SUMS.txt) and [package-manifest.json](package-manifest.json) - archive checksum and file hashes.

## Upload settings

Game: Dragon's Dogma 2. Mod: Map Markers and Collectables by Raze. Author: Raze. Version: 1.4. Category: User Interface. Download category: Main Files. REFramework is required. Donation Points remain disabled under the recorded source terms. Retain the credits and source notice in [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

This version refreshes and reconciles chest data, adds progression filtering and chest appearance choices, adds the red first-token marker, and fixes full-map icon overlap and chest fog handling on cave/city local maps. The new progression filter and first-token marker start enabled. Existing preferences are kept, and chest categories must be enabled to show chests.

Install the complete ZIP and restart the game. Keep the existing settings file. Automated Lua, Python, syntax, atlas and package checks pass, and Raze reported successful testing of the development build. The final chest reconciliation matches the fresh extraction.

## Rebuilding

Run `python tests/run.py` followed by `python scripts/build.py` with the dependencies in [DEVELOPMENT.md](../../docs/DEVELOPMENT.md). The builder refreshes this version's ZIP, changelog, file description, checksum and package manifest while preserving earlier versions. Keep `main_file.description` in `listing.json` nonempty and within 250 characters.
