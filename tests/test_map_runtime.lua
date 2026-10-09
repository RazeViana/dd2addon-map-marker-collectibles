-- Execute the complete map script against a small REFramework boundary fixture.
-- This checks Lua control flow and emitted icons; it does not simulate the native UI.
local hooks, callbacks, objects, next_address = {}, {}, {}, 1000
local messages, writes, ids, toggled = {}, {}, {}, false
local settings_reads = {}
local managers = {}
local chest_metadata = {schema_version=1, chests={}}
local chest_guids = {}
for _, kind in ipairs({10,11,12,495,692,693,694}) do
  local key = kind == 10 and '00000004-0000-0000-0000-000000000000'
    or string.format('%08x-0000-0000-0000-000000000000', kind + 1000)
  chest_guids[kind] = key
  chest_metadata.chests[key] = {gimmick_id=kind, variants={{world='any',quests={}}}}
end
local gimmicks_by_type, saved_keys, saved_records = {}, {}, {}
local small_chest_fixture = {locations={[chest_guids[10]]={x=1,y=0,z=1}}}
local dlc_data, dlc_guids, queried_gimmicks = {}, {}, {}
local steam_initialized, dlc_installed = true, true
local drawn_categories = {}
local drawn_checkboxes, drawn_text = {}, {}
local dlc_module = require('raze_MapMarkersAndCollectables.dlc_collectibles')
local create_coin_callbacks, ducat_diagnostics = dlc_module.coin_callbacks, nil
dlc_module.coin_callbacks = function(...)
  local callbacks, diagnostics = create_coin_callbacks(...)
  ducat_diagnostics = diagnostics
  return callbacks, diagnostics
end
local dlc_metadata={schema_version=1,records={}}
for _, kind in ipairs({755,757,758,795,826,885,894}) do
  local guid=string.format('%08x-0000-0000-0000-000000000000',kind+9000)
  dlc_guids[kind]=guid
  dlc_data[kind]={locations={[guid]={x=1,y=0,z=1}}}
  dlc_metadata.records[guid]={gimmick_id=kind,variants={{world='normal',quests={}}}}
  if kind<800 then dlc_metadata.records[guid].variants[1].unsupported='Trial activation unverified' end
end
local minimap_get_markers, minimap_options
local minimap_module = require("raze_MapMarkersAndCollectables.minimap")
local create_minimap = minimap_module.create
minimap_module.create = function(options)
  minimap_options = options
  minimap_get_markers = options.get_markers
  return create_minimap(options)
end
local hook_storage = {}
thread = { get_hook_storage = function() return hook_storage end }
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
local function priority_ref(priority)
  return { priority = priority,
    get_Prio = function(self) return self.priority end,
    set_Prio = function(self, value) self.priority = value end }
end
-- A native marker at a token's position can have a higher drawing priority
-- than the unused sprite slot borrowed for the token.
local native_marker = priority_ref(40)
native_marker.position = { x = 1, y = 0, z = 1 }
local native_panel = priority_ref(55)
local map = {
  MapIconSpriteSet = { atlas = { get_ResourcePath = function() return 'Gui/ui01/Common/map/UVS_map_01.uvs' end,
      add_ref = function(self) return self end },
    get_UVSequence = function(self) return self.atlas end,
    set_UVSequence = function(self, value) self.atlas = value end },
  MapIcon = { get_Length = function() return 1 end },
  MapIconSprite = { get_Length = function() return 3 end },
  MapIconInfoList = list({ { IconSprite = native_marker }, { Icon = native_panel } }),
  emitted = {}, refreshes = 0, NowScale = 1, IconScale = 1,
  isInDispRange = function(_, pos) return pos.x > 0 end,
  get_Valid = function() return true end,
  updateMapIcon = function(self) self.refreshes = self.refreshes + 1 end
}
function map:setMapScale()
  local previous = self.emitted
  hooks["app.ui040205.setupMapIcon"].pre({ [2] = self })
  for _, info in ipairs(previous) do
    local ref = info.ui_icon.IconSprite or info.ui_icon.Icon
    assert(ref.scale == ref.initial_scale, 'borrowed scale was not restored before native setup')
    assert(ref:get_Prio() == ref.initial_priority, 'borrowed priority was not restored before native setup')
    if ref.Sprite then assert(ref.Sprite.sequence == 1, 'borrowed UV sequence was not restored before native setup') end
    -- Native setup may reuse old custom slots for unrelated game icons.
    ref.scale = 2
    if ref.Sprite then ref.Sprite.sequence, ref.Sprite.pattern = 0, 3 end
    ref:set_Prio(73)
  end
  self.emitted = {}
  self.MapIconInfoList = list({ { IconSprite = native_marker }, { Icon = native_panel } })
  hooks["app.ui040205.setupMapIcon"].post(91)
  for _, info in ipairs(previous) do
    local ref = info.ui_icon.IconSprite or info.ui_icon.Icon
    assert(ref.scale == 2, 'custom cleanup overwrote a reused native scale')
    if ref.Sprite then
      assert(ref.Sprite.sequence == 0 and ref.Sprite.pattern == 3,
        'custom cleanup overwrote a reused native sprite')
    end
    assert(ref:get_Prio() == 73, 'custom cleanup overwrote a reused native priority')
  end
