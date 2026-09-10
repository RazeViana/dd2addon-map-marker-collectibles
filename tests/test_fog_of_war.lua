local module = require("raze_MapMarkersAndCollectables.fog_of_war")
local revealed = {[1] = true, [2] = false}
local mask = { MaskBit = { get_Length = function() return 1 end } }
local calls, available, fail, selected_area = 0, true, false, nil
local manager = { getMaskInfo = function(_, area)
  selected_area = area
  if area == 5 then return mask end
  return { MaskBit = mask.MaskBit, hidden = true }
end }
local api = {
  get_managed_singleton = function(name)
    calls = calls + 1
    assert(name == "app.GuiManager")
    return available and manager or nil
  end,
  find_type_definition = function(name)
    assert(name == "app.GuiManager.MapMaskInfo")
    return { get_method = function(_, name)
      assert(name == "isMaskOff(via.vec3)", "ambiguous or mutating fog method")
      return function(value, pos)
        if fail then error("fog unavailable") end
        assert(pos.y == 3 and pos.z == -4, "world coordinates were changed")
        return not value.hidden and revealed[pos.x]
      end
    end }
  end
}
local filter = module.create(api, function(pos) return {x=pos.x,y=pos.y,z=pos.z} end)
local chest_type, token_type = { is_chest = true }, {}
local markers = {
  {key="visible", marker_type=chest_type, pos={x=1,y=3,z=-4}},
  {key="hidden", marker_type=chest_type, pos={x=2,y=3,z=-4}},
  {key="token", marker_type=token_type, pos={x=2,y=3,z=-4}}
}
local ui = { LocalAreaNow = 5 }
assert(filter:filter(markers, ui, "fullmap", false) == markers and calls == 0,
  "disabled fog filter still accessed game state")
local result = filter:filter(markers, ui, "fullmap", true)
assert(#result == 2 and result[1].key == "visible" and result[2].key == "token")
assert(#markers == 3 and markers[2].key == "hidden", "fog filter damaged cached candidates")
assert(selected_area == 5)
revealed[2] = true
assert(#filter:filter(markers, ui, "minimap", true) == 3, "new exploration reused stale fog results")
ui.LocalAreaNow = 8
result = filter:filter(markers, ui, "minimap", true)
assert(#result == 1 and result[1].key == "token", "area transition reused the previous fog mask")
ui.LocalAreaNow = 5
available = false
result = filter:filter(markers, ui, "fullmap", true)
assert(#result == 1 and result[1].key == "token", "missing fog data revealed chests or hid other categories")
assert(filter.errors.fullmap, "unavailable fog data was silent")
available = true
fail = true
assert(#filter:filter(markers, ui, "fullmap", true) == 1, "fog lookup error escaped the chest filter")
fail = false
assert(#filter:filter(markers, ui, "fullmap", true) == 3 and not filter.errors.fullmap,
  "fog lookup did not recover when the game became ready")
mask.MaskBit = nil
assert(#filter:filter(markers, ui, "fullmap", true) == 1, "uninitialized mask reached the native query")
