local minimap = require("raze_MapMarkersAndCollectables.minimap")
local time, reads = 0, 0
local function icon(visible, color)
  return {
    visible = visible, color = color, icon_type = 33, position = { x = 0, y = 0, z = 0 }, rotation = 0,
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
  get_markers = function() reads = reads + 1; return markers end,
  vector = function(pos) return pos end, set_color = function(ref, color) ref:set_Color(color) end })
renderer:before(ui)
renderer:after(ui)
assert(icons[1].color == 10 and icons[1].visible, "native icon overwritten")
assert(icons[2].visible and icons[2].color == 100 and icons[2].position.x == 10)
assert(icons[3].visible and icons[3].position.x == 20)
assert(renderer.count == 2)
-- Collectible symbols are upright screen glyphs, regardless of camera heading.
for _, heading in ipairs({0, math.pi / 2, math.pi, -math.pi / 2}) do
  ui.getSpriteIconRot = function() return heading end
  renderer:before(ui); renderer:after(ui)
  assert(icons[2].rotation == 0 and icons[3].rotation == 0,
    "collectible symbols rotate with the camera")
end
renderer:before(ui)
assert(not icons[2].visible and icons[2].color == 20 and icons[2].icon_type == 33)
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
