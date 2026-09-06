# Nexus upload kit — version 1.0

**Status: prepared locally; publication awaits gibbed's permission.** Raze confirmed on 2026-09-06 that permission has not been obtained. The installable archive includes modified Almanac code and its original datasets. Nothing has been uploaded or sent.

## Files

- `Map-Markers-and-Collectables-by-Raze-v1.0.zip` — the main download. Upload this ZIP as the mod file, not the entire upload-kit folder.
- `description.bbcode.txt` — formatted Nexus description, ready for the BBCode/source editor after permission is obtained.
- `listing.json` — title, summary, author, category, requirement, and file details to copy into Nexus.
- `CHANGELOG.md` — version 1.0 release notes.
- `permission-request.txt` — an unsent message draft to gibbed.
- `SHA256SUMS.txt` — checksum for the main download.
- `images/minimap-gameplay.jpg` — an unedited gameplay capture showing the custom minimap markers. Suggested caption: "Nearby collectable markers on the minimap during exploration."

## Publishing

1. Obtain written permission from gibbed covering a separately named Nexus release, the modified code, and the bundled location datasets. Keep the reply and follow any conditions. The current upstream permissions prohibit Donation Points and paid asset use.
2. Update the permission record in this document and `THIRD_PARTY_NOTICES.md` to reflect the actual grant, then rebuild the ZIP and refresh its checksum. Retain the original credits in the listing and files.
3. Create a Dragon's Dogma 2 mod page titled **Map Markers and Collectables by Raze**, version **1.0**, author **Raze**, category **User Interface**. Add **REFramework** as a required Nexus mod. Suggested tags: **User Interface**, **Quality of Life**.
4. Paste the short summary and full description, add the version 1.0 changelog, and upload the main ZIP under **Main Files**. Use the file description in `listing.json`.
5. Add the included minimap gameplay image. A full-map screenshot and a settings screenshot showing both capacities can be added as further examples. Use captures of this adaptation rather than the original Almanac preview. Avoid images of unrelated mod menus or private desktop information.
6. Keep Donation Points disabled. Set distribution permissions to match the rights actually granted; do not describe the bundled original material as wholly created by Raze or available for unrestricted reuse.

## Package details

The ZIP supports manual installation into the folder containing `DD2.exe` and has `modinfo.ini` at its root for Fluffy Mod Manager. It contains seven Lua files, twelve location JSON files, and four metadata/documentation files. REFramework, personal settings, runtime reports, probes, development tools, backups, and the original preview are excluded.

Public numbering starts at 1.0. Earlier ZIPs in the project's `dist` folder are development builds and are not the upload target. The tested capacities and minimap fixes are included in this 1.0 package.

## Permission sources

Checked on 2026-09-06:

- [Arisen's Almanac — Permissions and credits](https://www.nexusmods.com/dragonsdogma2/mods/194): permission required for modification and asset reuse; Donation Points not allowed for mods using its assets.
- [Nexus file submission guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines): credit does not replace permission to reuse another author's submission.
- [Nexus best practices for mod authors](https://help.nexusmods.com/article/136-best-practices-for-mod-authors): clear requirements, installation instructions, file descriptions, and representative images.
