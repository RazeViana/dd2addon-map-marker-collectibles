local icons = require('raze_MapMarkersAndCollectables.object_icons')
assert(icons.native_type(76) == 31 and icons.native_type(79) == 31)
assert(icons.native_type(25) == 25)
local loads, warnings = {}, {}
local function holder(path)
  return { get_ResourcePath = function() return path end, add_ref = function(self) return self end }
end
local api = { create_resource = function(_, path)
  loads[#loads + 1] = path
  return { create_holder = function() return holder(path) end }
end }
local function map(path)
  local atlas = holder(path)
  return { MapIconSpriteSet = {
    get_UVSequence = function() return atlas end,
    set_UVSequence = function(_, value) atlas = value end
  } }
end
local function ref()
  return { Sprite = {
    sequence = 1, pattern = 31,
    get_UVSequenceNo = function(self) return self.sequence end,
    set_UVSequenceNo = function(self, value) self.sequence = value end,
    get_UVPatternNo = function(self) return self.pattern end,
    set_UVPatternNo = function(self, value) self.pattern = value end
  } }
end
local full = map('Gui/ui01/Common/map/UVS_map_01.uvs')
local mini = map('Gui/ui01/Common/map/UVS_map_03.uvs')
local renderer = icons.create(api, function(message) warnings[#warnings + 1] = message end)
local a,b,c = ref(),ref(),ref()
assert(renderer:apply(full, 'fullmap', a, 76))
assert(a.Sprite.sequence == 2 and a.Sprite.pattern == 0)
assert(renderer:apply(full, 'fullmap', b, 79))
assert(b.Sprite.pattern == 3 and #loads == 1, 'atlas loaded for every marker')
assert(not renderer:apply(full, 'fullmap', c, 25))
assert(c.Sprite.sequence == 1 and c.Sprite.pattern == 31, 'game symbol changed')
assert(renderer:apply(mini, 'minimap', c, 77))
assert(c.Sprite.sequence == 2 and c.Sprite.pattern == 1 and #loads == 2)
renderer:clear(full, 'fullmap')
assert(a.Sprite.sequence == 1 and a.Sprite.pattern == 31 and b.Sprite.sequence == 1)
assert(c.Sprite.sequence == 2, 'full-map refresh changed the minimap')
renderer:restore()
assert(full.MapIconSpriteSet:get_UVSequence():get_ResourcePath():find('UVS_map_01'))
assert(mini.MapIconSpriteSet:get_UVSequence():get_ResourcePath():find('UVS_map_03'))
-- Unknown map atlases and missing resources must leave native sprites intact.
local other = map('another_mod/custom.uvs')
assert(not renderer:apply(other, 'fullmap', a, 78))
assert(a.Sprite.sequence == 1 and #warnings == 1)
api.create_resource = function() return nil end
local broken = icons.create(api, function() end)
assert(not broken:apply(full, 'fullmap', a, 78) and a.Sprite.sequence == 1)
-- Destroyed UI must not be dereferenced during a later script reset.
renderer:destroy(other, 'fullmap')
other.MapIconSpriteSet.get_UVSequence = function() error('destroyed UI') end
renderer:restore()
