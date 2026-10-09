--[[
Map Markers and Collectables by Raze

Source and dataset attribution: see THIRD_PARTY_NOTICES.md.
]]

local MOD_NAME = "Map Markers and Collectables by Raze"
local settings_util = require("raze_MapMarkersAndCollectables.settings")
local nearby = require("raze_MapMarkersAndCollectables.nearby")
local object_icon_util = require("raze_MapMarkersAndCollectables.object_icons")
local dlc_collectibles = require("raze_MapMarkersAndCollectables.dlc_collectibles")
local dlc_access = dlc_collectibles.create_access(sdk)
local chest_availability = require("raze_MapMarkersAndCollectables.chest_availability").create(
  require("raze_MapMarkersAndCollectables.chest_game_state").create(sdk),
  dlc_collectibles.availability_catalog(
    settings_util.load(json, "raze_MapMarkersAndCollectables/chest-availability.json"),
    settings_util.load(json, "raze_MapMarkersAndCollectables/dlc-availability.json")))
local fog_visibility = require("raze_MapMarkersAndCollectables.fog_of_war").create(sdk,
  function(pos) return Vector3f.new(pos.x, pos.y, pos.z) end,
  function(message) log.warn(MOD_NAME .. ": " .. message) end)
local object_icon_error
local object_icons = object_icon_util.create(sdk, function(message)
  object_icon_error = message
  log.warn(MOD_NAME .. ": " .. message)
end)
local sprite_pools = require("raze_MapMarkersAndCollectables.sprite_pool").create(sdk)
local capacity_status = {}
local function ensure_icon_capacity(ui, kind, target)
  local count, err = sprite_pools:ensure(ui, kind, target)
  local message = err and (kind .. " capacity: " .. count .. " (expansion unavailable: " .. err .. ")")
    or (kind .. " capacity: " .. count .. " sprite slots")
  if capacity_status[kind] ~= message then
    capacity_status[kind] = message
    if err then log.warn(MOD_NAME .. ": " .. message) else log.info(MOD_NAME .. ": " .. message) end
  end
end

local int_t = sdk.find_type_definition("System.Int32")
local int_t_value_offset = int_t:get_field("m_value"):get_offset_from_base()

local uint_t = sdk.find_type_definition("System.UInt32")
local uint_t_value_offset = uint_t:get_field("m_value"):get_offset_from_base()

local intptr_t = sdk.find_type_definition("System.IntPtr")
local intptr_t_value_offset = intptr_t:get_field("_value"):get_offset_from_base()

local unique_id_t = sdk.find_type_definition("app.UniqueID")

local context_database_t = sdk.find_type_definition("app.ContextDatabase")

local context_database_key_t = sdk.find_type_definition("app.ContextDatabaseKey")

local gather_context_t = sdk.find_type_definition("app.GatherContext")
local gather_context_rt = gather_context_t:get_runtime_type()

local gimmick_context_t = sdk.find_type_definition("app.GimmickContext")
local gimmick_context_rt = gimmick_context_t:get_runtime_type()

local gmitem_context_t = sdk.find_type_definition("app.GmItemContext")
local gmitem_context_rt = gmitem_context_t:get_runtime_type()

local ui040205_t = sdk.find_type_definition("app.ui040205")

local map_icon_info_t = sdk.find_type_definition("app.GuiManager.MapIconInfo")

local map_icon_ref_t = sdk.find_type_definition("app.GUIBase.MapIconRef")

-- 3.2 nuked System.Guid.Parse from the TDB (capcom trims unused stuff, i guess). So we buiild it ourselves.
local guid_t = sdk.find_type_definition("System.Guid")

-- where each byte of the string form lands, first three groups are little-endian
local guid_byte_layout = { 4, 3, 2, 1, 6, 5, 8, 7, 9, 10, 11, 12, 13, 14, 15, 16 }

local guid_parse = function(_, str)
  local hex = (tostring(str):gsub("[^%x]", ""))
  if #hex ~= 32 then
    error("malformed GUID '" .. tostring(str) .. "'")
  end
  local guid = ValueType.new(guid_t)
  for i = 1, 16 do
    local j = guid_byte_layout[i]
    guid:write_byte(i - 1, tonumber(hex:sub(j * 2 - 1, j * 2), 16))
  end
  return guid
end

-- ValueType eats out of range writes without complaining, so if the layout ever changes we'd get zeroed guids and an empty map with no error at all.
do
  local expected = "e26516a9-39b1-4e5d-a814-34aba7c7e023"
  local ok, actual = pcall(function()
    return guid_parse(nil, expected):call("ToString")
  end)
  if ok == false or type(actual) ~= "string" then
    log.warn("Map Markers and Collectables by Raze: could not verify GUID construction, markers may not appear")
  elseif (actual:lower():gsub("[^%x]", "")) ~= (expected:gsub("[^%x]", "")) then
    log.error("Map Markers and Collectables by Raze: System.Guid layout changed, built " .. actual ..
      " from " .. expected)
  end
end

-- A valid item-name ID lets the game position and show its native hover panel.
-- setupIconName below replaces the displayed text only for our own markers.
local hover_name_guid = guid_parse(nil, "e26516a9-39b1-4e5d-a814-34aba7c7e023")

local ui040205_add_map_icon_info_list = ui040205_t:get_method("addMapIconInfoList")
local ui040205_add_map_icon_sprite_info_list = ui040205_t:get_method("addMapIconSpriteInfoList")

local gimmick_manager_get_gimmick_list = sdk.find_type_definition("app.GimmickManager"):get_method(
  "getGimmickList(app.GimmickID)")
local context_database_record_get_context = sdk.find_type_definition("app.ContextDatabaseRecord"):get_method(
  "getContext(System.Type)")

local get_context = function(args, context_type)
  local context_db = args.all.context_db
  local index_creator = context_db.IndexCreator
  local pointer_obj = args.all.pointer_obj
  pointer_obj:write_qword(intptr_t_value_offset, 0)
  if index_creator.UniqueID2Keys:TryGetValue(args.collectible_id, pointer_obj:get_address() + intptr_t_value_offset) == false then
    return nil
  end
  local db_key_pointer = pointer_obj:read_qword(intptr_t_value_offset)
  if db_key_pointer == 0 then
    return nil
  end
  local db_key = sdk.to_managed_object(db_key_pointer)
  if db_key:get_IsValid() == false then
    return nil
  end
  local db_index = db_key.KeyForSystem
  local record_count = context_db.Records:get_Count()
  if db_index >= record_count then
    return nil
  end
  local record = context_db.Records[db_index]:get_Record()
  if record == nil then
    return nil
  end
  return context_database_record_get_context(record, context_type)
