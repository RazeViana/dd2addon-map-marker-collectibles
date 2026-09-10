local minimap = require("raze_MapMarkersAndCollectables.minimap")
local time, reads, arrow_available = 0, 0, true
local function icon(visible, color)
  local value = {
    Sprite = { sequence = 7, pattern = 9,
      get_UVSequenceNo = function(self) return self.sequence end,
      set_UVSequenceNo = function(self, value) self.sequence = value end,
      get_UVPatternNo = function(self) return self.pattern end,
      set_UVPatternNo = function(self, value) self.pattern = value end },
    visible = visible, color = color, icon_type = 33, position = { x = 0, y = 0, z = 0 }, rotation = 0, scale = 1.2,
    get_Scale = function(self) return self.scale end,
    set_Scale = function(self, value) self.scale = value end,
    get_Visible = function(self) return self.visible end,
    set_Visible = function(self, value) self.visible = value end,
    get_Color = function(self) return self.color end,
    set_Color = function(self, value) self.color = value end,
    get_IconType = function(self) return self.icon_type end,
    set_IconType = function(self, value) self.icon_type = value end,
    get_Position = function(self) return self.position end,
    set_Position = function(self, value) self.position = value end,
    get_Rotation = function(self) return self.rotation end,
    set_Rotation = function(self, value) self.rotation = value end
  }
  value.Sprite.get_Size = function() return { w = 64 * value.scale, h = 64 * value.scale } end
  value.TexBG = { visible = false, set_Visible = function(self, state) self.visible = state end }
  return value
end
local icons = { icon(true, 10), icon(false, 20), icon(false, 30) }
local ui = { IsInit = true, PlChara = {}, PlUPos = { x = 0, y = 0, z = 0 }, MapOutRange = 100,
  MapIconList = { get_Count = function() return #icons end, get_Item = function(_, i) return icons[i + 1] end },
  getIconPos = function(_, pos) return { x = pos.x, y = pos.z, z = 0 } end,
  getSpriteIconRot = function() return 1 end
}
local enabled = { enabled = true, radius = 200, height = 60, max_markers = 24 }
local markers = {
  { key = "far", pos = {x=150,y=0,z=0}, icon_type = 25, icon_color = 100 },
  { key = "near", pos = {x=10,y=0,z=0}, icon_type = 25, icon_color = 100 },
  { key = "edge", pos = {x=20,y=0,z=0}, icon_type = 25, icon_color = 100 }
}
local renderer = minimap.create({ settings = enabled, clock = function() return time end,
  get_icon_scale = function() return 0.5 end,
  native_type = function(value) return value == 76 and 31 or value end,
  apply_icon = function(_, ref, value)
    ref.Sprite:set_UVSequenceNo(2); ref.Sprite:set_UVPatternNo(value == 76 and 0 or 2)
  end,
  apply_height = function(_, ref, direction)
    if not arrow_available then return false end
    ref.Sprite:set_UVSequenceNo(3); ref.Sprite:set_UVPatternNo(direction > 0 and 0 or 1)
    return true
  end,
  get_markers = function() reads = reads + 1; return markers end,
  vector = function(pos) return pos end, set_color = function(ref, color) ref:set_Color(color) end })
renderer:before(ui)
renderer:after(ui)
assert(icons[1].color == 10 and icons[1].visible, "native icon overwritten")
assert(icons[2].visible and icons[2].color == 100 and icons[2].position.x == 10)
assert(icons[3].visible and icons[3].position.x == 20)
assert(renderer.count == 2)
assert(icons[2].scale == 0.6 and icons[1].scale == 1.2, 'marker sizing affected a native icon')
-- Collectible symbols are upright screen glyphs, regardless of camera heading.
for _, heading in ipairs({0, math.pi / 2, math.pi, -math.pi / 2}) do
  ui.getSpriteIconRot = function() return heading end
  renderer:before(ui); renderer:after(ui)
  assert(icons[2].rotation == 0 and icons[3].rotation == 0,
    "collectible symbols rotate with the camera")
  assert(icons[2].scale == 0.6, 'icon size shrank on repeated updates')
end
renderer:before(ui)
assert(not icons[2].visible and icons[2].color == 20 and icons[2].icon_type == 33)
assert(icons[2].Sprite.sequence == 7 and icons[2].Sprite.pattern == 9, 'borrowed atlas coordinates were not restored')
assert(icons[2].scale == 1.2, 'native scale was not restored')
-- The game can reclaim a previously unused slot on its next update.
icons[2].visible = true; icons[2].color = 77
renderer:after(ui)
assert(icons[2].color == 77 and renderer.count == 1)
assert(reads == 1, "status was polled every frame")
renderer:before(ui)
time = 1
markers = {}
renderer:after(ui)
assert(renderer.count == 0 and not icons[3].visible and reads == 2)
-- Disable immediately, even with cached candidates; clear restores all borrowed state.
markers = {{key="a",pos={x=1,y=0,z=0},icon_type=25,icon_color=100}}
renderer:invalidate(); renderer:after(ui)
assert(icons[3].visible)
enabled.enabled = false
renderer:before(ui); renderer:after(ui)
assert(not icons[3].visible and renderer.count == 0)
enabled.enabled = true
renderer:invalidate(); renderer:after(ui)
renderer:clear()
assert(not icons[3].visible and icons[3].color == 30)
-- Missing player state during loading must not query collectible state.
ui.PlChara = nil
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 0)
-- A failed restore must not strand the other borrowed slots or lose retry state.
ui.PlChara = {}
icons = { icon(false, 20), icon(false, 30) }
icons[1].rotation = 0.75
icons[1].position = {x=3,y=4,z=0}
markers = {
  {key="a",pos={x=1,y=0,z=0},icon_type=25,icon_color=100},
  {key="b",pos={x=2,y=0,z=0},icon_type=25,icon_color=100}
}
renderer:invalidate(); renderer:after(ui)
local set_color = icons[1].set_Color
icons[1].set_Color = function(self, value)
  if value == 20 then error("restore failed") end
  set_color(self, value)
