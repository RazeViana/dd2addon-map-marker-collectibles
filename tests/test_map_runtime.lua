-- Execute the complete map script against a small REFramework boundary fixture.
-- This checks Lua control flow and emitted icons; it does not simulate the native UI.
local hooks, callbacks, objects, next_address = {}, {}, {}, 1000
local messages, writes, ids, toggled = {}, {}, {}, false
local settings_reads = {}
local managers = {}
local function list(items)
  return { get_Count = function() return #items end, get_Item = function(_, i) return items[i + 1] end }
end
local function box()
  next_address = next_address + 100
  local value = { address = next_address, value = 0 }
  objects[next_address] = value
  function value:add_ref() return self end
  function value:get_address() return self.address end
  function value:write_dword(_, data) self.value = data end
  function value:read_dword() return self.value end
  value.write_qword, value.read_qword = value.write_dword, value.read_dword
  function value:setup(guid) self.key = guid:call("ToString") end
  function value:ToString() return self.key .. "_0" end
  return value
end
local map = {
  MapIconSpriteSet = { atlas = { get_ResourcePath = function() return 'Gui/ui01/Common/map/UVS_map_01.uvs' end,
      add_ref = function(self) return self end },
    get_UVSequence = function(self) return self.atlas end,
    set_UVSequence = function(self, value) self.atlas = value end },
  MapIcon = { get_Length = function() return 1 end },
  MapIconSprite = { get_Length = function() return 3 end },
  MapIconInfoList = list({ { IconSprite = {} } }),
  emitted = {}, refreshes = 0, NowScale = 1,
  isInDispRange = function(_, pos) return pos.x > 0 end,
  get_Valid = function() return true end,
  updateMapIcon = function(self) self.refreshes = self.refreshes + 1 end
}
function map:setMapScale()
  local previous = self.emitted
  hooks["app.ui040205.setupMapIcon"].pre({ [2] = self })
  for _, info in ipairs(previous) do
    local ref = info.ui_icon.IconSprite
    assert(ref.scale == 1, 'borrowed scale was not restored before native setup')
    assert(ref.Sprite.sequence == 1, 'borrowed UV sequence was not restored before native setup')
    -- Native setup may reuse old custom slots for unrelated game icons.
    ref.scale, ref.Sprite.sequence, ref.Sprite.pattern = 2, 0, 3
  end
  self.emitted = {}
  self.MapIconInfoList = list({ { IconSprite = {} } })
  hooks["app.ui040205.setupMapIcon"].post(91)
  for _, info in ipairs(previous) do
    local ref = info.ui_icon.IconSprite
    assert(ref.scale == 2 and ref.Sprite.sequence == 0 and ref.Sprite.pattern == 3,
      'custom cleanup overwrote a reused native slot')
  end
end
local function method(type_name, name)
  if name == "getGimmickList(app.GimmickID)" then return function() return list({}) end end
  if name == "addMapIconInfoList" or name == "addMapIconSpriteInfoList" then
    return function(self, info, _, pointer, _, name_guid)
      assert(info.Pos.x > 0 and info.IsEnable and info.UniqId ~= nil)
      local cursor = objects[pointer]
      assert(cursor.value < 3, "wrote past icon pool")
      cursor.value = cursor.value + 1
      self.emitted[#self.emitted + 1] = info
      local ui_icon = box()
      ui_icon.Name, ui_icon.NameId = "Pawn dialogue", name_guid
      ui_icon.IconSprite = { scale = 1,
        get_Scale = function(self) return self.scale end,
        set_Scale = function(self, value) self.scale = value end,
        set_Color = function(_, color_pointer)
        info.color = objects[color_pointer].value
      end }
      ui_icon.IconSprite.Sprite = { sequence = 1, pattern = info.IconType,
        get_UVSequenceNo = function(self) return self.sequence end,
        set_UVSequenceNo = function(self, value) self.sequence = value end,
        get_UVPatternNo = function(self) return self.pattern end,
        set_UVPatternNo = function(self, value) self.pattern = value end }
      info.ui_icon = ui_icon
      return ui_icon
    end
  end
  return type_name .. "." .. name
end
sdk = {
  create_resource = function(_, path) return { create_holder = function()
    return { get_ResourcePath = function() return path end, add_ref = function(self) return self end }
  end } end,
  find_type_definition = function(name)
    return { get_field = function() return { get_offset_from_base = function() return 0 end } end,
      get_runtime_type = function() return name end,
      get_method = function(_, member) return method(name, member) end,
      create_instance = box }
  end,
  hook = function(member, pre, post) hooks[member] = { pre = pre, post = post } end,
  get_managed_singleton = function(name) return managers[name] end,
  to_managed_object = function(value) return value end
}
ValueType = { new = function()
  local value = { bytes = {} }
  function value:write_byte(index, byte) self.bytes[index + 1] = byte end
  function value:call()
    -- Derive the GUID back from the actual bytes written by production code.
    local b = self.bytes
    return ("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x"):format(
      b[4], b[3], b[2], b[1], b[6], b[5], b[8], b[7], b[9], b[10], b[11], b[12], b[13], b[14], b[15], b[16])
  end
  return value
end }
Vector3f = { new = function(x, y, z) return { x = x, y = y, z = z } end }
log = { info = function(message) messages[#messages + 1] = message end }
log.warn, log.error, log.debug = log.info, log.info, log.info
re = { on_config_save = function(callback) callbacks.save = callback end,
  on_draw_ui = function(callback) callbacks.ui = callback end }
json = {
  load_file = function(path)
    if path:match("_settings.json$") then
      settings_reads[#settings_reads + 1] = path
      return { markers = { ["Golden Trove Beetles"] = { unacquired_show = false } } }
    end
    if path == "raze_MapMarkersAndCollectables/167.json" then
      return { locations = {
        ["00000001-0000-0000-0000-000000000000"] = { x = 1, y = 0, z = 1 },
        ["00000002-0000-0000-0000-000000000000"] = { x = 2, y = 0, z = 1 },
        ["00000003-0000-0000-0000-000000000000"] = { x = -1, y = 0, z = 1 }
      } }
    end
    assert(path:match("^raze_MapMarkersAndCollectables/%d+.json$"))
    return { locations = { ["00000004-0000-0000-0000-000000000000"] = { x = 1, y = 0, z = 1 } } }
  end,
  dump_file = function(path, value) writes[path] = value; return true end
}
imgui = {
  tree_node = function(label) return label == "Map Markers and Collectables by Raze" end,
  tree_pop = function() end, text = function() end, text_colored = function() end,
  push_id = function(id) ids[#ids + 1] = id end,
  pop_id = function() table.remove(ids) end,
  push_style_color = function() end, pop_style_color = function() end,
  arrow_button = function() return false end, same_line = function() end,
  slider_int = function(_, value) return false, value end,
  is_item_hovered = function() return false end, button = function() return false end,
  checkbox = function(_, value)
    if not toggled and ids[1] == "Seeker's Tokens" and ids[2] == "Show Unacquired" then
      toggled = true; return true, false
    end
    return false, value
  end
}
dofile(TEST_ROOT .. "/reframework/autorun/raze_MapMarkersAndCollectables.lua")
assert(#messages == 0, "GUID construction or script initialization failed")
assert(#settings_reads == 1 and settings_reads[1] == "raze_MapMarkersAndCollectables_settings.json",
  "initialization accessed another mod's settings")
callbacks.save()
assert(writes["raze_MapMarkersAndCollectables_settings.json"] ~= nil)
for filename in pairs(writes) do assert(filename == "raze_MapMarkersAndCollectables_settings.json") end
hooks["app.ui040205..ctor"].pre({ [2] = map })
hooks["app.ui040205..ctor"].post(91)
-- Main menu / loading transitions must not dereference absent managers.
map:setMapScale()
assert(#map.emitted == 0)
local lock_count = 0
local database = { Lock = {
  readLock = function() lock_count = lock_count + 1 end,
  readUnlock = function() lock_count = lock_count - 1 end },
  IndexCreator = { UniqueID2Keys = { TryGetValue = function() return false end } }
}
managers["app.GenerateManager"] = { isNeverGenerate = function() return false end }
managers["app.GimmickManager"] = {}
managers["app.ContextDBMS"] = { get_CurrentDB = function() return database end }
map:setMapScale()
assert(lock_count == 0)
assert(#map.emitted == 2)
assert(map.emitted[1].color == 0xFF00CC00)
assert(map.emitted[1].ui_icon.Name == "Seeker's Token", "custom hover label was not assigned")
assert(map.emitted[1].IconType == 31 and map.emitted[1].ui_icon.IconSprite.Sprite.pattern == 0,
  'token did not use the token artwork')
assert(map.emitted[1].ui_icon.IconSprite.scale == 0.5, 'full-map icon was not halved')
local size_hook = hooks['app.ui040205.updateMapIcon']
size_hook.pre({[2]=map}); size_hook.post(91)
size_hook.pre({[2]=map}); size_hook.post(91)
assert(map.emitted[1].ui_icon.IconSprite.scale == 0.5, 'full-map size accumulated')
local hover_hook = hooks["app.ui040205.setupIconName"]
assert(hover_hook, "map hover display is not hooked")
map.TxtName = { message = "Native text", set_Message = function(self, message) self.message = message end }
map.SelectedIcon = map.emitted[1].ui_icon
hover_hook.pre({ [2] = map })
assert(hover_hook.post(91) == 91)
assert(map.TxtName.message == "Seeker's Token", "hover display did not use the custom label")
map.SelectedIcon = box()
map.TxtName.message = "Borderwatch Outpost"
hover_hook.pre({ [2] = map })
hover_hook.post(91)
assert(map.TxtName.message == "Borderwatch Outpost", "native hover label was overwritten")
-- Changing visibility must invalidate the marker cache and refresh on the UI hook.
callbacks.ui()
hooks["app.ui040205.update"].pre({ [2] = map })
assert(#map.emitted == 0, "settings change left stale markers")
-- A failing status lookup must release the DB lock and leave the cache retryable.
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
local saved_settings = writes["raze_MapMarkersAndCollectables_settings.json"]
saved_settings.markers["Seeker's Tokens"].unacquired_show = true
managers["app.GenerateManager"].isNeverGenerate = function() error("status unavailable") end
map:setMapScale()
assert(lock_count == 0 and #map.emitted == 0)
managers["app.GenerateManager"].isNeverGenerate = function() return false end
map:setMapScale()
assert(lock_count == 0 and #map.emitted == 2)

-- Every category emits a plain singular label without a pawn-dialogue message ID.
for category, label in pairs({
  ["Seeker's Tokens"] = "Seeker's Token", ["Golden Trove Beetles"] = "Golden Trove Beetle",
  ["Chests (S)"] = "Chest (S)", ["Chests (M)"] = "Chest (M)", ["Chests (L)"] = "Chest (L)",
  ["Chests (XL)"] = "Chest (XL)", ["Special Chests (S)"] = "Special Chest (S)",
  ["Special Chests (M)"] = "Special Chest (M)", ["Special Chests (L)"] = "Special Chest (L)"
}) do
  for name, marker in pairs(saved_settings.markers) do marker.unacquired_show = name == category end
  hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
  map:setMapScale()
  assert(#map.emitted > 0, "missing category: " .. category)
  for _, emitted in ipairs(map.emitted) do
    local expected = category == "Seeker's Tokens" and 0 or category == 'Golden Trove Beetles' and 1
      or category:find('Special', 1, true) and 3 or 2
    assert(emitted.IconType == 31 and emitted.ui_icon.IconSprite.Sprite.sequence == 2
      and emitted.ui_icon.IconSprite.Sprite.pattern == expected, 'wrong object artwork for ' .. category)
    assert(emitted.ui_icon.Name == label, "wrong hover label for " .. category)
    map.SelectedIcon = emitted.ui_icon
    map.TxtName.message = "Native text"
    hover_hook.pre({ [2] = map }); hover_hook.post(91)
    assert(map.TxtName.message == label, "native hover text was not replaced for " .. category)
  end
end
-- Switching to game symbols retains the saved choice and forces a map refresh.
local old_checkbox = imgui.checkbox
imgui.checkbox = function(label, value)
  if label == 'Use object icons' then return true, false end
  return false, value
end
callbacks.ui()
hooks['app.ui040205.update'].pre({[2]=map})
assert(#map.emitted > 0 and map.emitted[1].IconType == 25)
assert(map.emitted[1].ui_icon.IconSprite.Sprite.sequence == 1)
imgui.checkbox = old_checkbox
imgui.slider_int = function(_, value) return true, 125 end
callbacks.ui(); hooks['app.ui040205.update'].pre({[2]=map})
assert(map.emitted[1].ui_icon.IconSprite.scale == 1.25, 'size slider did not refresh game symbols')
imgui.slider_int = function(_, value) return false, value end
local stale = map.SelectedIcon
hooks["app.ui040205.onDestroy"].pre({ [2] = map })
map.SelectedIcon = stale
map.TxtName.message = "New map label"
hover_hook.pre({ [2] = map }); hover_hook.post(91)
assert(map.TxtName.message == "New map label", "destroyed map retained stale custom labels")