end

-- no GetEnumerator here: 3.2 hands back a zeroed struct and MoveNext null derefs, taking the game with it.
local get_gimmick_map = function(gimmick_list)
  local map = {}
  if gimmick_list == nil then return map end
  local count = gimmick_list:get_Count()
  for i = 0, count - 1 do
    local gimmick = gimmick_list:get_Item(i)
    if gimmick ~= nil then
      map[gimmick:get_UniqId():ToString()] = gimmick
    end
  end
  return map
end

local seeker_token_get_state_callbacks =
{
  -- proof
  --[[
  function(args)
    -- If the proof matches the collectible's unique id, then it's been picked up
    if args.all.proof_key ~= nil and args.all.proof_key == args.collectible_key then
      return true
    end
    return nil
  end,
  ]] --
  -- never generate
  function(args)
    -- If the collectible has been flagged to never generate then it's been picked up
    if args.all.generate_manager:isNeverGenerate(args.collectible_id) == true then
      return true
    end
    return nil
  end,
  -- nearby
  function(args)
    local gimmick = args.gimmick_map[args.collectible_id:ToString()]
    if gimmick ~= nil then
      return gimmick:get_IsGetFreeBit()
    end
    return nil
  end,
  -- offline
  function(args)
    local context = get_context(args, gimmick_context_rt)
    if context ~= nil then
      return context:isOnFreeBit(16)
    end
    return nil
  end,
}
local golden_trove_beetle_get_state_callbacks =
{
  -- nearby
  function(args)
    local gimmick = args.gimmick_map[args.collectible_id:ToString()]
    -- A fresh pickup is conclusive, but an unbroken loaded gimmick does not
    -- override the save's depleted GatherContext (including earlier playthroughs).
    if gimmick ~= nil and gimmick:get_IsBroken() == true then
      return true
    end
    return nil
  end,
  -- offline
  function(args)
    local context = get_context(args, gather_context_rt)
    if context ~= nil then
      return context:get_Num() <= 0
    end
    return nil
  end,
}
local chest_get_state_callbacks =
{
  -- nearby
  function(args)
    local gimmick = args.gimmick_map[args.collectible_id:ToString()]
    -- A new opening is conclusive; a closed loaded object must not override
    -- acquisition already recorded in the save before the mod was installed.
    if gimmick ~= nil and gimmick:get_IsOpenedFreeBit() == true then
      return true
    end
    return nil
  end,
  -- offline
  function(args)
    local context = get_context(args, gmitem_context_rt)
    if context ~= nil then
      return context:get_IsPick()
    end
    return nil
  end,
}

