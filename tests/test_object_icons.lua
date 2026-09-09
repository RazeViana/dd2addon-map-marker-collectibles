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
local up, down = ref(), ref()
assert(renderer:apply_height(mini, up, 1) and renderer:apply_height(mini, down, -1))
assert(up.Sprite.sequence == 3 and up.Sprite.pattern == 0, 'wrong upward indicator glyph')
assert(down.Sprite.sequence == 3 and down.Sprite.pattern == 1, 'wrong downward indicator glyph')
assert(#loads == 2, 'height indicators reloaded the shared minimap atlas')
local native_mini = map('Gui/ui01/Common/map/UVS_map_03.uvs')
assert(renderer:apply_height(native_mini, up, 1), 'height indicators require object icons to be enabled')
assert(native_mini.MapIconSpriteSet:get_UVSequence():get_ResourcePath() == 'raze/mapmarkers/minimap.uvs')
-- Restore the previous HUD before continuing its restoration checks.
renderer:destroy(native_mini, 'minimap')
renderer:apply(mini, 'minimap', c, 77)
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
local incompatible_mini = map('another_mod/custom.uvs')
assert(not renderer:apply_height(incompatible_mini, down, -1))
assert(incompatible_mini.MapIconSpriteSet:get_UVSequence():get_ResourcePath() == 'another_mod/custom.uvs')
api.create_resource = function() return nil end
local broken = icons.create(api, function() end)
assert(not broken:apply(full, 'fullmap', a, 78) and a.Sprite.sequence == 1)
local untouched = ref()
assert(not broken:apply_height(mini, untouched, 1))
assert(untouched.Sprite.sequence == 1 and untouched.Sprite.pattern == 31,
  'missing arrow assets replaced a native glyph')
-- Destroyed UI must not be dereferenced during a later script reset.
renderer:destroy(other, 'fullmap')
other.MapIconSpriteSet.get_UVSequence = function() error('destroyed UI') end
renderer:restore()
