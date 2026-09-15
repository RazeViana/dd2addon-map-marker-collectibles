local first_token = require('raze_MapMarkersAndCollectables.first_token')
local guid = '02a4d67e-7828-48ab-925d-6c2153dddd4b'
local other = '0457ce14-0c4c-4d2b-b2fe-ea15215dbfa6'
local empty, collected, proof_key = false, false, guid .. '_0'
local finder_spawned = false
local proof = { isEmpty = function() return empty end, ToString = function() return proof_key end }
local manager = { get_FirstSeekerProof = function() return proof end,
  isGimmickFlag = function(_, flag)
    -- Independently decoded native flags: 18 displays the Finder, 40 is the
    -- ordinary token pickup, and 122 records the Finder's Token pickup.
    if flag == 18 then return finder_spawned end
    if flag == 40 then return true end
    if flag == 122 then return collected end
    error('unexpected gimmick flag ' .. tostring(flag))
  end }
local api = { get_managed_singleton = function(name)
  assert(name == 'app.GimmickManager'); return manager
end }
local positions = { [guid] = { x = 1, y = 2, z = 3 }, [other] = { x = 4, y = 5, z = 6 } }
local tracker = first_token.create(api, positions)
local base = { {key=guid, marker_type={gimmick_id=167}}, {key='chest', marker_type={gimmick_id=10}} }
local markers, signature = tracker:overlay(base, true, 76)
assert(#markers == 2 and markers[1].icon_color == 0xFF0000FF and markers[1].icon_type == 76)
assert(markers[1].pos == positions[guid] and markers[1].id == proof)
assert(markers[1].marker_type.name == "First Seeker's Token")
assert(markers[1].marker_type.fog_setting == 'hide_unexplored_tokens')
assert(markers[2] == base[2] and #base == 2 and base[1].icon_color == nil,
  'overlay must replace the matching ordinary token without changing cached candidates')
assert(signature == 'first-token:' .. guid)
finder_spawned = true
markers = tracker:overlay(base, true, 76)
assert(markers[1].icon_color == 0xFF0000FF and markers[1].pos == positions[guid],
  'starting the Sphinx riddle must not hide the first-token marker')
local late_install = first_token.create(api, positions):overlay({}, true, 76)
assert(#late_install == 1 and late_install[1].pos == positions[guid],
  'installing on an existing save with the Finder spawned must show the saved location')
assert(#tracker:overlay({}, true, 25) == 1, 'acquired/category hiding must not suppress the separate marker')
assert(tracker:overlay({}, true, 25)[1].icon_type == 25, 'native symbol was ignored')
empty = true
assert(tracker:overlay(base, true, 76) == base, 'no marker before the first collection')
empty, collected = false, true
assert(tracker:overlay(base, true, 76) == base, 'Finder collection must remove the special marker')
-- Saved pickup state is checked afresh; transferring/using the item cannot revive it.
assert(first_token.create(api, positions):overlay(base, true, 76) == base,
  'late installation must honor an already collected Finder token')
markers = tracker:overlay(base, true, 76, true)
assert(#markers == 2 and markers[1].icon_color == 0xFF0000FF and markers[1].pos == positions[guid],
  'show-after-collection must restore the saved first-token location without a duplicate')
assert(first_token.create(api, positions):overlay({}, true, 25, true)[1].pos == positions[guid],
  'show-after-collection must work when first installed after Finder pickup')
assert(tracker:overlay(base, false, 76, true) == base,
  'show-after-collection must respect the main first-token visibility toggle')
assert(tracker:overlay(base, true, 76, false) == base,
  'turning off show-after-collection must restore automatic pickup hiding')
finder_spawned = false
assert(first_token.create(api, positions):overlay(base, true, 76) == base,
  'clearing the display flag or handing the Finder in must not revive the marker')
collected, proof_key = false, other:upper() .. '_0'
markers = tracker:overlay(base, true, 76)
assert(markers[1].pos == positions[other], 'save/NG+ change retained the previous first token')
collected = nil
assert(tracker:overlay(base, true, 76) == base and tracker.error, 'unknown pickup state must not invent a marker')
assert(tracker:overlay({}, true, 76, true)[1].pos == positions[other] and not tracker.error,
  'explicitly showing the saved location must not depend on pickup-state availability')
empty = true
assert(tracker:overlay(base, true, 76, true) == base,
  'show-after-collection must not invent a first-token location before any pickup')
empty = false
collected, proof_key = false, 'bad-id'
assert(tracker:overlay(base, true, 76) == base and tracker.error)
proof_key = guid .. '_1'
assert(tracker:overlay(base, true, 76) == base and tracker.error, 'unknown spawn index used static coordinates')
proof_key = '00000000-0000-0000-0000-000000000001_0'
assert(tracker:overlay(base, true, 76) == base and tracker.error, 'unknown location was guessed')
manager = nil
assert(tracker:overlay(base, true, 76) == base)
manager = { get_FirstSeekerProof = function() error('loading') end }
assert(tracker:overlay(base, true, 76) == base and tracker.error)
assert(tracker:overlay(base, false, 76) == base and tracker.error == nil,
  'disabled feature must skip native reads and clear its error')
tracker:reset()
assert(tracker.error == nil)
