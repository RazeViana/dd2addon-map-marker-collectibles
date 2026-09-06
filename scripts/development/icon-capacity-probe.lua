-- Temporary development probe. Creates one detached sprite; never attaches it to the HUD.
local report = { maps = {}, errors = {}, fullmap_history = {} }
local filename = "raze_MapMarkersAndCollectables_capacity_probe.json"
local function attempt(name, callback)
  local ok, result = pcall(callback)
  if ok then return result end
  report.errors[#report.errors + 1] = name .. ": " .. tostring(result)
end
local function save()
  json.dump_file(filename, report)
end
local function inspect(ui, name)
  if name == "minimap" and report.maps[name] then return end
  local is_mini = name == "minimap"
  local pool = is_mini and ui.MapIconList or ui.MapIconSprite
  if not pool then return end
  local count = is_mini and pool:get_Count() or pool:get_Length()
  if count == 0 then return end
  local first = is_mini and pool:get_Item(0) or pool[0]
  if not first or not first.Sprite then return end
  local item = { sprite_count = count }
  report.maps[name] = item
  attempt(name .. " pools", function()
    if not is_mini then
      item.panel_count = ui.MapIcon:get_Length()
      item.info_count = ui.MapIconInfoList:get_Count()
      item.visible, item.visible_above_original_limit = 0, 0
      for index = 0, count - 1 do
        local ref = pool[index]
        if ref and ref:get_Visible() then
          item.visible = item.visible + 1
          if index >= 1024 then item.visible_above_original_limit = item.visible_above_original_limit + 1 end
        end
      end
      report.fullmap_history[#report.fullmap_history + 1] = {
        info_count=item.info_count, visible=item.visible,
        visible_above_original_limit=item.visible_above_original_limit, capacity=count
      }
    end
    local sprite_set = ui.MapIconSpriteSet
    local bg_set = is_mini and ui.MapIconBGSpriteSet or ui.MapIconBgSpriteSet
    item.sprite_set = sprite_set ~= nil
    item.bg_set = bg_set ~= nil
    item.parent_name = sprite_set:get_Parent():get_Name()
    item.is_menu = first.IsMenu
    item.pos_rate = first.PosRate
    item.tex_scale = first.TexScale
    item.parent_scale = first.ParentScale
    item.sprite_sequence = first.Sprite:get_UVSequenceNo()
    item.sprite_pattern = first.Sprite:get_UVPatternNo()
    item.has_background = first.TexBG ~= nil
  end)
  save()
end
for name, typename in pairs({minimap="app.ui020301", fullmap="app.ui040205"}) do
  local method = sdk.find_type_definition(typename):get_method(name == "minimap" and "updateIcon" or "setupMapIcon")
  sdk.hook(method, function(args)
    thread.get_hook_storage().raze_capacity_ui = sdk.to_managed_object(args[2])
  end, function(retval)
    attempt(name, function() inspect(thread.get_hook_storage().raze_capacity_ui, name) end)
    return retval
  end)
end
local done = false
re.on_frame(function()
  if done then return end
  done = true
  attempt("detached sprite", function()
    local sprite = sdk.create_instance("via.gui.Sprite")
    report.sprite_created = sprite ~= nil
    if not sprite then return end
    sprite:add_ref()
    sprite:set_Visible(false)
    report.sprite_visible = sprite:get_Visible()
    report.sprite_sequence = sprite:get_UVSequenceNo()
  end)
  attempt("empty ref array", function()
    local array = sdk.create_managed_array("app.GUIBase.MapIconSpriteRef", 2)
    report.array_created = array ~= nil
    if array then array:add_ref(); report.array_length = array:get_Length() end
  end)
  save()
end)
