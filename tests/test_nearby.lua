local nearby = require("raze_MapMarkersAndCollectables.nearby")
local origin = { x = 0, y = 10, z = 0 }
local function marker(key, x, y, z) return { key = key, pos = { x = x, y = y, z = z } } end
local entries = { marker("far", 30, 10, 0), marker("b", 3, 10, 4), marker("a", -3, 10, 4),
  marker("above", 0, 80, 0), marker("near", 1, 10, 0), marker("boundary", 10, 10, 0) }
local selected = nearby.select(entries, origin, 10, 20, 3)
assert(#selected == 3)
assert(selected[1].key == "near" and selected[2].key == "a" and selected[3].key == "b")
assert(#nearby.select(entries, origin, 10, 20, 0) == 0)
assert(#nearby.select(entries, origin, 10, 20, 10) == 4)
assert(entries[1].key == "far", "must not reorder source data")
assert(nearby.in_range({x=6,y=10,z=8}, origin, 10, 20))
assert(not nearby.in_range({x=6,y=31,z=8}, origin, 10, 20))
assert(not nearby.in_range({x=6,y=10,z=9}, origin, 10, 20))
assert(not nearby.in_range({x=0/0,y=10,z=0}, origin, 10, 20))