end
local ok = pcall(renderer.clear, renderer)
assert(not ok, "restoration failure should be reported")
assert(not icons[2].visible and icons[2].color == 30 and icons[2].icon_type == 33,
  "one failed slot prevents other slots from being restored")
assert(#renderer.owned == 1 and renderer.owned[1].ref == icons[1], "failed restoration snapshot lost")
icons[1].set_Color = set_color
renderer:clear()
assert(#renderer.owned == 0 and icons[1].color == 20 and icons[1].rotation == 0.75
  and icons[1].position.x == 3, "failed restoration could not be retried")
-- Exercise the enlarged pool at the maximum custom limit, alongside 56 native icons.
icons, markers = {}, {}
for i = 1, 256 do icons[i] = icon(i <= 56, i) end
for i = 1, 220 do
  markers[i] = {key=tostring(i),pos={x=i/10,y=0,z=0},icon_type=25,icon_color=1000}
end
enabled.max_markers = 200
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 200 and icons[256].visible and icons[256].color == 1000)
for i = 1, 56 do assert(icons[i].visible and icons[i].color == i, "native icon overwritten at high capacity") end
renderer:clear()
for i = 57, 256 do assert(not icons[i].visible and icons[i].color == i, "expanded slot not restored") end
markers = {{key='token',pos={x=1,y=0,z=0},icon_type=76,icon_color=100}}
renderer:invalidate(); renderer:after(ui)
assert(icons[57].icon_type == 31 and icons[57].Sprite.pattern == 0, 'custom symbol was not drawn through a native slot')
renderer:clear()
assert(icons[57].Sprite.sequence == 7 and icons[57].Sprite.pattern == 9)
-- Draw every collectible before borrowing any remaining slots for height arrows.
icons = {icon(true, 10), icon(false, 20), icon(false, 30), icon(false, 40), icon(false, 50), icon(false, 60)}
enabled.height_indicators, enabled.height_tolerance = true, 3
markers = {
  {key='up',pos={x=1,y=8,z=0},icon_type=76,icon_color=101},
  {key='down',pos={x=2,y=-8,z=0},icon_type=25,icon_color=102},
  {key='level',pos={x=3,y=3,z=0},icon_type=25,icon_color=103}
}
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 3 and renderer.height_count == 2, 'missing height indicators')
assert(icons[2].icon_type == 31 and icons[3].icon_type == 25 and icons[4].color == 103)
assert(icons[5].Sprite.sequence == 3 and icons[5].Sprite.pattern == 0 and icons[5].position.y < icons[2].position.y,
  'higher item must have an upward arrow above its icon')
