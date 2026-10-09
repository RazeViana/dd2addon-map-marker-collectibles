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
local chest_settings = { hide_unexplored_chests = true }
local chest_type = { fog_setting = "hide_unexplored_chests" }
local token_type = { fog_setting = "hide_unexplored_tokens" }
local markers = {
  {key="visible", marker_type=chest_type, pos={x=1,y=3,z=-4}},
  {key="hidden", marker_type=chest_type, pos={x=2,y=3,z=-4}},
  {key="token", marker_type=token_type, pos={x=2,y=3,z=-4}}
}
local ui = { LocalAreaNow = 5, IsFieldMap = true, IsDispField = true }
assert(filter:filter(markers, ui, "fullmap", {}) == markers and calls == 0,
  "disabled fog filter still accessed game state")
local result = filter:filter(markers, ui, "fullmap", chest_settings)
assert(#result == 2 and result[1].key == "visible" and result[2].key == "token")
assert(#markers == 3 and markers[2].key == "hidden", "fog filter damaged cached candidates")
assert(selected_area == 5)
revealed[2] = true
assert(#filter:filter(markers, ui, "minimap", chest_settings) == 3, "new exploration reused stale fog results")
ui.LocalAreaNow = 8
result = filter:filter(markers, ui, "minimap", chest_settings)
assert(#result == 1 and result[1].key == "token", "area transition reused the previous fog mask")
ui.LocalAreaNow = 5
available = false
result = filter:filter(markers, ui, "fullmap", chest_settings)
assert(#result == 1 and result[1].key == "token", "missing fog data revealed chests or hid other categories")
assert(filter.errors.fullmap, "unavailable fog data was silent")
available = true
fail = true
assert(#filter:filter(markers, ui, "fullmap", chest_settings) == 1, "fog lookup error escaped the chest filter")
fail = false
assert(#filter:filter(markers, ui, "fullmap", chest_settings) == 3 and not filter.errors.fullmap,
  "fog lookup did not recover when the game became ready")
mask.MaskBit = nil
assert(#filter:filter(markers, ui, "fullmap", chest_settings) == 1, "uninitialized mask reached the native query")
-- Each fog option controls only its own group, including all combinations.
mask.MaskBit = {get_Length=function() return 1 end}
revealed[2] = false
local groups = {
  {key="chest",marker_type=chest_type,pos={x=2,y=3,z=-4}},
  {key="token",marker_type=token_type,pos={x=2,y=3,z=-4}},
  {key="beetle",marker_type={fog_setting="hide_unexplored_beetles"},pos={x=2,y=3,z=-4}}
}
for _, case in ipairs({
  {{}, "chest,token,beetle"},
  {{hide_unexplored_chests=true}, "token,beetle"},
  {{hide_unexplored_tokens=true}, "chest,beetle"},
  {{hide_unexplored_beetles=true}, "chest,token"},
  {{hide_unexplored_chests=true,hide_unexplored_tokens=true}, "beetle"},
  {{hide_unexplored_chests=true,hide_unexplored_beetles=true}, "token"},
  {{hide_unexplored_tokens=true,hide_unexplored_beetles=true}, "chest"},
  {{hide_unexplored_chests=true,hide_unexplored_tokens=true,hide_unexplored_beetles=true}, ""}
}) do
  for _, ready in ipairs({true,false}) do
    available = ready
    local result = filter:filter(groups, ui, "minimap", case[1])
    local keys = {}
    for _, marker in ipairs(result) do keys[#keys+1] = marker.key end
    assert(table.concat(keys,",") == case[2], "fog preferences were coupled or hid the wrong group")
  end
end

local dlc_chest={key='dlc-chest',marker_type={fog_setting='hide_unexplored_dlc_chests'},
  pos={x=2,y=3,z=-4}}
local both={groups[1],dlc_chest}
available=true;ui.LocalAreaNow=5;revealed[2]=false
for _,case in ipairs({
  {{hide_unexplored_chests=true,hide_unexplored_dlc_chests=false},'dlc-chest'},
  {{hide_unexplored_chests=false,hide_unexplored_dlc_chests=true},'chest'},
  {{hide_unexplored_chests=true,hide_unexplored_dlc_chests=true},''},
  {{hide_unexplored_chests=false,hide_unexplored_dlc_chests=false},'chest,dlc-chest'},
}) do
  local shown=filter:filter(both,ui,'fullmap',case[1])
  local keys={};for _,m in ipairs(shown) do keys[#keys+1]=m.key end
  assert(table.concat(keys,',')==case[2], 'base/DLC chest fog controls hid the wrong group')
end
for _,kind in ipairs({'fullmap','minimap'}) do
  local local_ui=kind=='fullmap' and {IsFieldMap=false} or {IsDispField=false}
  available=false;local before_calls=calls
  local input={dlc_chest}
  assert(filter:filter(input,local_ui,kind,{hide_unexplored_dlc_chests=true})==input and calls==before_calls,
    'DLC chest fog incorrectly hid trial-local chests or queried an unavailable mask')
end
local before = calls
assert(filter:filter(groups, ui, "minimap", {}) == groups and calls == before and not filter.errors.minimap,
  "disabling all fog controls kept a stale error or queried the game")

-- Chests bypass fog on cave/city local maps, then follow the saved preference
-- again outdoors. The displayed map mode, not a guessed local-area ID, controls this.
for _, kind in ipairs({"fullmap", "minimap"}) do
  local mode = kind == "fullmap" and "IsFieldMap" or "IsDispField"
  local local_ui = { LocalAreaNow = 8, [mode] = false }
  local only_chests = { groups[1] }
  available = false
  filter.errors[kind] = "Previous outdoor fog error"
  before = calls
  assert(filter:filter(only_chests, local_ui, kind, chest_settings) == only_chests,
    "local-map chest still required fog data: " .. kind)
  assert(calls == before and not filter.errors[kind], "chest bypass queried fog or kept a stale error")
  assert(chest_settings.hide_unexplored_chests == true, "local-map bypass changed the saved toggle")

  for _, area in ipairs({5, 8}) do
    local_ui.LocalAreaNow = area
    for _, ready in ipairs({true, false}) do
      available = ready
      local all_enabled = {hide_unexplored_chests=true,hide_unexplored_tokens=true,hide_unexplored_beetles=true}
      local local_result = filter:filter(groups, local_ui, kind, all_enabled)
      assert(#local_result == 1 and local_result[1].key == "chest",
        "local-map chest bypass changed token or beetle fog filtering")
      assert((filter.errors[kind] ~= nil) == (not ready), "other fog errors were lost or invented")
    end
  end

  -- Same cached candidates, including entering a cave and returning outside.
  available = true
  local_ui.LocalAreaNow = 5
  for _, field in ipairs({true, false, true, false, true}) do
    local_ui[mode] = field
    local transitioned = filter:filter(groups, local_ui, kind, chest_settings)
    assert(#transitioned == (field and 2 or 3), "map transition retained stale chest visibility")
    assert(#groups == 3 and groups[1].key == "chest", "transition modified cached marker candidates")
  end
  -- Missing mode information never silently disables the outdoor fog preference.
  local_ui[mode] = nil
  assert(#filter:filter(groups, local_ui, kind, chest_settings) == 2,
    "unknown map mode bypassed chest fog")
  local_ui[mode] = false
  before = calls
  assert(filter:filter(groups, local_ui, kind, {}) == groups and calls == before,
    "disabled fog controls changed local-map behavior")
end
