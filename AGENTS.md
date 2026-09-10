# Repository instructions

## Git branch naming

- Use `master` as the default Git branch name. Use `main` only if Raze explicitly requests it for this repository.

## Contributor attribution

- Do not identify an assistant or its provider as a contributor or author in commits, code, documentation, changelogs, pull requests, or other attribution.

## Release materials

- Every release must include a plain-text Nexus file description of no more than 250 characters.
- Store that description in `main_file.description` in the release's `nexus-upload/<version>/listing.json`. The builder generates the copy-ready `FILE-DESCRIPTION.txt` and rejects empty or overlong descriptions.
- Keep the file description, page description, changelog, and GitHub release notes aligned with the packaged features.