assert(icons[6].Sprite.sequence == 3 and icons[6].Sprite.pattern == 1 and icons[6].position.y > icons[3].position.y,
  'lower item must have a downward arrow below its icon')
assert(icons[5].position.x == icons[2].position.x and icons[6].position.x == icons[3].position.x)
assert(icons[5].color == 101 and icons[6].color == 102 and icons[5].rotation == 0 and icons[6].rotation == 0)
assert(icons[5].scale < icons[2].scale and not icons[5].TexBG.visible, 'arrow obscures its collectible')
local arrow_scale = icons[5].scale
for _, heading in ipairs({0, math.pi / 2, math.pi, -math.pi / 2}) do
  ui.getSpriteIconRot = function() return heading end
  renderer:before(ui); renderer:after(ui)
  assert(icons[5].rotation == 0 and icons[6].rotation == 0, 'height arrows rotate with the camera')
end
-- Height follows the player's current position even while the collectible cache is reused.
renderer:before(ui)
ui.PlUPos.y = 8
renderer:after(ui)
assert(renderer.height_count == 2 and icons[5].Sprite.pattern == 1 and icons[5].position.x == 2)
assert(icons[5].scale == arrow_scale, 'arrow size accumulated across updates')
renderer:before(ui)
ui.PlUPos.y = 0
enabled.height_tolerance = 8
renderer:after(ui)
assert(renderer.count == 3 and renderer.height_count == 0 and not icons[5].visible and not icons[6].visible,
  'tolerance boundary did not count as level')
renderer:before(ui)
enabled.height_tolerance = 0
renderer:after(ui)
assert(renderer.count == 3 and renderer.height_count == 2, 'arrows displaced a collectible at capacity')
renderer:before(ui)
enabled.height_indicators = false
renderer:after(ui)
assert(renderer.count == 3 and renderer.height_count == 0 and not icons[5].visible and not icons[6].visible,
  'disabling arrows hid collectibles or left stale arrows')
renderer:clear()
for i = 2, 6 do
  assert(not icons[i].visible and icons[i].color == i*10 and icons[i].Sprite.sequence == 7
    and icons[i].Sprite.pattern == 9 and icons[i].scale == 1.2 and icons[i].position.x == 0,
    'arrow or marker did not restore its borrowed slot')
end
assert(icons[1].visible and icons[1].color == 10, 'arrows changed a native marker')
-- A full pool still displays the same number of collectibles, just without arrows.
icons = {icon(true, 10), icon(false, 20), icon(false, 30), icon(false, 40)}
enabled.height_indicators = true
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 3 and renderer.height_count == 0)
renderer:clear()
-- The enlarged arrow-capable pool can hold 200 icons plus their 200 indicators.
icons, markers = {}, {}
for i = 1, 512 do icons[i] = icon(i <= 56, i) end
for i = 1, 200 do
  markers[i] = {key=tostring(i),pos={x=i/10,y=i%2 == 0 and 10 or -10,z=0},icon_type=25,icon_color=1000}
