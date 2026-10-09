# Nexus upload kit - version 1.5

Dark Arisen Edition release package. Existing-save loading and full-map/minimap markers passed an in-game check on Title Update 4.0 with compatible REFramework. Native DLC acceptance is pending; the release notes and page describe the supported scope and unresolved activation rules.

Mod page: [Nexus Mods](https://www.nexusmods.com/dragonsdogma2/mods/1551). Matching release: [GitHub v1.5](https://github.com/RazeViana/dd2addon-map-marker-collectibles/releases/tag/v1.5).

The ZIP is the exact published Nexus v1.5 download. Its original manifest and checksum are preserved; the accompanying release copy and branding reflect publication.

The DLC is optional, and new expansion markers/artwork start enabled when it is available. The installed-expansion access check passed natively; base-only behavior and the exact Vernworth chest exclusion have automated coverage. `DESCRIPTION.txt` retains the feature and settings guide in shorter sections, with Dark Arisen support first.

- `Map-Markers-and-Collectables-by-Raze-v1.5.zip`: complete Fluffy/manual package.
- `listing.json` and `FILE-DESCRIPTION.txt`: metadata and copy-ready file description, limited to 250 characters.
- `DESCRIPTION.txt`: plain-text page description.
- `RELEASE-NOTES.md`, `CHANGELOG.md`, `NEXUS-DETAILS.txt`: aligned release copy and details.
- `SHA256SUMS.txt`, `package-manifest.json`: archive and payload hashes.
- `images/`: matching Dark Arisen Edition thumbnail and banner, plus the earlier gameplay image. The old gameplay image does not show DLC additions.

Use a compatible REFramework, close DD2, and install the entire ZIP. Preserve the settings JSON. The 2.0 quest experiment is separate. Follow the source terms in [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md); Donation Points remain disabled. Publishing a GitHub release does not upload to Nexus.

Validate with `python tests/run.py` using the documented dependencies. `python scripts/build.py` generates an archive, file description, changelog copy and hashes without changing earlier kits. Rebuilding after publication updates to the documentation changes the ZIP hash; preserve this released ZIP and its original manifest/checksum when maintaining v1.5.