end
local function method(type_name, name)
  if name == "getGimmickList(app.GimmickID)" then
    return function(_, id) queried_gimmicks[id]=true; return list(gimmicks_by_type[id] or {}) end
  end
  if name == "getContext(System.Type)" then
    return function(record, context_type) return record[context_type] end
  end
  if name == "addMapIconInfoList" or name == "addMapIconSpriteInfoList" then
    return function(self, info, _, pointer, _, name_guid)
      assert(info.Pos.x > 0 and info.IsEnable and info.UniqId ~= nil)
      local cursor = objects[pointer]
      local limit=name=='addMapIconInfoList' and self.MapIcon:get_Length() or self.MapIconSprite:get_Length()
      assert(cursor.value < limit, "wrote past icon pool")
      cursor.value = cursor.value + 1
      self.emitted[#self.emitted + 1] = info
      local ui_icon = box()
      ui_icon.NameId = name_guid
      assert(name_guid:call("ToString") == "e26516a9-39b1-4e5d-a814-34aba7c7e023",
        "missing native item-name GUID for the hover panel")
      -- Reproduce the reported native newindex failure while keeping reads valid.
      -- Marker creation and hover text must work without assigning the Name field.
      setmetatable(ui_icon, {
        __index = function(_, key) if key == "Name" then return "Native item name" end end,
        __newindex = function(self, key, value)
          if key == "Name" then error("native MapIconInfo.Name assignment rejected") end
          rawset(self, key, value)
        end
      })
      local slot_scale = self.slot_scales and self.slot_scales[#self.emitted] or 1
      ui_icon.IconSprite = { scale = slot_scale, initial_scale = slot_scale,
        priority = 5, initial_priority = 5,
        get_Prio = function(self) return self.priority end,
        set_Prio = function(self, value) self.priority = value end,
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
      if name == 'addMapIconInfoList' then
        ui_icon.Icon = ui_icon.IconSprite
        ui_icon.Icon.Sprite, ui_icon.IconSprite = nil, nil
      end
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
    if name == 'via.Steam' then
      return {get_method=function(_, member)
        return {call=function(_, receiver, app_id)
          assert(receiver == nil)
          if member == 'get_Supported' then return true end
          if member == 'get_Initialized' then return steam_initialized end
          assert(member == 'isInstalledDlc(System.UInt64)' and app_id == 2593290)
          return dlc_installed
        end}
      end}
    end
    return { get_field = function(_, field)
      if name=='app.Gm83_169' and field=='FreeBitGet' then
        return {is_static=function() return true end,get_data=function() return 64 end}
      end
      return { get_offset_from_base = function() return 0 end }
    end,
      get_runtime_type = function() return name end,
      get_method = function(_, member) return method(name, member) end,
      create_instance = box }
  end,
  hook = function(member, pre, post) hooks[member] = { pre = pre, post = post } end,
  get_managed_singleton = function(name) return managers[name] end,
  to_managed_object = function(value) return objects[value] or value end
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
  on_script_reset = function(callback) callbacks.reset = callback end,
  on_draw_ui = function(callback) callbacks.ui = callback end }
json = {
  load_file = function(path)
    if path == 'raze_MapMarkersAndCollectables/chest-availability.json' then return chest_metadata end
    if path == 'raze_MapMarkersAndCollectables/dlc-availability.json' then return dlc_metadata end
    if path:match("_settings.json$") then
      settings_reads[#settings_reads + 1] = path
      return { markers = { ["Golden Trove Beetles"] = { unacquired_show = false },
        ['Norgan Ducats']={unacquired_show=false},['Norgan Chests']={unacquired_show=false},
        ['Norgan Rare Chests']={unacquired_show=false},['Lost Rites Chests']={unacquired_show=false}
      }, quests={enabled=false} }
    end
    if path == "raze_MapMarkersAndCollectables/167.json" then
      return { locations = {
        ["00000001-0000-0000-0000-000000000000"] = { x = 1, y = 0, z = 1 },
        ["00000002-0000-0000-0000-000000000000"] = { x = 2, y = 0, z = 1 },
        ["00000003-0000-0000-0000-000000000000"] = { x = -1, y = 0, z = 1 }
      } }
    end
    assert(path:match("^raze_MapMarkersAndCollectables/%d+.json$"))
    local kind = tonumber(path:match('/(%d+)%.json$'))
    if kind == 10 then return small_chest_fixture end
    if dlc_data[kind] then return dlc_data[kind] end
    return { locations = { [chest_guids[kind] or "00000004-0000-0000-0000-000000000000"] = { x = 1, y = 0, z = 1 } } }
  end,
  dump_file = function(path, value) writes[path] = value; return true end
}
imgui = {
  tree_node = function(label) return label == "Map Markers and Collectables by Raze" end,
  tree_pop = function() end, text = function(message) drawn_text[message]=true end, text_colored = function() end,
  push_id = function(id) ids[#ids + 1] = id; drawn_categories[id]=true end,
  pop_id = function() table.remove(ids) end,
  push_style_color = function() end, pop_style_color = function() end,
  arrow_button = function() return false end, same_line = function() end,
  slider_int = function(_, value) return false, value end,
  is_item_hovered = function() return false end, button = function() return false end,
  checkbox = function(label, value)
    drawn_checkboxes[label]=true
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
  IndexCreator = { UniqueID2Keys = { TryGetValue = function(_, id, pointer)
    local key = saved_keys[id.key]
    if not key then return false end
    objects[pointer].value = key:get_address()
    return true
  end } },
  Records = setmetatable({ get_Count = function() return #saved_records end }, {
    __index = function(_, index) return saved_records[index + 1] end
  })
}
local function save_context(guid, context_type, context)
  local key = box()
  key.KeyForSystem = #saved_records
  key.get_IsValid = function() return true end
  saved_keys[guid] = key
  saved_records[#saved_records + 1] = {
    get_Record = function() return { [context_type] = context } end
  }
end
managers["app.GenerateManager"] = { isNeverGenerate = function() return false end }
managers["app.GimmickManager"] = {}
managers["app.ContextDBMS"] = { get_CurrentDB = function() return database end }
map:setMapScale()
assert(lock_count == 0)
assert(#map.emitted == 2)
assert(map.emitted[1].color == 0xFF00CC00)
assert(map.emitted[1].IconType == 31 and map.emitted[1].ui_icon.IconSprite.Sprite.pattern == 0,
  'token did not use the token artwork')
assert(map.emitted[1].ui_icon.IconSprite.scale == 0.5, 'full-map icon was not halved')
for _, info in ipairs(map.emitted) do
  assert(info.ui_icon.IconSprite:get_Prio() > native_marker:get_Prio(),
    'overlapping native marker still draws above the half-size token')
  assert(info.Pos.x == 1 or info.Pos.x == 2, 'ordering moved a token away from its location')
  assert(info.ui_icon.IconSprite:get_Prio() > native_panel:get_Prio(),
    'native panel marker still has priority over the token')
end
assert(native_marker:get_Prio() == 40, 'collectible ordering changed a native marker priority')
local size_hook = hooks['app.ui040205.updateMapIcon']
size_hook.pre({[2]=map}); size_hook.post(91)
size_hook.pre({[2]=map}); size_hook.post(91)
assert(map.emitted[1].ui_icon.IconSprite.scale == 0.5, 'full-map size accumulated')
-- Reused and newly available slots can retain scales from different zoom levels.
-- Both tokens must use the current map scale, including when native updates skip a slot.
map.slot_scales, map.IconScale = { 0.6, 1.2 }, 0.8
map:setMapScale()
for _, info in ipairs(map.emitted) do
  assert(math.abs(info.ui_icon.IconSprite.scale - 0.4) < 1e-6,
    'same token artwork has different sizes after reusing slots at a new zoom')
end
local native_ref = native_panel
native_ref.scale, native_ref.set_Scale = 1.7, function(self, value) self.scale = value end
map.MapIconInfoList = list({ { IconSprite = native_marker, Icon = native_ref },
  map.emitted[1].ui_icon, map.emitted[2].ui_icon })
for _, zoom in ipairs({ { 1.2, 0.6 }, { 0.6, 0.3 }, { 0.8, 0.4 } }) do
  map.IconScale = zoom[1]
  for frame = 1, 3 do
    size_hook.pre({ [2] = map })
    -- Simulate native scale writes for only one of the two custom slots.
    map.emitted[1].ui_icon.IconSprite.scale = map.IconScale
    native_marker:set_Prio(60 + frame)
    map.emitted[1].ui_icon.IconSprite:set_Prio(5)
    assert(size_hook.post(91) == 91)
    for _, info in ipairs(map.emitted) do
      assert(math.abs(info.ui_icon.IconSprite.scale - zoom[2]) < 1e-6,
        'custom sizes did not follow zoom consistently or accumulated across frames')
      assert(info.ui_icon.IconSprite:get_Prio() == native_marker:get_Prio() + 1,
        'custom priority was not reapplied after native updates or accumulated across frames')
    end
    assert(native_ref.scale == 1.7, 'zoom sizing changed a native marker')
    assert(native_ref:get_Prio() == 55 and native_marker:get_Prio() == 60 + frame,
      'custom ordering changed native panel or sprite priority')
  end
end
map.slot_scales, map.IconScale = nil, 1
map:setMapScale()
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
    local expected = ({["Seeker's Tokens"]=0, ["Golden Trove Beetles"]=1,
      ["Chests (S)"]=4, ["Chests (M)"]=2, ["Chests (L)"]=5, ["Chests (XL)"]=6})[category] or 3
    assert(emitted.IconType == 31 and emitted.ui_icon.IconSprite.Sprite.sequence == 2
      and emitted.ui_icon.IconSprite.Sprite.pattern == expected, 'wrong object artwork for ' .. category)
    map.SelectedIcon = emitted.ui_icon
    map.TxtName.message = "Native text"
    hover_hook.pre({ [2] = map }); hover_hook.post(91)
    assert(map.TxtName.message == label, "native hover text was not replaced for " .. category)
  end
end
-- A save can contain acquired state before the mod has ever seen a pickup.
local beetle_guid = "00000004-0000-0000-0000-000000000000"
local function show_category(category)
  for name, marker in pairs(saved_settings.markers) do
    marker.unacquired_show, marker.acquired_show = name == category, false
  end
  hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
end
show_category("Golden Trove Beetles")
save_context(beetle_guid, "app.GatherContext", { get_Num = function() return 0 end })
map:setMapScale()
assert(#map.emitted == 0, 'previously collected beetle appeared before its area loaded')
-- In NG+ an empty beetle location may still have a loaded gimmick reporting not broken.
gimmicks_by_type[161] = {{
  get_UniqId = function() return { ToString = function() return beetle_guid .. "_0" end } end,
  get_IsBroken = function() return false end
}}
local nearby_markers = minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60)
assert(#nearby_markers == 0, 'nearby refresh resurrected a beetle already collected in the save')
hooks["app.ui040205..ctor"].pre({ [2] = map })
hooks["app.ui040205..ctor"].post(91)
map:setMapScale()
assert(#map.emitted == 0, 'nearby refresh made a collected beetle reappear on the world map')
-- An acquired-only view must use the same saved status, rather than simply suppress the icon.
saved_settings.markers["Golden Trove Beetles"].unacquired_show = false
saved_settings.markers["Golden Trove Beetles"].acquired_show = true
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
assert(#minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 1,
  'saved beetle was not classified as acquired')
-- Loading a different save must discard the previous save's acquired cache.
saved_keys, saved_records, gimmicks_by_type = {}, {}, {}
show_category("Golden Trove Beetles")
save_context(beetle_guid, "app.GatherContext", { get_Num = function() return 1 end })
map:setMapScale()
assert(#map.emitted == 1, 'another save inherited acquired beetle state')
gimmicks_by_type[161] = {{
  get_UniqId = function() return { ToString = function() return beetle_guid .. "_0" end } end,
  get_IsBroken = function() return false end
}}
assert(#minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 1,
  'an uncollected beetle was hidden when its area loaded')
saved_keys, saved_records = {}, {}
assert(#minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 1,
  'a beetle with no saved collection record was assumed acquired')
save_context(beetle_guid, "app.GatherContext", { get_Num = function() return 1 end })
-- A fresh pickup can be observed live before the saved context catches up.
gimmicks_by_type[161] = {{
  get_UniqId = function() return { ToString = function() return beetle_guid .. "_0" end } end,
  get_IsBroken = function() return true end
}}
assert(#minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 0,
  'fresh beetle pickup was ignored while saved state lagged')
-- Existing token and chest saves are also read without a live object or pickup history.
saved_keys, saved_records, gimmicks_by_type = {}, {}, {}
show_category("Seeker's Tokens")
save_context("00000001-0000-0000-0000-000000000000", "app.GimmickContext", {
  isOnFreeBit = function(_, bit) assert(bit == 16); return true end
})
map:setMapScale()
assert(#map.emitted == 1 and map.emitted[1].UniqId.key == "00000002-0000-0000-0000-000000000000",
  'existing token save was not distinguished from an uncollected token')
saved_keys, saved_records = {}, {}
show_category("Chests (S)")
save_context(beetle_guid, "app.GmItemContext", { get_IsPick = function() return true end })
map:setMapScale()
assert(#map.emitted == 0, 'previously opened chest appeared with no live object')
-- Installing after a chest was opened must also classify it as acquired while
-- its area is unloaded, before a nearby pickup or a live refresh has occurred.
local chest_settings = saved_settings.markers["Chests (S)"]
chest_settings.unacquired_show, chest_settings.acquired_show = false, true
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
map:setMapScale()
assert(#map.emitted == 1 and map.emitted[1].UniqId.key == beetle_guid,
  'late installation did not classify the saved chest as acquired')
chest_settings.unacquired_show, chest_settings.acquired_show = true, false
local live_chest_opened = false
gimmicks_by_type[10] = {{
  get_UniqId = function() return { ToString = function() return beetle_guid .. "_0" end } end,
  get_IsOpenedFreeBit = function() return live_chest_opened end
}}
assert(#minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 0,
  'loaded closed chest overrode saved acquisition during a nearby refresh')
hooks["app.ui040205..ctor"].pre({ [2] = map })
hooks["app.ui040205..ctor"].post(91)
map:setMapScale()
assert(#map.emitted == 0, 'nearby refresh resurrected a saved chest on the full map')
chest_settings.unacquired_show, chest_settings.acquired_show = false, true
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
map:setMapScale()
assert(#map.emitted == 1 and #minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 1,
  'saved acquisition was lost from the acquired-only chest view')
-- An older save or a new cycle can make this GUID unacquired again. The native
-- context reset must discard the prior positive cache for both map surfaces.
saved_keys, saved_records = {}, {}
save_context(beetle_guid, "app.GmItemContext", { get_IsPick = function() return false end })
chest_settings.unacquired_show, chest_settings.acquired_show = true, false
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
map:setMapScale()
assert(#map.emitted == 1 and #minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 1,
  'reloaded chest inherited acquisition from the previous save')
-- A new opening is immediately conclusive even if the saved context still lags.
live_chest_opened = true
assert(#minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 0,
  'fresh chest opening was ignored while saved acquisition lagged')
hooks["app.ui040205..ctor"].pre({ [2] = map })
hooks["app.ui040205..ctor"].post(91)
map:setMapScale()
assert(#map.emitted == 0, 'fresh chest opening was lost from the full map')
assert(lock_count == 0, 'chest state refresh leaked the context read lock')
saved_keys, saved_records, gimmicks_by_type = {}, {}, {}
show_category("Special Chests (L)")
map:setMapScale()
-- Category artwork must reach both map renderers independently of the global style.
saved_settings.markers["Special Chests (L)"].unacquired_icon_style = "large"
saved_settings.object_icons = false
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
map:setMapScale()
assert(map.emitted[1].ui_icon.IconSprite.Sprite.pattern == 5,
  'full map ignored the category artwork override')
assert(minimap_get_markers({x=1,y=0,z=1},180,60)[1].icon_type == 81,
  'minimap ignored the category artwork override')
saved_settings.markers["Special Chests (L)"].unacquired_icon_style = "default"
saved_settings.object_icons = true
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
map:setMapScale()
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
-- Full-map visibility is independent, refreshes an open map, and survives saving.
local function toggle_map(label, enabled)
  local found = false
  imgui.checkbox = function(name, value)
    if name == label then found = true; return value ~= enabled, enabled end
    return false, value
  end
  callbacks.ui()
  imgui.checkbox = old_checkbox
  assert(found, "missing visibility control: " .. label)
  hooks["app.ui040205.update"].pre({ [2] = map })
end
-- Progression filters cached markers on both surfaces, without changing acquired history.
local is_unmoored = false
managers['app.MainFlowManager'] = {get_IsBackStage=function() return is_unmoored end}
saved_keys, saved_records, gimmicks_by_type = {}, {}, {}
show_category('Chests (S)')
local small_rule = chest_metadata.chests[chest_guids[10]].variants[1]
small_rule.world = 'unmoored'
map:setMapScale()
assert(#map.emitted==0, 'unobtainable chest was shown before the Unmoored World')
local cached_progression_markers = minimap_get_markers({x=1,y=0,z=1},180,60)
assert(#minimap_options.filter_markers({},cached_progression_markers)==0,
  'minimap did not apply progression to cached candidates')
is_unmoored = true
-- The regular UI update must notice progression changes without a zoom/reopen.
local original_clock = os.clock
os.clock = function() return original_clock() + 2 end
hooks['app.ui040205.update'].pre({[2]=map})
os.clock = original_clock
assert(#map.emitted==1 and #minimap_options.filter_markers({},cached_progression_markers)==1,
  'world transition did not reveal cached chest markers')
is_unmoored = false
toggle_map('Reveal Unmoored-only chests early', true)
assert(#map.emitted==1 and #minimap_options.filter_markers({},cached_progression_markers)==1)
toggle_map('Reveal Unmoored-only chests early', false)
assert(#map.emitted==0)
toggle_map('Hide unobtainable chests', false)
assert(#map.emitted==1, 'availability display override did not refresh the map')
toggle_map('Hide unobtainable chests', true)
assert(#map.emitted==0)
callbacks.save()
assert(saved_settings.hide_unavailable_chests and not saved_settings.reveal_unmoored_chests)
save_context(beetle_guid, 'app.GmItemContext', {get_IsPick=function() return true end})
saved_settings.markers['Chests (S)'].unacquired_show = false
saved_settings.markers['Chests (S)'].acquired_show = true
hooks['app.ContextDatabase.clearAllContextsImpl'].pre({})
map:setMapScale()
assert(#map.emitted==1, 'progression hiding suppressed the acquired-only view')
small_rule.world = 'any'
saved_keys, saved_records = {}, {}
show_category('Special Chests (L)')
map:setMapScale()
local hidden_icon = map.emitted[1].ui_icon
toggle_map("Show on full map", false)
assert(#map.emitted == 0, "disabling the full map left custom markers visible")
assert(map.MapIconInfoList:get_Count() == 2, "disabling custom markers removed native map entries")
map.SelectedIcon, map.TxtName.message = hidden_icon, "Native text"
hover_hook.pre({ [2] = map }); hover_hook.post(91)
assert(map.TxtName.message == "Native text", "disabled full map retained a custom hover label")
callbacks.save()
assert(writes["raze_MapMarkersAndCollectables_settings.json"].fullmap.enabled == false,
  "full-map visibility was not saved")
assert(saved_settings.minimap.enabled == true, "full-map toggle disabled the minimap")
assert(#minimap_get_markers({ x = 1, y = 0, z = 1 }, 180, 60) == 1,
  "full-map toggle suppressed minimap candidates")
-- Reopening while disabled must also skip collectible lookups.
hooks["app.ui040205..ctor"].pre({ [2] = map })
hooks["app.ui040205..ctor"].post(91)
local get_manager = sdk.get_managed_singleton
sdk.get_managed_singleton = function() error("disabled full map queried collectible state") end
map:setMapScale()
sdk.get_managed_singleton = get_manager
assert(#map.emitted == 0, "reopening a disabled full map added custom markers")
toggle_map("Show on minimap", false)
toggle_map("Show on full map", true)
assert(#map.emitted == 1, "re-enabling the full map did not restore selected categories")
assert(saved_settings.minimap.enabled == false, "full-map toggle enabled the minimap")
assert(map.emitted[1].IconType == 25 and map.emitted[1].ui_icon.IconSprite.scale == 1.25,
  "full-map toggle lost symbol or size preferences")
map.SelectedIcon = map.emitted[1].ui_icon
hover_hook.pre({ [2] = map }); hover_hook.post(91)
assert(map.TxtName.message == "Special Chest (L)", "re-enabled full map lost hover labels")
toggle_map("Show on minimap", true)
assert(#map.emitted == 1, "minimap toggle hid full-map markers")
callbacks.save()
assert(writes["raze_MapMarkersAndCollectables_settings.json"].fullmap.enabled == true,
  "re-enabled full-map visibility was not saved")
-- The actual settings controls feed the live minimap renderer and config save.
local old_tree_node = imgui.tree_node
imgui.tree_node = function(label) return label == "Minimap settings" or old_tree_node(label) end
imgui.drag_int = function(label, value)
  if label == "Height tolerance (world units)" then return true, 7 end
  return false, value
end
toggle_map("Show height indicators", false)
callbacks.save()
assert(minimap_options.settings.height_indicators == false and minimap_options.settings.height_tolerance == 7,
  "height controls did not reach the live minimap renderer")
assert(writes["raze_MapMarkersAndCollectables_settings.json"].minimap.height_tolerance == 7,
  "height tolerance was not saved")
toggle_map("Show height indicators", true)
assert(minimap_options.settings.height_indicators == true and #map.emitted == 1)
imgui.tree_node = old_tree_node
-- The main entry point connects both directions to the installed arrow atlas.
local mini_atlas = { get_ResourcePath = function() return "Gui/ui01/Common/map/UVS_map_03.uvs" end,
  add_ref = function(self) return self end }
local mini_ui = { MapIconSpriteSet = {
  get_UVSequence = function() return mini_atlas end,
  set_UVSequence = function(_, value) mini_atlas = value end
} }
local arrow_sprite = { sequence = 1, pattern = 25,
  set_UVSequenceNo = function(self, value) self.sequence = value end,
  set_UVPatternNo = function(self, value) self.pattern = value end }
assert(minimap_options.apply_height(mini_ui, {Sprite=arrow_sprite}, 1))
assert(arrow_sprite.sequence == 3 and arrow_sprite.pattern == 0)
assert(minimap_options.apply_height(mini_ui, {Sprite=arrow_sprite}, -1))
assert(arrow_sprite.pattern == 1 and mini_atlas:get_ResourcePath() == "raze/mapmarkers/minimap.uvs")
-- Fog filtering is independent of acquisition, artwork, and each map's visibility.
local fog_revealed, fog_queries = false, 0
local fog_mask = { MaskBit = { get_Length = function() return 1 end } }
local previous_method = method
method = function(type_name, name)
  if type_name == "app.GuiManager.MapMaskInfo" and name == "isMaskOff(via.vec3)" then
    return function(mask, pos)
      fog_queries = fog_queries + 1
      assert(mask == fog_mask and (pos.x == 1 or pos.x == 2 or pos.x == -1) and pos.z == 1)
      return fog_revealed
    end
  end
  return previous_method(type_name, name)
end
managers["app.GuiManager"] = { getMaskInfo = function(_, area)
  assert(area == 17, "fog lookup did not use the displayed area")
  return fog_mask
end }
map.LocalAreaNow = 17
map.IsFieldMap = true
local fog_ui = { LocalAreaNow = 17, IsDispField = true }
toggle_map("Hide chests in unexplored areas", true)
assert(#map.emitted == 0, "enabling fog filtering left a special chest visible")
assert(#minimap_options.filter_markers(fog_ui, minimap_get_markers({x=1,y=0,z=1},180,60)) == 0,
  "fog-covered chest appeared on the minimap")
callbacks.save()
assert(writes["raze_MapMarkersAndCollectables_settings.json"].hide_unexplored_chests == true,
  "fog preference was not saved")
local original_range, queries_before = map.isInDispRange, fog_queries
map.isInDispRange = function() return false end
map:setMapScale()
assert(#map.emitted == 0 and fog_queries == queries_before,
  "chest outside the displayed local map was sent to its native fog lookup")
map.isInDispRange = original_range
for _, category in ipairs({"Chests (S)", "Chests (M)", "Chests (L)", "Chests (XL)",
    "Special Chests (S)", "Special Chests (M)", "Special Chests (L)"}) do
  show_category(category)
  fog_revealed = false
  map:setMapScale()
  assert(#map.emitted == 0, "fog did not hide " .. category)
  local cached_chests = minimap_get_markers({x=1,y=0,z=1},180,60)
  assert(#cached_chests == 1, "local-map test did not isolate the selected chest category")
  -- The full map and minimap can display different modes. Each must apply its
  -- own mode to the same cached candidates when entering/leaving a local map.
  map.IsFieldMap = false
  local queries_before_local_map = fog_queries
  map:setMapScale()
  assert(#map.emitted == 1 and fog_queries == queries_before_local_map,
    "local full map still filtered " .. category .. " through fog")
  assert(#minimap_options.filter_markers(fog_ui, cached_chests) == 0,
    "local full map incorrectly disabled outdoor minimap fog")
  fog_ui.IsDispField = false
  queries_before_local_map = fog_queries
  assert(#minimap_options.filter_markers(fog_ui, cached_chests) == 1
    and fog_queries == queries_before_local_map, "local minimap still queried chest fog")
  map.IsFieldMap = true
  map:setMapScale()
  assert(#map.emitted == 0, "returning to the outdoor full map left a cached chest visible")
  assert(#minimap_options.filter_markers(fog_ui, cached_chests) == 1,
    "outdoor full map incorrectly enabled fog on a local minimap")
  fog_ui.IsDispField = true
  assert(#minimap_options.filter_markers(fog_ui, cached_chests) == 0,
    "returning to the outdoor minimap left a cached chest visible")
  assert(saved_settings.hide_unexplored_chests == true, "map transition changed the chest preference")
  fog_revealed = true
  -- Neither the collectible cache nor the marker cache is invalidated here.
  map:setMapScale()
  assert(#map.emitted == 1, "revealing fog left a cached chest hidden: " .. category)
end
fog_revealed = false
for _, category in ipairs({"Seeker's Tokens", "Golden Trove Beetles"}) do
  show_category(category)
  map:setMapScale()
  assert(#map.emitted > 0, "chest fog toggle affected " .. category)
end
show_category("Chests (S)")
save_context(beetle_guid, "app.GmItemContext", { get_IsPick = function() return true end })
fog_revealed = true
map:setMapScale()
assert(#map.emitted == 0, "revealed fog overrode acquired-chest visibility")
map.IsFieldMap, fog_ui.IsDispField = false, false
map:setMapScale()
assert(#map.emitted == 0, "local-map bypass revealed an acquired chest")
assert(#minimap_get_markers({x=1,y=0,z=1},180,60) == 0,
  "local minimap bypass revealed an acquired chest")
saved_settings.markers["Chests (S)"].acquired_show = true
hooks["app.ContextDatabase.clearAllContextsImpl"].pre({})
map:setMapScale()
assert(#map.emitted == 1)
fog_revealed = false
map:setMapScale()
assert(#map.emitted == 1, "local-map bypass did not retain the acquired-only choice")
map.IsFieldMap, fog_ui.IsDispField = true, true
fog_revealed = false
map:setMapScale()
assert(#map.emitted == 0, "acquired-only chest bypassed fog filtering")
toggle_map("Hide chests in unexplored areas", false)
assert(#map.emitted == 1 and map.emitted[1].IconType == 25,
  "disabling fog filtering did not restore the saved chest display")
callbacks.save()
assert(saved_settings.hide_unexplored_chests == false)
-- The two new fog controls refresh both maps and preserve the other preferences.
saved_keys, saved_records, gimmicks_by_type = {}, {}, {}
for _, case in ipairs({
  {category="Golden Trove Beetles", key="hide_unexplored_beetles", label="Hide beetles in unexplored areas", count=1, nearby_count=1},
  {category="Seeker's Tokens", key="hide_unexplored_tokens", label="Hide Seeker's Tokens in unexplored areas", count=2, nearby_count=3}
}) do
  show_category(case.category)
  fog_revealed = false
  map:setMapScale()
  assert(#map.emitted == case.count, "new fog toggle was enabled by default")
  toggle_map(case.label, true)
  assert(#map.emitted == 0, "new fog control did not hide " .. case.category)
  local cached_candidates = minimap_get_markers({x=1,y=0,z=1},180,60)
  assert(#minimap_options.filter_markers(fog_ui, cached_candidates) == 0,
    "minimap did not receive new fog preference for " .. case.category)
  callbacks.save()
  assert(saved_settings[case.key] == true and saved_settings.hide_unexplored_chests == false,
    "saving a new fog preference changed chest filtering")
  fog_revealed = true
  map:setMapScale()
  assert(#map.emitted == case.count, "newly revealed items stayed hidden on the full map")
  assert(#minimap_options.filter_markers(fog_ui, cached_candidates) == case.nearby_count,
    "newly revealed items stayed hidden in cached minimap candidates")
  fog_revealed = false
  -- Other categories still appear when their own fog preference is off.
  show_category("Chests (S)")
  map:setMapScale()
  assert(#map.emitted == 1, "beetle/token fog filtering affected chests")
  show_category(case.category)
  map:setMapScale()
  toggle_map(case.label, false)
  assert(#map.emitted == case.count, "disabling new fog control did not restore markers")
  callbacks.save()
  assert(saved_settings[case.key] == false)
end
-- First-token guidance is independent of ordinary acquisition/category visibility.
do
  show_category("Seeker's Tokens")
  saved_settings.object_icons = true
  saved_settings.markers["Seeker's Tokens"].unacquired_icon_style = 'default'
  local proof = box()
  proof.key = '00000001-0000-0000-0000-000000000000'
  local first_empty, finder_collected, finder_spawned = true, false, false
  proof.isEmpty = function() return first_empty end
  managers['app.GimmickManager'] = { get_FirstSeekerProof = function() return proof end,
    isGimmickFlag = function(_, flag)
      if flag == 18 then return finder_spawned end
      if flag == 40 then return true end
      if flag == 122 then return finder_collected end
      error('unexpected gimmick flag ' .. tostring(flag))
    end }
  map:setMapScale()
  assert(#map.emitted == 2 and map.emitted[1].color ~= 0xFF0000FF,
    'first-token marker appeared before any token was collected')
  local cached = minimap_get_markers({x=1,y=0,z=1},180,60)
  first_empty = false
  save_context(proof.key, 'app.GimmickContext', {isOnFreeBit=function(_, bit) assert(bit == 16); return true end})
  local real_clock, tick = os.clock, os.clock() + 20
  os.clock = function() return tick end
  hooks['app.ui040205.update'].pre({[2]=map})
  assert(#map.emitted == 2 and map.emitted[1].color == 0xFF0000FF,
    'first pickup did not refresh the cached full map with one red marker')
  assert(map.emitted[1].UniqId == proof and map.emitted[1].Pos.x == 1)
  assert(map.emitted[1].ui_icon.IconSprite.Sprite.pattern == 0)
  map.SelectedIcon = map.emitted[1].ui_icon
  hover_hook.pre({[2]=map}); hover_hook.post(91)
  assert(map.TxtName.message == "First Seeker's Token")
  local mini = minimap_options.filter_markers(fog_ui, cached)
  assert(#mini == 3 and mini[1].icon_color == 0xFF0000FF,
    'cached minimap candidates did not replace the original token with red guidance')
  for _, marker in ipairs(mini) do assert(marker.key ~= proof.key, 'duplicate original token') end
  -- The Sphinx turns on the item's display flag before the Finder is collected.
  finder_spawned, tick = true, tick + 2
  hooks['app.ui040205.update'].pre({[2]=map})
  assert(#map.emitted == 2 and map.emitted[1].color == 0xFF0000FF,
    'starting the Sphinx riddle hid the red marker on the full map')
  mini = minimap_options.filter_markers(fog_ui, cached)
  assert(#mini == 3 and mini[1].icon_color == 0xFF0000FF,
    'starting the Sphinx riddle hid the red marker on the minimap')
  saved_settings.markers["Seeker's Tokens"].unacquired_show = false
  hooks['app.ContextDatabase.clearAllContextsImpl'].pre({})
  map:setMapScale()
  assert(#map.emitted == 1 and map.emitted[1].color == 0xFF0000FF,
    'ordinary token category visibility hid the special marker')
  toggle_map("Show first Seeker's Token", false)
  assert(#map.emitted == 0 and saved_settings.show_first_seeker_token == false)
  toggle_map("Show first Seeker's Token", true)
  assert(#map.emitted == 1)
  toggle_map("Hide Seeker's Tokens in unexplored areas", true)
  assert(#map.emitted == 0 and #minimap_options.filter_markers(fog_ui, {}) == 0)
  toggle_map("Hide Seeker's Tokens in unexplored areas", false)
  assert(#map.emitted == 1)
  finder_collected, tick = true, tick + 2
  hooks['app.ui040205.update'].pre({[2]=map})
  assert(#map.emitted == 0, 'Finder pickup left the first-token marker on the open map')
  assert(#minimap_options.filter_markers(fog_ui, {}) == 0,
    'Finder pickup left a minimap guidance marker')
  finder_spawned, tick = false, tick + 2
  hooks['app.ui040205.update'].pre({[2]=map})
  assert(#map.emitted == 0 and #minimap_options.filter_markers(fog_ui, {}) == 0,
    'clearing the Finder display flag revived a collected marker')
  toggle_map("Show after Finder's Token collection", true)
  assert(#map.emitted == 1 and map.emitted[1].color == 0xFF0000FF,
    'show-after-collection did not restore the red full-map marker immediately')
  mini = minimap_options.filter_markers(fog_ui, cached)
  assert(mini[1].icon_color == 0xFF0000FF and mini[1].pos.x == 1,
    'show-after-collection did not restore the cached minimap marker')
  callbacks.save()
  assert(saved_settings.show_first_token_after_collection == true,
    'show-after-collection preference was not saved')
  toggle_map("Show first Seeker's Token", false)
  assert(#map.emitted == 0 and #minimap_options.filter_markers(fog_ui, {}) == 0,
    'historical marker ignored the main visibility toggle')
  toggle_map("Show first Seeker's Token", true)
  assert(#map.emitted == 1, 'historical preference was lost when the main toggle changed')
  toggle_map("Hide Seeker's Tokens in unexplored areas", true)
  assert(#map.emitted == 0 and #minimap_options.filter_markers(fog_ui, {}) == 0,
    'historical marker ignored token fog preferences')
  toggle_map("Hide Seeker's Tokens in unexplored areas", false)
  toggle_map("Show after Finder's Token collection", false)
  assert(#map.emitted == 0 and #minimap_options.filter_markers(fog_ui, {}) == 0,
    'turning show-after-collection off left a completed marker visible')
  callbacks.save()
  assert(saved_settings.show_first_token_after_collection == false)
  -- A different save/current-playthrough proof replaces the location instead of retaining history.
  finder_collected, proof.key = false, '00000002-0000-0000-0000-000000000000'
  hooks['app.ContextDatabase.clearAllContextsImpl'].pre({})
  map:setMapScale()
  assert(#map.emitted == 1 and map.emitted[1].Pos.x == 2 and map.emitted[1].color == 0xFF0000FF)
  saved_settings.object_icons = false
  saved_settings.markers["Seeker's Tokens"].unacquired_icon_type = 25
  map:setMapScale()
  assert(map.emitted[1].IconType == 25 and map.emitted[1].color == 0xFF0000FF)
  callbacks.save()
  assert(saved_settings.show_first_seeker_token == true)
  os.clock = real_clock
  managers['app.GimmickManager'] = {}
  saved_keys, saved_records = {}, {}
  hooks['app.ContextDatabase.clearAllContextsImpl'].pre({})
end
-- The fallback panel pool uses the same native priority API. Game symbols,
-- map toggles, and script resets must keep the same ordering/restoration rules.
saved_settings.icon_size = 50
saved_settings.object_icons = false
map.MapIcon = { get_Length = function() return 3 end }
map.MapIconSprite = { get_Length = function() return 1 end }
show_category("Seeker's Tokens")
map:setMapScale()
assert(#map.emitted == 2 and map.emitted[1].ui_icon.Icon, 'panel fallback was not exercised')
for _, info in ipairs(map.emitted) do
  local ref = info.ui_icon.Icon
  assert(ref.scale == 0.5 and ref:get_Prio() > native_marker:get_Prio()
    and ref:get_Prio() > native_panel:get_Prio(), 'panel token was not raised at the chosen size')
end
toggle_map("Show on full map", false)
toggle_map("Show on full map", true)
local reset_refs = {}
for _, info in ipairs(map.emitted) do reset_refs[#reset_refs + 1] = info.ui_icon.Icon end
callbacks.reset()
for _, ref in ipairs(reset_refs) do
  assert(ref.scale == ref.initial_scale and ref:get_Prio() == ref.initial_priority,
    'script reset did not restore a borrowed panel')
  ref:set_Prio(29)
end
size_hook.pre({ [2] = map }); size_hook.post(91)
for _, ref in ipairs(reset_refs) do
  assert(ref:get_Prio() == 29, 'script reset left stale priority overrides')
  ref:set_Prio(ref.initial_priority)
end
-- Return to sprites and verify script-reset cleanup for their priorities too.
map.MapIcon = { get_Length = function() return 1 end }
map.MapIconSprite = { get_Length = function() return 3 end }
map:setMapScale()
reset_refs = {}
for _, info in ipairs(map.emitted) do reset_refs[#reset_refs + 1] = info.ui_icon.IconSprite end
callbacks.reset()
for _, ref in ipairs(reset_refs) do
  assert(ref.scale == ref.initial_scale and ref:get_Prio() == ref.initial_priority,
    'script reset did not restore a borrowed sprite')
end
-- Exercise the actual collection loop with DLC data, native types, history and filtering.
saved_keys,saved_records,gimmicks_by_type={}, {}, {}
saved_settings.show_first_seeker_token=false
saved_settings.object_icons=true
saved_settings.hide_unavailable_chests=true
saved_settings.hide_unexplored_ducats=false
is_unmoored=false
map.MapIconSprite={get_Length=function() return 10 end}
local ducat_picked=false
gimmicks_by_type[894]={{get_UniqId=function() return {ToString=function() return dlc_guids[894]..'_0' end} end,
  get_IsGetFreeBit=function() return ducat_picked end}}
save_context(dlc_guids[894],'app.GimmickContext',{isOnFreeBit=function(_,bit)
  assert(bit==64,'Ducat history assumed the original token flag'); return true end})
show_category('Norgan Ducats'); map:setMapScale()
assert(#map.emitted==0 and #minimap_get_markers({x=1,y=0,z=1},180,60)==0,
  'a loaded unpicked Ducat overrode its saved pickup history')
saved_keys,saved_records={},{}
show_category('Norgan Ducats'); map:setMapScale()
assert(#map.emitted==1 and #minimap_get_markers({x=1,y=0,z=1},180,60)==1)
assert(map.emitted[1].IconType==31 and map.emitted[1].ui_icon.IconSprite.Sprite.pattern==10,
  'Ducat artwork did not reach the full-map renderer')
map.SelectedIcon=map.emitted[1].ui_icon
hover_hook.pre({[2]=map}); hover_hook.post(91)
assert(map.TxtName.message=='Norgan Ducat')
ducat_picked=true
show_category('Norgan Ducats'); map:setMapScale()
assert(#map.emitted==0,'a new Ducat pickup stayed on the map')
show_category('Lost Rites Chests'); map:setMapScale()
assert(#map.emitted==0,'unknown trial activation was shown as actionable')
for _,kind in ipairs({755,757,758,795}) do
  assert(queried_gimmicks[kind],'grouped trial chest native list was not queried')
  -- A resolved activation fixture proves per-marker native IDs survive grouping.
  dlc_metadata.records[dlc_guids[kind]].variants[1].unsupported=nil
end
local trial_opened=true
gimmicks_by_type[755]={{get_UniqId=function() return {ToString=function() return dlc_guids[755]..'_0' end} end,
  get_IsOpenedFreeBit=function() return trial_opened end}}
show_category('Lost Rites Chests'); map:setMapScale()
assert(#map.emitted==3,'grouped chest types or actual availability IDs were lost')
local nearby_trials=minimap_get_markers({x=1,y=0,z=1},180,60)
assert(#minimap_options.filter_markers({},nearby_trials)==3)
trial_opened=false
assert(#minimap_get_markers({x=1,y=0,z=1},180,60)==4,
  'renewed trial chest remained permanently cached as acquired')
-- Base-game owners never query/render DLC content, even with saved DLC choices enabled.
ducat_picked = false
dlc_installed = false
queried_gimmicks = {}
show_category('Norgan Ducats'); map:setMapScale()
assert(#map.emitted == 0 and #minimap_get_markers({x=1,y=0,z=1},180,60) == 0
  and next(queried_gimmicks) == nil, 'DLC marker queries reached a non-owner')
drawn_categories = {}
drawn_checkboxes, drawn_text = {}, {}
ducat_diagnostics.error = 'Ducat history fixture warning'
callbacks.ui()
for _, name in ipairs({'Norgan Ducats','Norgan Chests','Norgan Rare Chests','Lost Rites Chests'}) do
  assert(not drawn_categories[name], 'non-owner was offered unavailable DLC controls')
end
assert(not drawn_checkboxes['Hide Norgan Ducats in unexplored areas'],
  'non-owner was offered the DLC fog control')
assert(not drawn_text['Ducat history fixture warning'], 'non-owner saw a stale DLC warning')
ducat_diagnostics.error = nil
show_category("Seeker's Tokens"); map:setMapScale()
assert(#map.emitted > 0 and #minimap_get_markers({x=1,y=0,z=1},180,60) > 0
  and queried_gimmicks[167], 'base-game markers stopped when DLC was absent')
dlc_installed = true
steam_initialized = false
queried_gimmicks = {}
show_category('Norgan Ducats'); map:setMapScale()
assert(#map.emitted == 0 and next(queried_gimmicks) == nil,
  'uninitialized DLC access queried expansion content')
steam_initialized = true
map:setMapScale()
assert(#map.emitted == 1, 'cached base-only map did not recover when DLC access initialized')
dlc_installed = false
map:setMapScale()
assert(#map.emitted == 0, 'cached DLC marker survived loss of DLC access')
-- The selected sealed-room chest stays absent on both maps in either acquisition state.
local inaccessible = '90a2c89d-100b-03f5-285f-510aa4c098ea'
small_chest_fixture.locations[inaccessible] = {x=1,y=0,z=1}
saved_keys, saved_records, gimmicks_by_type = {}, {}, {}
saved_settings.hide_unavailable_chests = false
local generate_manager = managers['app.GenerateManager']
local original_never_generate = generate_manager.isNeverGenerate
for _, acquired in ipairs({false,true}) do
  generate_manager.isNeverGenerate = function(_, id) return id.key == inaccessible and acquired end
  show_category('Chests (S)')
  saved_settings.markers['Chests (S)'].acquired_show = true
  map:setMapScale()
  assert(#map.emitted == 1 and map.emitted[1].UniqId.key == chest_guids[10],
    'inaccessible Vernworth chest still appears on the full map, or a normal chest was lost')
  local markers = minimap_get_markers({x=1,y=0,z=1},180,60)
  assert(#markers == 1 and markers[1].key == chest_guids[10],
    'inaccessible Vernworth chest still appears on the minimap, or a normal chest was lost')
end
generate_manager.isNeverGenerate = original_never_generate
callbacks.save()
assert(saved_settings.quests and saved_settings.quests.enabled==false,
  'stable-line testing discarded separate quest-development preferences')
map:setMapScale()
local stale = map.SelectedIcon
hooks["app.ui040205.onDestroy"].pre({ [2] = map })
map.SelectedIcon = stale
map.TxtName.message = "New map label"
hover_hook.pre({ [2] = map }); hover_hook.post(91)
assert(map.TxtName.message == "New map label", "destroyed map retained stale custom labels")