end
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 200 and renderer.height_count == 200 and icons[456].visible)
for i = 1, 56 do assert(icons[i].visible and icons[i].color == i, 'arrow overwrote a native slot') end
enabled.enabled = false
renderer:before(ui); renderer:after(ui)
assert(renderer.count == 0 and renderer.height_count == 0)
for i = 57, 512 do assert(not icons[i].visible and icons[i].color == i, 'disabled minimap stranded an arrow') end
-- Missing custom artwork must not expose the arrow slot's native fallback symbol.
enabled.enabled, arrow_available = true, false
icons = {icon(true, 10), icon(false, 20), icon(false, 30)}
markers = {{key='up',pos={x=1,y=10,z=0},icon_type=25,icon_color=100}}
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 1 and renderer.height_count == 0 and icons[2].visible and not icons[3].visible)
renderer:clear()
assert(icons[3].icon_type == 33 and icons[3].scale == 1.2)
-- Suppress arrows whose offset would put them outside the minimap.
arrow_available = true
markers = {{key='edge',pos={x=0,y=10,z=-95},icon_type=25,icon_color=100}}
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 1 and renderer.height_count == 0 and not icons[3].visible)
renderer:clear()
markers[1].pos.z = 0
renderer:invalidate(); renderer:after(ui)
assert(renderer.height_count == 1)
renderer:clear()
-- A clipped arrow must leave the final free slot available to a later visible arrow.
icons = {icon(false, 10), icon(false, 20), icon(false, 30)}
markers = {
  {key='outer',pos={x=0,y=8,z=-90},icon_type=25,icon_color=101},
  {key='inner',pos={x=0,y=8,z=91},icon_type=25,icon_color=102}
}
renderer:invalidate(); renderer:after(ui)
assert(renderer.count == 2 and renderer.height_count == 1 and icons[3].visible,
  'clipped arrow consumed the only free slot')
assert(icons[3].color == 102 and icons[3].position.y > 0 and icons[3].position.y < 91)
assert(#renderer.owned == 3, 'reusing a clipped arrow slot duplicated its restoration snapshot')
renderer:destroy(ui)
assert(renderer.height_count == 0 and #renderer.owned == 0, 'destroyed HUD retained arrow references')
-- Fog filtering runs before the limit and again while nearby candidates are cached.
icons = {icon(true, 10), icon(false, 20), icon(false, 30)}
markers = {
  {key='chest',pos={x=1,y=0,z=0},icon_type=25,icon_color=101},
  {key='token',pos={x=5,y=0,z=0},icon_type=25,icon_color=102}
}
ui.PlUPos = {x=0,y=0,z=0}
local show_chest, candidate_reads = false, 0
local filtered_renderer = minimap.create({
  settings = { enabled=true, radius=100, height=60, max_markers=1 },
  clock = function() return 0 end,
  get_markers = function() candidate_reads = candidate_reads + 1; return markers end,
  filter_markers = function(current_ui, candidates)
    assert(current_ui == ui)
    return show_chest and candidates or {candidates[2]}
  end,
  vector = function(pos) return pos end,
  set_color = function(ref, color) ref:set_Color(color) end
})
filtered_renderer:before(ui); filtered_renderer:after(ui)
assert(filtered_renderer.count == 1 and icons[2].color == 102,
  'a hidden nearby chest consumed the only permitted marker')
show_chest = true
filtered_renderer:before(ui); filtered_renderer:after(ui)
assert(candidate_reads == 1 and icons[2].color == 101,
  'newly revealed chest waited for cached collectible positions to expire')
show_chest = false
filtered_renderer:before(ui); filtered_renderer:after(ui)
assert(icons[2].color == 102 and icons[1].color == 10 and icons[1].visible,
  'changing fog left a stale chest or changed a native icon')
filtered_renderer:clear()
assert(not icons[2].visible and icons[2].color == 20, 'fog-filtered sprite was not restored')
