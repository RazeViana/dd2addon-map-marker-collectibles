# Chest coverage patch

Use the installed Title Update 4.0 game files as the placement source for the next stable patch, v1.5.1.

The accepted scan found 94 omitted Gm83_102-family chest identities at 86 distinct positions and three additional quest-linked chest identities. Add a Spoils Chests category for the former and Norgan Quest Chests for the latter. Use a distinct Spoils symbol enabled by default. Preserve exact native identities and coordinates, including alternate event identities at the same position; do not manufacture loot or unlock rules.

Lost Rites already has 185 positions. Show its potential positions by default independently of the ordinary DLC availability filter, using a separate saved option for each repeatable category. Turning potential positions off shows only loaded chests or positions with evaluated availability. Potential locations do not promise an active event or available reward. Ordinary unresolved quest gates remain guarded.

Derive each trial's UI map ID and rectangle from the installed map resources and its placement source. Trial coordinates must not leak onto Norgan or base maps. Use the selected map, rather than the player's current trial, when routing full-map markers. Use the minimap's current map ID for nearby markers. Do not infer individual floor assignments from height: the extracted records have no verified floor labels. Full-map trial locations cover the selected trial; minimap height arrows remain available.

A currently loaded closed repeatable chest overrides an older collected save context. Preserve base-game behavior, existing preferences, the excluded Vernworth chest, DLC access checks and unrelated work. Native DLC rendering and event renewal require an in-game acceptance check; automated checks must not be described as that check.

Create fresh v1.5.1 release materials without overwriting published v1.5 files. Align README, Nexus page/file description, changelog and GitHub notes. Nexus file description is plain text, 1–250 characters. Default branch is master. All authorship remains Raze and existing source attribution.
