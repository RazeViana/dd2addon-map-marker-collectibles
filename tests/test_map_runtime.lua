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
  MapIcon = { get_Length = function() return 1 end },
  MapIconSprite = { get_Length = function() return 3 end },
  MapIconInfoList = list({ { IconSprite = {} } }),
  emitted = {}, refreshes = 0, NowScale = 1,
  isInDispRange = function(_, pos) return pos.x > 0 end,
  get_Valid = function() return true end,
  updateMapIcon = function(self) self.refreshes = self.refreshes + 1 end
}
function map:setMapScale()
  self.emitted = {}
  self.MapIconInfoList = list({ { IconSprite = {} } })
  hooks["app.ui040205.setupMapIcon"].pre({ [2] = self })
  hooks["app.ui040205.setupMapIcon"].post(91)
end
local function method(type_name, name)
  if name == "getGimmickList(app.GimmickID)" then return function() return list({}) end end
  if name == "addMapIconInfoList" or name == "addMapIconSpriteInfoList" then
    return function(self, info, _, pointer)
      assert(info.Pos.x > 0 and info.IsEnable and info.UniqId ~= nil)
      local cursor = objects[pointer]
      assert(cursor.value < 3, "wrote past icon pool")
      cursor.value = cursor.value + 1
      self.emitted[#self.emitted + 1] = info
      return { IconSprite = { set_Color = function(_, color_pointer)
        info.color = objects[color_pointer].value
      end } }
    end
  end
  return type_name .. "." .. name
end
sdk = {
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
    if path:match("_settings.json$") then settings_reads[#settings_reads + 1] = path; return nil end
    if path == "raze_MapMarkersAndCollectables/167.json" then
      return { locations = {
        ["00000001-0000-0000-0000-000000000000"] = { x = 1, y = 0, z = 1 },
        ["00000002-0000-0000-0000-000000000000"] = { x = 2, y = 0, z = 1 },
        ["00000003-0000-0000-0000-000000000000"] = { x = -1, y = 0, z = 1 }
      } }
    end
    assert(path:match("^raze_MapMarkersAndCollectables/%d+.json$"))
    return { locations = {} }
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