local function chest_defaults(color)
  local dimmed = 0xA0000000
  for shift = 0, 16, 8 do dimmed = dimmed | ((((color >> shift) & 0xFF) // 2) << shift) end
  return { unacquired_icon_type = 25, acquired_icon_type = 25,
    unacquired_icon_color = color, acquired_icon_color = dimmed,
    unacquired_show = false, acquired_show = false }
end

local marker_types =
{
  ["Seeker's Tokens"] =
  {
    label = "Seeker's Tokens",
    fog_setting = "hide_unexplored_tokens",
    data = json.load_file("raze_MapMarkersAndCollectables/167.json"),
    gimmick_id = 167,
    get_state_callbacks = seeker_token_get_state_callbacks,
    name = "Seeker's Token",
    object_icon = 76,
    settings_default =
    {
      unacquired_icon_type = 25,
      unacquired_icon_color = 0xFF00CC00,
      acquired_icon_type = 25,
      acquired_icon_color = 0xCC006600,
      unacquired_show = true,
      acquired_show = false,
    },
  },
  ["Golden Trove Beetles"] =
  {
    label = "Golden Trove Beetles",
    fog_setting = "hide_unexplored_beetles",
    data = json.load_file("raze_MapMarkersAndCollectables/161.json"),
    gimmick_id = 161,
    get_state_callbacks = golden_trove_beetle_get_state_callbacks,
    name = "Golden Trove Beetle",
    object_icon = 77,
    settings_default =
    {
      unacquired_icon_type = 25,
      unacquired_icon_color = 0xFF37AFD4,
      acquired_icon_type = 25,
      acquired_icon_color = 0xCC194E5E,
      unacquired_show = true,
      acquired_show = false,
    },
  },
  ["Chests (S)"] =
  {
    label = "Small Chests",
    fog_setting = "hide_unexplored_chests",
    data = json.load_file("raze_MapMarkersAndCollectables/10.json"),
    gimmick_id = 10,
    get_state_callbacks = chest_get_state_callbacks,
    name = "Chest (S)",
    object_icon = 80,
    settings_default = chest_defaults(0xFF6CA4DC),
  },
  ["Chests (M)"] =
  {
    label = "Medium Chests",
    fog_setting = "hide_unexplored_chests",
    data = json.load_file("raze_MapMarkersAndCollectables/11.json"),
    gimmick_id = 11,
    get_state_callbacks = chest_get_state_callbacks,
    name = "Chest (M)",
    object_icon = 78,
    settings_default = chest_defaults(0xFFE0CFBA),
  },
  ["Chests (L)"] =
  {
    label = "Large Chests",
    fog_setting = "hide_unexplored_chests",
    data = json.load_file("raze_MapMarkersAndCollectables/12.json"),
    gimmick_id = 12,
    get_state_callbacks = chest_get_state_callbacks,
    name = "Chest (L)",
    object_icon = 81,
    settings_default = chest_defaults(0xFF6FD6FF),
  },
  -- 13, Sphinx's opulent chest
  -- 465, Chest (L), sealed by Sphinx
  ["Chests (XL)"] =
  {
    label = "Extra Large Chests",
    fog_setting = "hide_unexplored_chests",
    tooltip = "Also known as 'sunken chests'. Progression requirements are checked per location; chest size alone does not determine availability.",
    data = json.load_file("raze_MapMarkersAndCollectables/495.json"),
    gimmick_id = 495,
    get_state_callbacks = chest_get_state_callbacks,
    name = "Chest (XL)",
    object_icon = 82,
    settings_default = chest_defaults(0xFFFFC780),
  },
  -- 653, Sphinx's opulent chest
  ["Special Chests (S)"] =
  {
    label = "Small Special Chests",
    fog_setting = "hide_unexplored_chests",
    data = json.load_file("raze_MapMarkersAndCollectables/692.json"),
    gimmick_id = 692,
    get_state_callbacks = chest_get_state_callbacks,
    name = "Special Chest (S)",
    object_icon = 79,
    settings_default = chest_defaults(0xFFFF9DDB),
  },
  ["Special Chests (M)"] =
  {
    label = "Medium Special Chests",
    fog_setting = "hide_unexplored_chests",
    data = json.load_file("raze_MapMarkersAndCollectables/693.json"),
    gimmick_id = 693,
    get_state_callbacks = chest_get_state_callbacks,
    name = "Special Chest (M)",
    object_icon = 79,
    settings_default = chest_defaults(0xFFFF9DDB),
  },
  ["Special Chests (L)"] =
  {
    label = "Large Special Chests",
    fog_setting = "hide_unexplored_chests",
    data = json.load_file("raze_MapMarkersAndCollectables/694.json"),
    gimmick_id = 694,
    get_state_callbacks = chest_get_state_callbacks,
    name = "Special Chest (L)",
    object_icon = 79,
    settings_default = chest_defaults(0xFFFF9DDB),
  },
}
-- also used as default ordering
local marker_type_names =
{
  "Seeker's Tokens",
  "Golden Trove Beetles",
  "Chests (S)",
  "Chests (M)",
  "Chests (L)",
  "Chests (XL)",
  "Special Chests (S)",
  "Special Chests (M)",
  "Special Chests (L)",
}

local settings_filename = "raze_MapMarkersAndCollectables_settings.json"
local ducat_callbacks, ducat_diagnostics = dlc_collectibles.coin_callbacks(sdk, get_context, gimmick_context_rt)
dlc_collectibles.register(marker_types, marker_type_names, function(path) return settings_util.load(json, path) end,
  chest_get_state_callbacks, ducat_callbacks, chest_defaults)
local loaded_settings = settings_util.load(json, settings_filename)

local settings_default_generic =
{
  unacquired_icon_type = 25,
  unacquired_icon_color = 0xFFD4AF37,
  acquired_icon_type = 25,
  acquired_icon_color = 0xCC5F4E19,
  unacquired_show = false,
  acquired_show = false,
}

local argb_to_abgr = settings_util.argb_to_abgr
local settings = settings_util.normalize(loaded_settings, marker_type_names, marker_types, settings_default_generic)
-- Retain preferences when temporarily testing this stable-line patch over the quest build.
if type(loaded_settings)=='table' and type(loaded_settings.quests)=='table' then
  settings.quests=loaded_settings.quests
end
local token_type = marker_types["Seeker's Tokens"]
local first_token = require("raze_MapMarkersAndCollectables.first_token").create(sdk,
  type(token_type.data) == "table" and token_type.data.locations)
local function with_first_token(markers)
  return first_token:overlay(markers, settings.show_first_seeker_token,
    object_icon_util.resolve_type(token_type, settings.markers["Seeker's Tokens"], "unacquired", settings.object_icons),
    settings.show_first_token_after_collection)
end
local settings_message = nil

local save_settings = function()
  local ok, saved = pcall(json.dump_file, settings_filename, settings)
  if not ok or saved ~= true then
    settings_message = "Could not save settings. See re2_framework_log.txt."
    log.error(MOD_NAME .. ": could not save settings: " .. tostring(saved))
    return false
  end
  settings_message = "Settings saved."
  return true
end

re.on_config_save(
  function()
    save_settings()
  end
)

local show_exception = false
local show_warning = false

--local map_icon_new_array_size = 1024

local cache_acquired = {}
local cache_collectibles = nil
local cache_markers = nil
local availability_signature, next_availability_refresh = nil, 0
local first_token_signature
local minimap_renderer = nil
local minimap_error = nil

local want_update = false
local dlc_available
local function refresh_dlc_access()
  local available = dlc_access:available()
  if available ~= dlc_available then
    dlc_available = available
    cache_collectibles, cache_markers = nil, nil
    if minimap_renderer then minimap_renderer:invalidate() end
    want_update = true
  end
  return available
end

local marker_label = "Open the map!"
local update_marker_count = function(game_count, script_count, remaining_count, total_count, pool_label)
  marker_label = ("Icons: %d game, %d custom, %d unused (%d maximum, %s pool)"):format(game_count, script_count,
    remaining_count, total_count, pool_label)
end

local ui_map = nil
local hover_labels = {}

local draw_marker_type_settings = function(setting_prefix, marker_type, marker_settings)
  local icon_type_key = setting_prefix .. "_icon_type"
  local icon_color_key = setting_prefix .. "_icon_color"
  local icon_color_gui_key = setting_prefix .. "_icon_color_gui"
  local icon_style_key = setting_prefix .. "_icon_style"
  local dirty = nil
  local labels, selected = {}, 1
  for i, style in ipairs(object_icon_util.styles) do
    labels[i] = style.label
    if style.key == marker_settings[icon_style_key] then selected = i end
  end
  local changed, choice = imgui.combo("Artwork", selected, labels)
  if changed and object_icon_util.styles[choice] then
    marker_settings[icon_style_key] = object_icon_util.styles[choice].key
    dirty = true
  end
  if marker_settings[icon_style_key] == "native"
      or (marker_settings[icon_style_key] == "default" and not settings.object_icons) then
    local changed, new_value = imgui.drag_int("Icon Type", marker_settings[icon_type_key], 1, 0, 75)
    if changed then
      marker_settings[icon_type_key] = new_value
      dirty = true
    end
  end
  if imgui.tree_node("Icon Color") then
    local changed, new_value = imgui.color_picker_argb("", marker_settings[icon_color_gui_key], 0x30000)
    if changed then
      marker_settings[icon_color_key] = argb_to_abgr(new_value)
      marker_settings[icon_color_gui_key] = new_value
      dirty = true
    end
    imgui.tree_pop()
  end
  if imgui.button("Reset") then
    local settings_default
    if marker_type.settings_default == nil then
      settings_default = settings_default_generic
    else
      settings_default = marker_type.settings_default
    end
    marker_settings[icon_style_key] = settings_default[icon_style_key] or "default"
    marker_settings[icon_type_key] = settings_default[icon_type_key]
    marker_settings[icon_color_key] = settings_default[icon_color_key]
    marker_settings[icon_color_gui_key] = argb_to_abgr(settings_default[icon_color_key])
    dirty = true
  end
  return dirty
end

-- settings!
re.on_draw_ui(function()
  local markers_dirty = false
  local collectibles_dirty = false
  local reorder_index = 0
  if imgui.tree_node(MOD_NAME) then
    local has_dlc = refresh_dlc_access()
    imgui.text("v1.5 - Map and minimap markers")
    local symbols_changed, use_objects = imgui.checkbox("Use object icons", settings.object_icons)
    if symbols_changed then settings.object_icons = use_objects; markers_dirty = true end
    if imgui.is_item_hovered() then
      imgui.set_tooltip("Default artwork for categories using 'Follow global icon style'. Category overrides are set below.")
    end
    local size_changed, icon_size = imgui.slider_int("Icon size (%)", settings.icon_size, 25, 150)
    if size_changed then settings.icon_size = icon_size; markers_dirty = true end
    if object_icon_error then imgui.text(object_icon_error) end
    if settings_message ~= nil then imgui.text(settings_message) end
    local first_changed, show_first = imgui.checkbox("Show first Seeker's Token", settings.show_first_seeker_token)
    if first_changed then settings.show_first_seeker_token = show_first; markers_dirty = true end
    if imgui.is_item_hovered() then
      imgui.set_tooltip("Mark your first collected Seeker's Token in red. By default, it disappears after Finder's Token collection; enable the option below to keep it visible. Independent of Acquired/Unacquired visibility; follows token artwork, fog and map settings.")
    end
    if settings.show_first_seeker_token then
      local history_changed, show_history = imgui.checkbox("Show after Finder's Token collection", settings.show_first_token_after_collection)
      if history_changed then settings.show_first_token_after_collection = show_history; markers_dirty = true end
      if imgui.is_item_hovered() then
        imgui.set_tooltip("Keep the red first-token location visible even after collecting or handing in the Finder's Token. Uses the current playthrough's saved location; still follows token fog and map settings.")
      end
    end
    if settings.show_first_seeker_token and first_token.error then imgui.text(first_token.error) end
    local progression_changed, hide_unavailable = imgui.checkbox("Hide unobtainable chests", settings.hide_unavailable_chests)
    if progression_changed then settings.hide_unavailable_chests = hide_unavailable; markers_dirty = true end
    if imgui.is_item_hovered() then
      imgui.set_tooltip("Hide unopened chests blocked by their world, quest or environment conditions. Unresolved availability stays hidden. Collected-chest history follows each category's Acquired setting.")
    end
    local unmoored_changed, reveal_unmoored = imgui.checkbox("Reveal Unmoored-only chests early", settings.reveal_unmoored_chests)
    if unmoored_changed then settings.reveal_unmoored_chests = reveal_unmoored; markers_dirty = true end
    if imgui.is_item_hovered() then
      imgui.set_tooltip("Reveal recorded Unmoored-only placements before entering that world. Other quest and environment conditions still apply. Turn off Hide unobtainable chests to display every location.")
    end
    if settings.hide_unavailable_chests then
      for _, kind in ipairs({"fullmap", "minimap"}) do
        if settings[kind].enabled and chest_availability.errors[kind] then
          imgui.text(chest_availability.errors[kind])
        end
      end
    end
    local fullmap_changed, show_fullmap = imgui.checkbox("Show on full map", settings.fullmap.enabled)
    if has_dlc and ducat_diagnostics.error then imgui.text(ducat_diagnostics.error) end
    if fullmap_changed then
      settings.fullmap.enabled = show_fullmap
      markers_dirty = true
    end
    local changed, enabled = imgui.checkbox("Show on minimap", settings.minimap.enabled)
    if changed then
      settings.minimap.enabled = enabled
      minimap_error = nil
      markers_dirty = true
    end
    local fog_enabled = false
    for _, control in ipairs({
      {"hide_unexplored_chests", "Hide chests in unexplored areas", "regular and special chests"},
      {"hide_unexplored_beetles", "Hide beetles in unexplored areas", "Golden Trove Beetles"},
      {"hide_unexplored_tokens", "Hide Seeker's Tokens in unexplored areas", "Seeker's Tokens"},
      {"hide_unexplored_ducats", "Hide Norgan Ducats in unexplored areas", "Norgan Ducats"}
    }) do
      if control[1] ~= "hide_unexplored_ducats" or has_dlc then
        local fog_changed, hide_unexplored = imgui.checkbox(control[2], settings[control[1]])
        if fog_changed then settings[control[1]] = hide_unexplored; markers_dirty = true end
        fog_enabled = fog_enabled or settings[control[1]]
        if imgui.is_item_hovered() then
          imgui.begin_tooltip()
          local tooltip = "Show " .. control[3] .. " only where the map's fog of war has cleared. Applies to both maps."
          if control[1] == "hide_unexplored_chests" then
            tooltip = tooltip .. " Chests ignore fog on cave and city local maps; outdoor maps follow this option again. Category and Acquired/Unacquired choices still apply."
          end
          imgui.set_tooltip(tooltip)
          imgui.end_tooltip()
        end
      end
    end
    if fog_enabled then
      if settings.fullmap.enabled and fog_visibility.errors.fullmap then imgui.text(fog_visibility.errors.fullmap) end
      if settings.minimap.enabled and fog_visibility.errors.minimap then imgui.text(fog_visibility.errors.minimap) end
    end
    if minimap_renderer ~= nil then
      imgui.text(("Minimap: %d custom icons - %s"):format(minimap_renderer.count, minimap_renderer.status))
    end
    if minimap_error ~= nil then imgui.text_colored(minimap_error, 0xFF0000FF) end
    if capacity_status.fullmap then imgui.text(capacity_status.fullmap) end
    if capacity_status.minimap then imgui.text(capacity_status.minimap) end
    if imgui.tree_node("Minimap settings") then
      local height_changed, show_height = imgui.checkbox("Show height indicators", settings.minimap.height_indicators)
      if height_changed then settings.minimap.height_indicators = show_height; markers_dirty = true end
      for _, field in ipairs({
        { "radius", "Search radius (world units)", 25, 300 },
        { "height", "Maximum height difference", 10, 150 },
        { "height_tolerance", "Height tolerance (world units)", 0, 30 },
        { "max_markers", "Maximum custom icons", 1, 200 }
      }) do
        local edited, value = imgui.drag_int(field[2], settings.minimap[field[1]], 1, field[3], field[4])
        if edited then settings.minimap[field[1]] = value; markers_dirty = true end
      end
      imgui.text("Uses the category visibility and colors below. Nearest items are shown first.")
      imgui.text("Height arrows point up or down. No arrow is shown within the height tolerance.")
      imgui.tree_pop()
    end
    if marker_label ~= nil then
      imgui.text(marker_label)
    end
    if show_exception then
      imgui.text_colored(
        "An error occurred while getting collectible status. See re2_framework_log.txt and report this to Raze.",
        0xFF0000FF)
    end
    if show_warning then
      imgui.text_colored(
        "Reached the icon limit! Icons limited."
        --.. " You can try increasing icon array size under Advanced."
        ,
        0xFF0000FF)
    end
    for key_index, marker_type_name in ipairs(settings.marker_order) do
      local marker_type = marker_types[marker_type_name]
      if not marker_type.requires_dlc or has_dlc then
        local marker_settings = settings.markers[marker_type_name]
        imgui.push_id(marker_type_name)
        if imgui.arrow_button("#Move Up", 2) then
          reorder_index = -key_index
        end
        imgui.same_line()
        if imgui.arrow_button("#Move Down", 3) then
          reorder_index = key_index
        end
        imgui.same_line()
        imgui.push_id("Show Unacquired")
        imgui.push_style_color(18, marker_settings.unacquired_icon_color)
        local changed, new_value = imgui.checkbox("", marker_settings.unacquired_show)
        imgui.pop_style_color()
        if imgui.is_item_hovered() then
          imgui.begin_tooltip()
          if marker_settings.unacquired_show then
            imgui.set_tooltip("Show unacquired " .. marker_type.label)
          else
            imgui.set_tooltip("Hide unacquired " .. marker_type.label)
          end
          imgui.end_tooltip()
        end
        if changed then
          if cache_collectibles ~= nil and cache_collectibles[marker_type_name] == nil then
            collectibles_dirty = true
          else
            markers_dirty = true
          end
          marker_settings.unacquired_show = new_value
        end
        imgui.pop_id()
        imgui.same_line()
        imgui.push_id("Show Acquired")
        imgui.push_style_color(18, marker_settings.acquired_icon_color)
        local changed, new_value = imgui.checkbox("", marker_settings.acquired_show)
        imgui.pop_style_color()
        if imgui.is_item_hovered() then
          imgui.begin_tooltip()
          if marker_settings.acquired_show then
            imgui.set_tooltip("Show acquired " .. marker_type.label)
          else
            imgui.set_tooltip("Hide acquired " .. marker_type.label)
          end
          imgui.end_tooltip()
        end
        if changed then
          if cache_collectibles ~= nil and cache_collectibles[marker_type_name] == nil then
            collectibles_dirty = true
          else
            markers_dirty = true
          end
          marker_settings.acquired_show = new_value
        end
        imgui.pop_id()
        imgui.same_line()
        local tree_node
        if type(marker_type.data) ~= "table" or type(marker_type.data.locations) ~= "table" then
          imgui.push_style_color(0, 0xFF0000FF)
          tree_node = imgui.tree_node(marker_type.label .. " (data file missing!)")
          imgui.pop_style_color()
        else
          tree_node = imgui.tree_node(marker_type.label)
        end
        if marker_type.tooltip ~= nil and imgui.is_item_hovered() then
          imgui.begin_tooltip()
          imgui.set_tooltip(marker_type.tooltip)
          imgui.end_tooltip()
        end
        if tree_node then
          if imgui.tree_node("Unacquired Settings") then
            local changed = draw_marker_type_settings("unacquired", marker_type, marker_settings)
            if changed == true then
              markers_dirty = true
            elseif changed == false then
              collectibles_dirty = true
            end
            imgui.tree_pop()
          end
          if imgui.tree_node("Acquired Settings") then
            local changed = draw_marker_type_settings("acquired", marker_type, marker_settings)
            if changed == true then
              markers_dirty = true
            elseif changed == false then
              collectibles_dirty = true
            end
            imgui.tree_pop()
          end
          imgui.tree_pop()
        end
        imgui.pop_id()
      end
    end
    --[[
    if imgui.tree_node("Advanced Settings") then
      imgui.text("Changing Icon Array Size requires closing the map and opening it again")
      local changed, new_value = imgui.drag_int(
        "Icon Array Size = " .. tostring(map_icon_new_array_size),
        settings.map_icon_new_array_size_multiplier,
        1,
        1, 16)
      if changed then
        settings.map_icon_new_array_size_multiplier = new_value
        map_icon_new_array_size = new_value * 512
      end
      imgui.tree_pop()
    end
    ]] --
    if imgui.button("Save Settings") then
      save_settings()
    end
    imgui.tree_pop()
  end
  if reorder_index ~= 0 then
    local new_index
    if reorder_index < 0 then
      reorder_index = -reorder_index
      new_index = reorder_index - 1
    else
      new_index = reorder_index + 1
    end
    if new_index >= 1 and new_index <= #settings.marker_order then
      local reorder_key = settings.marker_order[reorder_index]
      table.remove(settings.marker_order, reorder_index)
      table.insert(settings.marker_order, new_index, reorder_key)
    end
    markers_dirty = true
  end
  if collectibles_dirty then
    cache_collectibles = nil
    markers_dirty = true
  end
  if markers_dirty then
    cache_markers = nil
    if minimap_renderer then minimap_renderer:invalidate() end
    if ui_map ~= nil and ui_map:get_Valid() then
      want_update = true
    end
  end
end)

local get_collectibles = function(all_args, include_position)
  local collectibles = {}
  for _, marker_type_name in ipairs(settings.marker_order) do
    repeat
      local marker_type = marker_types[marker_type_name]
      if marker_type.requires_dlc and all_args.dlc_available ~= true then break end
      if type(marker_type.data) ~= "table" or type(marker_type.data.locations) ~= "table" then
        break
      end
      local marker_settings = settings.markers[marker_type_name]
      if marker_settings.unacquired_show == false and marker_settings.acquired_show == false then
        break
      end

      local gimmick_list, gimmick_map
      if marker_type.get_gimmick_list ~= nil then
        gimmick_list = marker_type.get_gimmick_list(all_args)
        gimmick_map = get_gimmick_map(gimmick_list)
      else
        gimmick_map = {}
        for _, gimmick_id in ipairs(marker_type.gimmick_ids or {marker_type.gimmick_id}) do
          gimmick_list = gimmick_manager_get_gimmick_list(all_args.gimmick_manager, gimmick_id)
          for key, value in pairs(get_gimmick_map(gimmick_list)) do gimmick_map[key]=value end
        end
      end

      local marker_collectibles = {}
      for collectible_key, collectible_pos in pairs(marker_type.data.locations) do
        repeat
          if include_position and not include_position(collectible_pos) then break end
          local collectible_guid = guid_parse(nil, collectible_key)
          local collectible_id = unique_id_t:create_instance():add_ref()
          collectible_id:setup(collectible_guid, 0)

          local check_args = {}
          check_args.all = all_args
          check_args.gimmick_map = gimmick_map
          check_args.collectible_key = collectible_key
          check_args.collectible_id = collectible_id

          -- cache acquired = true lookups so we don't have to needlessly check again
          local acquired = cache_acquired[collectible_key]
          if all_args.live_refresh or marker_type.live_acquired then acquired = nil end
          if acquired ~= true then
            for _, get_state_callback in ipairs(marker_type.get_state_callbacks) do
              acquired = get_state_callback(check_args)
              if acquired ~= nil then
                break
              end
            end
            cache_acquired[collectible_key] = acquired == true and true or nil
          end

          table.insert(marker_collectibles,
            {
              key = collectible_key,
              id = collectible_id,
              pos = collectible_pos,
              acquired = acquired,
              gimmick_id = marker_type.data.gimmick_ids and marker_type.data.gimmick_ids[collectible_key]
                or marker_type.gimmick_id,
              marker_type = marker_type,
              marker_settings = marker_settings,
            })
        until true
      end
      collectibles[marker_type_name] = marker_collectibles
    until true
  end
  return collectibles
end

local get_markers = function(collectibles)
  local markers = {}
  for _, marker_type_name in ipairs(settings.marker_order) do
    repeat
      local marker_collectibles = collectibles[marker_type_name]
      if marker_collectibles == nil then
        break
      end
      for _, collectible in ipairs(marker_collectibles) do
        repeat
          local marker_settings = collectible.marker_settings
          local icon_color
          if collectible.acquired == true then
            if marker_settings.acquired_show == false then
              break
            end
            icon_color = marker_settings.acquired_icon_color
          else
            if marker_settings.unacquired_show == false then
              break
            end
            icon_color = marker_settings.unacquired_icon_color
          end

          table.insert(markers,
            {
              key = collectible.key,
              id = collectible.id,
              pos = collectible.pos,
              marker_type = collectible.marker_type,
              gimmick_id = collectible.gimmick_id,
              acquired = collectible.acquired == true,
              icon_type = object_icon_util.resolve_type(collectible.marker_type, marker_settings,
                collectible.acquired == true and "acquired" or "unacquired", settings.object_icons),
              icon_color = icon_color,
            })
        until true
      end
    until true
  end
  return markers
end

-- Native panel and sprite pools; the sprite pool is expanded before adding custom icons.
local icon_pools =
{
  { label = "panel",  array = "MapIcon",       ref = "Icon",       add = ui040205_add_map_icon_info_list },
  { label = "sprite", array = "MapIconSprite", ref = "IconSprite", add = ui040205_add_map_icon_sprite_info_list },
}

-- original used the MapIconInfoList count as the slot cursor, which was fine until 3.2 put the game's own markers on sprites.
-- 130 infos vs 32 panels, so everything looked over the limit forever.
local get_icon_pool = function(this)
  local used = {}
  local native_refs = {}
  for i = 1, #icon_pools do
    used[i] = 0
  end
  local infos = this.MapIconInfoList
  for i = 0, infos:get_Count() - 1 do
    local info = infos:get_Item(i)
    if info ~= nil then
      for j = 1, #icon_pools do
        if info[icon_pools[j].ref] ~= nil then
          used[j] = used[j] + 1
          native_refs[#native_refs + 1] = info[icon_pools[j].ref]
        end
      end
    end
  end
  local pool, pool_used, pool_limit
  for i = 1, #icon_pools do
    local array = this[icon_pools[i].array]
    local limit = 0
    if array ~= nil then
      limit = array:get_Length()
    end
    if pool == nil or limit - used[i] > pool_limit - pool_used then
      pool, pool_used, pool_limit = icon_pools[i], used[i], limit
    end
  end
  return pool, pool_used, pool_limit, native_refs
end

local fullmap_styles, fullmap_native_refs = {}, {}
local function restore_fullmap_styles()
  for _, saved in ipairs(fullmap_styles) do
    saved.ref:set_Scale(saved.scale)
    saved.ref:set_Prio(saved.priority)
  end
  fullmap_styles, fullmap_native_refs = {}, {}
end
local function apply_fullmap_styles(this)
  if #fullmap_styles == 0 then return end
  -- Slot scales can belong to an earlier zoom, especially when slots are reused.
  -- Use the map's current icon scale for every custom marker; snapshots are only for restoration.
  local scale = this.IconScale * settings.icon_size / 100
  -- Adding icons last does not override native drawing priority (e.g. Dragon's Gaze).
  -- Only native refs captured before our additions determine the foreground priority,
  -- so reapplying after native updates cannot increase it on every frame.
  local priority = 0
  for _, ref in ipairs(fullmap_native_refs) do priority = math.max(priority, ref:get_Prio()) end
  for _, saved in ipairs(fullmap_styles) do
    saved.ref:set_Scale(scale)
    saved.ref:set_Prio(priority + 1)
  end
end

local add_markers = function(this)
  if this == nil then
    return
  end
  hover_labels = {}

  if not settings.fullmap.enabled then
    show_exception, show_warning = false, false
    marker_label = "Full map: Disabled"
    return
  end

  local generate_manager = sdk.get_managed_singleton("app.GenerateManager")
  local gimmick_manager = sdk.get_managed_singleton("app.GimmickManager")
  local context_dbms = sdk.get_managed_singleton("app.ContextDBMS")
  if generate_manager == nil or gimmick_manager == nil or context_dbms == nil then return end
  local context_db = context_dbms:get_CurrentDB()
  if context_db == nil or context_db.Lock == nil or context_db.IndexCreator == nil then return end
  local has_dlc = refresh_dlc_access()

  -- scratchpad for ref pointer arguments
  local pointer_obj = intptr_t:create_instance():add_ref()

  -- collecting useful stuff to be passed into other functions
  local all_args = {}
  all_args.generate_manager = generate_manager
  all_args.gimmick_manager = gimmick_manager
  all_args.context_dbms = context_dbms
  all_args.context_db = context_db
  all_args.pointer_obj = pointer_obj
  all_args.dlc_available = has_dlc

  -- get all markers that should be possibly shown on the map

  -- collect all collectible state if needed
  if cache_collectibles == nil then
    local lock = context_db.Lock
    lock:readLock()
    -- since the db gets locked, need to make sure an error here doesn't prevent the db from being unlocked
    local result, err = pcall(get_collectibles, all_args)
    lock:readUnlock()
    local collectibles
    if not result then
      show_exception = true
      log.error(MOD_NAME .. ": " .. tostring(err))
      return
    else
      show_exception = false
      collectibles = err
    end
    cache_collectibles = collectibles
    cache_markers = nil
  end

  -- collect all markers if needed
  local markers
  if cache_markers ~= nil then
    markers = cache_markers
  else
    markers = get_markers(cache_collectibles)
    cache_markers = markers
  end

  -- The first-token marker follows current saved state even while ordinary markers are cached.
  markers, first_token_signature = with_first_token(markers)
  -- Progression applies after the marker cache, independently of fog and category settings.
  markers, availability_signature = chest_availability:filter(markers, settings, "fullmap")
  -- Display range describes the selected world/local map, not its zoom level.
  -- Check it before querying fog so local masks receive only relevant positions.
  local in_range = {}
  for _, marker in ipairs(markers) do
    if this:isInDispRange(Vector3f.new(marker.pos.x, marker.pos.y, marker.pos.z)) then
      in_range[#in_range + 1] = marker
    end
  end
  -- Filter after the marker cache so exploration and map-area changes are read afresh.
  markers = fog_visibility:filter(in_range, this, "fullmap", settings)
  ensure_icon_capacity(this, "fullmap", 2048)
  local icon_pool, icon_count, icon_limit, native_refs = get_icon_pool(this)
  fullmap_native_refs = native_refs

  -- passed in as ref to the pool's add function
  local icon_index = icon_count
  local icon_index_obj = int_t:create_instance():add_ref()
  icon_index_obj:write_dword(int_t_value_offset, icon_index)

  local icon_color_obj = uint_t:create_instance():add_ref()

  show_warning = false
  local marker_count = 0
  for _, marker in ipairs(markers) do
    repeat
      -- addMapIconInfoList increments icon_index for each icon added
      if icon_index >= icon_limit then
        show_warning = true
        break
      end

      local vec3 = Vector3f.new(marker.pos.x, marker.pos.y, marker.pos.z)

      local marker_type  = marker.marker_type

      --log.debug("adding marker for " .. collectible.id:ToString())

      -- Create a custom icon...
      local info         = map_icon_info_t:create_instance():add_ref()
      info.IsEnable      = true
      info.IsNavi        = false
      info.IconId        = 0
      info.SortNo        = 0
      info.UniqId        = marker.id
      info.IconType      = object_icon_util.native_type(marker.icon_type)
      info.Timing        = 0
      info.Pos           = vec3
      info.Area          = -1 -- app.AIAreaDefinition.None
      info.LocalArea     = 0  -- app.AILocalAreaDefinition.None
      info.IsDispAllArea = true

      -- ...and add it to the map
      local ui_icon      = icon_pool.add(
        this,
        info,
        0,
        icon_index_obj:get_address() + int_t_value_offset,
        -1,
        hover_name_guid, false)
      if ui_icon == nil then
        log.debug("failed to add icon for " .. marker.id:ToString())
        break
      end

      -- setupIconName applies our label through TxtName:set_Message. Keep it in Lua
      -- so a native MapIconInfo.Name assignment cannot abort marker creation.
      hover_labels[ui_icon:get_address()] = marker_type.name

      icon_index = icon_index_obj:read_dword(int_t_value_offset)

      -- no ref means no color, icon still shows though
      local map_icon_ref = ui_icon[icon_pool.ref]
      if map_icon_ref ~= nil then
        fullmap_styles[#fullmap_styles + 1] = {
          ref = map_icon_ref, scale = map_icon_ref:get_Scale(), priority = map_icon_ref:get_Prio() }
        object_icons:apply(this, "fullmap", map_icon_ref, marker.icon_type)
        icon_color_obj:write_dword(uint_t_value_offset, marker.icon_color)
        map_icon_ref:set_Color(icon_color_obj:get_address() + uint_t_value_offset)
      end

      marker_count = marker_count + 1
    until true
  end
  update_marker_count(icon_count, marker_count, icon_limit - marker_count - icon_count, icon_limit,
    icon_pool.label)
end

-- hook clearAllContextsImpl to clear caches as needed
-- clearAllContextsImpl is called by clearAllContexts and restoreFromSaveData
sdk.hook(
  context_database_t:get_method("clearAllContextsImpl"),
  function(args)
    cache_acquired = {}
    show_exception = false
    show_warning = false
    cache_collectibles = nil
    cache_markers = nil
    chest_availability:reset()
    first_token:reset()
    first_token_signature = nil
    availability_signature, next_availability_refresh = nil, 0
    if minimap_renderer then minimap_renderer:invalidate() end
  end,
  function(retval)
    return retval
  end
)

-- The full map is recreated whenever it is opened.
sdk.hook(
  ui040205_t:get_method(".ctor"),
  function(args)
    ui_map = sdk.to_managed_object(args[2])
  end,
  function(retval)
    local this = ui_map
    cache_collectibles = nil
    cache_markers = nil
    return retval
  end
)

-- hook onDestroy to reset ui_map since the object is recreated whenever the map is opened
sdk.hook(
  ui040205_t:get_method("onDestroy"),
  function(args)
    sprite_pools:destroy(sdk.to_managed_object(args[2]), "fullmap")
    object_icons:destroy(sdk.to_managed_object(args[2]), "fullmap")
    fullmap_styles, fullmap_native_refs = {}, {}
    hover_labels = {}
    ui_map = nil
  end,
  function(retval)
    return retval
  end
)

local hover_map
sdk.hook(ui040205_t:get_method("setupIconName"),
  function(args) hover_map = sdk.to_managed_object(args[2]) end,
  function(retval)
    local selected = hover_map and hover_map.SelectedIcon
    local label = selected and hover_labels[selected:get_address()]
    if label and hover_map.TxtName then hover_map.TxtName:set_Message(label) end
    return retval
  end)

-- hook update so that setupMapIcon is called from within the UI thread (assumed) to avoid crashing calling it directly
sdk.hook(
  ui040205_t:get_method("update"),
  function(args)
    if settings.fullmap.enabled then refresh_dlc_access() end
    if settings.fullmap.enabled and cache_markers ~= nil
        and os.clock() >= next_availability_refresh then
      next_availability_refresh = os.clock() + 1
      local candidates, first_signature = with_first_token(cache_markers)
      local _, signature = chest_availability:filter(candidates, settings, "fullmap")
      if first_token_signature ~= nil and first_signature ~= first_token_signature then
        -- Re-read ordinary acquisition too, so a freshly collected first token cannot return green.
        cache_collectibles, cache_markers = nil, nil
        want_update = true
      end
      if availability_signature ~= nil and signature ~= availability_signature then want_update = true end
    end
    if want_update == false then
      return
    end
    local this = sdk.to_managed_object(args[2])
    this:setMapScale(this.NowScale, true)
    want_update = false
  end,
  function(retval)
    return retval
  end
)

-- Native updates can rewrite scale and priority; reapply only to our own refs.
local scale_map
sdk.hook(ui040205_t:get_method("updateMapIcon"),
  function(args) scale_map = sdk.to_managed_object(args[2]) end,
  function(retval)
    if scale_map == ui_map then apply_fullmap_styles(scale_map) end
    return retval
  end)

sdk.hook(
  ui040205_t:get_method("setupMapIcon"),
  function(args)
    ui_map = sdk.to_managed_object(args[2])
    -- Restore borrowed state before native setup can reuse these slots for game icons.
    restore_fullmap_styles()
    object_icons:clear(ui_map, "fullmap")
  end,
  function(retval)
    local this = ui_map
    if this ~= nil then
      add_markers(this)
      this:updateMapIcon()
      apply_fullmap_styles(this)
    end
    return retval
  end
)

-- Borrow only unused native sprite slots, within the minimap's own update hook.
-- Collection state is refreshed for nearby locations twice per second.
local function get_minimap_markers(origin, radius, height)
  local generate_manager = sdk.get_managed_singleton("app.GenerateManager")
  local gimmick_manager = sdk.get_managed_singleton("app.GimmickManager")
  local context_dbms = sdk.get_managed_singleton("app.ContextDBMS")
  if not generate_manager or not gimmick_manager or not context_dbms then return {} end
  local db = context_dbms:get_CurrentDB()
  if not db or not db.Lock or not db.IndexCreator then return {} end
  local args = { generate_manager = generate_manager, gimmick_manager = gimmick_manager,
    context_dbms = context_dbms, context_db = db, pointer_obj = intptr_t:create_instance():add_ref(),
    live_refresh = true, dlc_available = refresh_dlc_access() }
  db.Lock:readLock()
  local ok, result = pcall(get_collectibles, args, function(pos)
    return nearby.in_range(pos, origin, radius, height)
  end)
  db.Lock:readUnlock()
  if not ok then error(result) end
  return get_markers(result)
end

local ui020301_t = sdk.find_type_definition("app.ui020301")
if ui020301_t and thread and thread.get_hook_storage then
  local update_icon = ui020301_t:get_method("updateIcon")
  if update_icon then
    local color = uint_t:create_instance():add_ref()
    minimap_renderer = require("raze_MapMarkersAndCollectables.minimap").create({
      settings = settings.minimap, clock = os.clock, get_markers = get_minimap_markers,
      filter_markers = function(ui, markers)
        markers = with_first_token(markers)
        markers = chest_availability:filter(markers, settings, "minimap")
        return fog_visibility:filter(markers, ui, "minimap", settings)
      end,
      native_type = object_icon_util.native_type,
      get_icon_scale = function() return settings.icon_size / 100 end,
      apply_icon = function(ui, ref, icon_type) object_icons:apply(ui, "minimap", ref, icon_type) end,
      apply_height = function(ui, ref, direction) return object_icons:apply_height(ui, ref, direction) end,
      vector = function(pos) return Vector3f.new(pos.x, pos.y, pos.z) end,
      set_color = function(ref, value)
        color:write_dword(uint_t_value_offset, value)
        ref:set_Color(color:get_address() + uint_t_value_offset)
      end
    })
    local function report_error(err)
      local message = "Minimap paused: " .. tostring(err)
      if minimap_error ~= message then log.error(MOD_NAME .. ": " .. message) end
      minimap_error = message
    end
    sdk.hook(update_icon,
      function(args)
        local this = sdk.to_managed_object(args[2])
        thread.get_hook_storage().raze_minimap = this
        local ok, err = pcall(function()
          minimap_renderer:before(this)
          if this.IsInit then ensure_icon_capacity(this, "minimap", settings.minimap.height_indicators and 512 or 256) end
        end)
        if not ok then report_error(err) end
      end,
      function(retval)
        local this = thread.get_hook_storage().raze_minimap
        if this and minimap_error == nil then
          local ok, err = pcall(minimap_renderer.after, minimap_renderer, this)
          if not ok then report_error(err) end
        end
        return retval
      end)
    local destroy = ui020301_t:get_method("onDestroy")
    if destroy then
      sdk.hook(destroy, function(args)
        local this = sdk.to_managed_object(args[2])
        minimap_renderer:destroy(this)
        sprite_pools:destroy(this, "minimap")
        object_icons:destroy(this, "minimap")
      end, function(retval) return retval end)
    end
  else
    minimap_error = "Minimap updateIcon is unavailable in this game version."
  end
else
  minimap_error = "Minimap requires app.ui020301 and REFramework's thread API."
end

if re.on_script_reset then
  re.on_script_reset(function()
    chest_availability:reset()
    first_token:reset()
    if minimap_renderer then pcall(minimap_renderer.clear, minimap_renderer) end
    pcall(restore_fullmap_styles)
    pcall(object_icons.restore, object_icons)
  end)
end
