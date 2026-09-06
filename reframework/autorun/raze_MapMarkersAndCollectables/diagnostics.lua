-- Read-only type inspection. This module never installs hooks or changes game objects.
local M = {}
local target_names = {
  "app.ui020301", "app.ui040205", "app.GuiManager",
  "app.GuiManager.MapIconInfo", "app.GUIBase.MapIconRef", "app.GUIBase.MapIconSpriteRef",
  "via.gui.SpriteSet", "via.gui.Sprite", "via.gui.Texture", "via.gui.Panel",
  "System.Collections.Generic.List`1<app.GuiManager.MapIconInfo>"
}

function M.collect(api)
  local report = {
    mod = "Map Markers and Collectables by Raze", version = "1.0",
    captured_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    types = {}, errors = {}, minimap_instance = { present = false }
  }
  local function attempt(label, callback)
    local ok, result = pcall(callback)
    if ok then return result end
    report.errors[#report.errors + 1] = label .. ": " .. tostring(result)
  end
  local inspect
  inspect = function(definition, depth)
    if definition == nil or depth > 12 then return end
    local name = definition:get_full_name()
    if report.types[name] ~= nil then return end
    local record = { name = name, methods = {}, fields = {} }
    report.types[name] = record
    local methods = attempt(name .. " methods", function() return definition:get_methods() end) or {}
    for _, method in ipairs(methods) do
      local entry = attempt(name .. " method", function()
        local parameters = {}
        local names = method:get_param_names() or {}
        for i, param_type in ipairs(method:get_param_types() or {}) do
          parameters[#parameters + 1] = { name = names[i] or tostring(i), type = param_type:get_full_name() }
        end
        local returns = method:get_return_type()
        return { name = method:get_name(), parameters = parameters,
          returns = returns and returns:get_full_name() or "System.Void", static = method:is_static() }
      end)
      if entry then record.methods[#record.methods + 1] = entry end
    end
    local fields = attempt(name .. " fields", function() return definition:get_fields() end) or {}
    for _, field in ipairs(fields) do
      local entry = attempt(name .. " field", function()
        local field_type = field:get_type()
        return { name = field:get_name(), type = field_type and field_type:get_full_name() or "unknown",
          offset = field:get_offset_from_base(), static = field:is_static() }
      end)
      if entry then record.fields[#record.fields + 1] = entry end
    end
    table.sort(record.fields, function(a, b) return a.name < b.name end)
    local parent = attempt(name .. " parent", function() return definition:get_parent_type() end)
    if parent then
      record.parent = parent:get_full_name()
      attempt(record.parent, function() inspect(parent, depth + 1) end)
    end
  end
  for _, name in ipairs(target_names) do
    local definition = attempt(name, function() return api.find_type_definition(name) end)
    if definition == nil then
      report.types[name] = { missing = true }
    else
      attempt(name, function() inspect(definition, 0) end)
    end
  end
  -- Capture whether the actual HUD exists, without invoking any minimap methods.
  attempt("minimap instance", function()
    local manager = api.get_managed_singleton("app.GuiManager")
    local list = manager and manager._GUIList
    if list == nil then return end
    for index = 0, list:get_Count() - 1 do
      local item = list:get_Item(index)
      if item and item:get_type_definition():get_name() == "ui020301" then
        report.minimap_instance = { present = true, type = item:get_type_definition():get_full_name() }
        break
      end
    end
  end)
  return report
end

function M.export(api, filename, report)
  local ok, result = pcall(api.dump_file, filename, report)
  if not ok then return false, tostring(result) end
  if result ~= true then return false, "Could not write " .. filename end
  return true
end

return M
