# Chest progression and customization

Update the v1.4 development build with the 54 newly extracted chest GUIDs. Following the user's subsequent alignment request, retire the two original GUIDs absent from the fresh extraction and correct the one position difference beyond the 0.01-world-unit comparison tolerance. Preserve retained GUIDs for collection tracking and record original provenance, removals and corrected positions in the development manifest. Record extracted placement conditions separately from coordinates and preserve original dataset attribution.

The user selected categories by chest type, with progression filters independent of category. Keep the existing small, medium, large, extra-large and special categories and their saved visibility/order. Give categories distinct default chest artwork and colors, and let users choose artwork or a native game symbol and colors independently for acquired/unacquired markers. Existing saved appearance settings take precedence over new defaults.

Read acquisition from native game/save state without writing to the save or keeping a mod-owned acquisition ledger. A saved positive acquisition result must survive a transient closed loaded object. Clear acquisition caches on save/context replacement and refresh live minimap state. Acquired markers remain governed by their category's acquired setting; progression filtering applies to unacquired chests.

Default `hide_unavailable_chests` to true. Default `reveal_unmoored_chests` to false. The latter permits early display of chests restricted to the Unmoored World; it must not bypass unrelated quest requirements or turn every extra-large chest into an Unmoored-only chest. Derive world restrictions from source catalog membership and native progression metadata. Use verified native read-only evaluation for quest conditions. Evaluate current state after marker caching on both map surfaces and refresh on changes.

Treat missing progression APIs or unresolved availability as unknown. Do not invent a claim that a chest is obtainable. With filtering enabled, suppress unresolved unacquired records and explain unavailable progression checks in the settings UI; disabling the filter is the explicit display override. Preserve collected history regardless of availability metadata.

Add retained Sphinx records only if their sealed reward conditions can be supported reliably; the existing seven chest categories and all requested new placements take priority. Newly exposed sealed rewards must not be represented as currently obtainable merely because their objects spawn.

Validate with Lua runtime and policy regression tests, dataset consistency/provenance tests, unchanged native atlas checks, and package tests. Include a specific in-game checklist for save installation, world transitions and quest availability; do not claim those native behaviors were tested merely from mocks or executable metadata.

Initial scope was a development build. After testing and chest reconciliation, the user authorized the v1.4 release. Preserve unrelated pending release-material edits, keep extracted game resources outside the package, and align release descriptions with the final packaged behavior.
