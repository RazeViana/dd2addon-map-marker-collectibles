# Nexus upload kit - version 1.4.1

This folder contains the complete v1.4.1 package and copy-ready Nexus materials. Nexus uploading is manual; publishing the GitHub release does not update the Nexus page.

## Files to use

- [Map-Markers-and-Collectables-by-Raze-v1.4.1.zip](Map-Markers-and-Collectables-by-Raze-v1.4.1.zip) - main download.
- [NEXUS-DETAILS.txt](NEXUS-DETAILS.txt) - summary, file description, update instructions and version changelog.
- [FILE-DESCRIPTION.txt](FILE-DESCRIPTION.txt) - main-file description, at most 250 characters.
- [DESCRIPTION.txt](DESCRIPTION.txt) - complete plain-text page description.
- [listing.json](listing.json) - structured upload metadata.
- [RELEASE-NOTES.md](RELEASE-NOTES.md) and [CHANGELOG.md](CHANGELOG.md) - GitHub announcement and full history.
- [images/logo.png](images/logo.png), [images/banner.png](images/banner.png) and [images/minimap-gameplay.jpg](images/minimap-gameplay.jpg) - existing branding and gameplay image. The gameplay image predates v1.4.1 and does not demonstrate its new features.
- [SHA256SUMS.txt](SHA256SUMS.txt) and [package-manifest.json](package-manifest.json) - archive checksum and file hashes.

## Upload settings

Game: Dragon's Dogma 2. Mod: Map Markers and Collectables by Raze. Author: Raze. Version: 1.4.1. Category: User Interface. Download category: Main Files. REFramework is required. Donation Points remain disabled under the recorded source terms. Retain the credits and source notice in [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

This version fixes the first-token marker disappearing when the Sphinx riddle starts and adds **Show after Finder's Token collection**, off by default. Enable it beneath **Show first Seeker's Token** to retain the saved location after pickup or hand-in. It works with existing save records and retains the full v1.4 feature set.

Close the game and install the complete ZIP with Fluffy Mod Manager. For manual installation, copy both reframework and natives into the game folder beside DD2.exe, then restart. Keep reframework/data/raze_MapMarkersAndCollectables_settings.json to retain your choices.

Raze reported that the first-token correction works in-game. The new retention option is covered by automated module, settings and map integration tests; its native visual behaviour after pickup/hand-in remains for the next live test.

## Rebuilding

Run `python tests/run.py` followed by `python scripts/build.py` with the dependencies in [DEVELOPMENT.md](../../docs/DEVELOPMENT.md). The builder refreshes this version's ZIP, changelog, file description, checksum and package manifest while preserving earlier versions. Keep `main_file.description` in `listing.json` nonempty and within 250 characters.
