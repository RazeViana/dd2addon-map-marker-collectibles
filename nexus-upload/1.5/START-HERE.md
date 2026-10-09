# Nexus upload kit - version 1.5

Unpublished Dark Arisen test package. Existing-save loading and full-map/minimap markers passed an in-game check on Title Update 4.0 with compatible REFramework. Native DLC acceptance is pending; the release notes and page describe the supported scope and unresolved activation rules.

The DLC is optional, and new expansion markers/artwork start enabled when it is available. The installed-expansion access check passed natively; base-only behavior and the exact Vernworth chest exclusion have automated coverage. `DESCRIPTION.txt` retains the feature and settings guide in shorter sections, with Dark Arisen support first.

- `Map-Markers-and-Collectables-by-Raze-v1.5.zip`: complete Fluffy/manual package.
- `listing.json` and `FILE-DESCRIPTION.txt`: metadata and copy-ready file description, limited to 250 characters.
- `DESCRIPTION.txt`: plain-text page description.
- `RELEASE-NOTES.md`, `CHANGELOG.md`, `NEXUS-DETAILS.txt`: aligned release copy and details.
- `SHA256SUMS.txt`, `package-manifest.json`: archive and payload hashes.
- `images/`: existing branding and gameplay image. The old gameplay image does not show DLC additions.

Use a compatible REFramework, close DD2, and install the entire ZIP. Preserve the settings JSON. The 2.0 quest experiment is separate. Follow the source terms in [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md); Donation Points remain disabled. Publishing a GitHub release does not upload to Nexus.

Rebuild with `python tests/run.py` and `python scripts/build.py` using the documented dependencies. The builder generates the archive, file description, changelog copy and hashes without changing earlier kits.
