-- Development-only readout. Run with REFramework's Run script button.
local report = { types = {}, live = {}, errors = {} }
local function attempt(name, callback)
  local ok, result = pcall(callback)
  if ok then return result end
  report.errors[#report.errors + 1] = name .. ": " .. tostring(result)
end
for _, name in ipairs({ "app.GUIBase.MapIconSpriteRef", "via.gui.SpriteSet", "via.gui.Sprite",
  "System.Collections.Generic.List`1<app.GuiManager.MapIconInfo>", "app.MapIconType" }) do
  attempt(name, function()
    local t = sdk.find_type_definition(name)
    if not t then report.types[name] = { missing = true }; return end
    local item = { fields = {}, methods = {} }
    report.types[name] = item
    for _, field in ipairs(t:get_fields()) do
      local f = { name = field:get_name(), type = field:get_type():get_full_name() }
      if field:is_static() and name == "app.MapIconType" then f.value = field:get_data(nil) end
      item.fields[#item.fields + 1] = f
    end
    for _, method in ipairs(t:get_methods()) do
      local params = {}
      for _, param in ipairs(method:get_param_types()) do params[#params + 1] = param:get_full_name() end
      item.methods[#item.methods + 1] = { name = method:get_name(), parameters = params,
        returns = method:get_return_type():get_full_name() }
    end
  end)
end
attempt("live", function()
  local manager = sdk.get_managed_singleton("app.GuiManager")
  local list = manager._GUIList
  for i = 0, list:get_Count() - 1 do
    local item = list:get_Item(i)
    if item and item:get_type_definition():get_name() == "ui020301" then
      for _, field in ipairs({"IsInit", "NowScale", "MapZoom", "ZoomNow", "MapOutRange", "MaskDispRange",
        "DefaultMaskSize", "LocalAreaNow", "MapAreaNow", "FieldScale", "DetailScale"}) do
        report.live[field] = item[field]
      end
      local pos = item.PlUPos
      report.live.position = { x = pos.x, y = pos.y, z = pos.z }
      local projected = item:getIconPos(pos)
      report.live.projected_player = { x = projected.x, y = projected.y, z = projected.z }
      for _, field in ipairs({"MapIconList", "MarkerIconList", "AreaIconList"}) do
        local collection = item[field]
        if collection then
          report.live[field] = { count = collection:get_Count(), type = collection:get_type_definition():get_full_name() }
          local first = collection:get_Count() > 0 and collection:get_Item(0)
          if first then
            report.live[field].first_type = first:get_type_definition():get_full_name()
            report.live[field].first_visible = first:get_Visible()
          end
        end
      end
    end
  end
  local icons = manager:getMiniMapIconList()
  report.live.game_icons = { type = icons:get_type_definition():get_full_name(), count = icons:get_Count(), sample = {} }
  for index = 0, math.min(icons:get_Count() - 1, 4) do
    local icon = icons:get_Item(index)
    report.live.game_icons.sample[#report.live.game_icons.sample + 1] = {
      enabled = icon.IsEnable, type = icon.IconType, area = icon.Area, local_area = icon.LocalArea,
      all_areas = icon.IsDispAllArea, timing = icon.Timing, id = icon.IconId,
      pos = { x = icon.Pos.x, y = icon.Pos.y, z = icon.Pos.z }
    }
  end
end)
json.dump_file("raze_MapMarkersAndCollectables_probe.json", report)
log.info("Map Markers and Collectables by Raze: minimap probe saved")
