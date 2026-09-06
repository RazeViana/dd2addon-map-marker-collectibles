local M = {}

function M.load(api, filename)
  local ok, value = pcall(api.load_file, filename)
  if ok and type(value) == "table" then return value end
end

function M.argb_to_abgr(value)
  return (value & 0xFF00FF00) | ((value & 0x00FF0000) >> 16) | ((value & 0x000000FF) << 16)
end

local function valid_value(key, value, default)
  if type(value) ~= type(default) then return false end
  if type(value) == "number" then
    if value ~= value or value % 1 ~= 0 then return false end
    if key:match("_icon_type$") then return value >= 0 and value <= 75 end
    if key:match("_icon_color$") then return value >= 0 and value <= 0xFFFFFFFF end
  end
  return true
end

function M.normalize(loaded, names, marker_types, generic)
  if type(loaded) ~= "table" then loaded = {} end
  local result = { marker_order = {}, markers = {}, minimap = { enabled = true, radius = 180, height = 60, max_markers = 24 } }
  result.object_icons = loaded.object_icons ~= false
  local size = loaded.icon_size
  result.icon_size = type(size) == "number" and size % 1 == 0 and size >= 25 and size <= 150 and size or 50
  local minimap = type(loaded.minimap) == "table" and loaded.minimap or {}
  if type(minimap.enabled) == "boolean" then result.minimap.enabled = minimap.enabled end
  for key, bounds in pairs({ radius = { 25, 300 }, height = { 10, 150 }, max_markers = { 1, 200 } }) do
    local value = minimap[key]
    if type(value) == "number" and value % 1 == 0 and value >= bounds[1] and value <= bounds[2] then
      result.minimap[key] = value
    end
  end
  local remaining = {}
  for _, name in ipairs(names) do remaining[name] = true end
  if type(loaded.marker_order) == "table" then
    for _, name in ipairs(loaded.marker_order) do
      if remaining[name] then
        result.marker_order[#result.marker_order + 1] = name
        remaining[name] = nil
      end
    end
  end
  for _, name in ipairs(names) do
    if remaining[name] then result.marker_order[#result.marker_order + 1] = name end
    local defaults = marker_types[name].settings_default or generic
    local previous = type(loaded.markers) == "table" and loaded.markers[name] or nil
    if type(previous) ~= "table" then previous = {} end
    local marker = {}
    for key, default in pairs(defaults) do
      marker[key] = default
      if valid_value(key, previous[key], default) then marker[key] = previous[key] end
    end
    marker.unacquired_icon_color_gui = M.argb_to_abgr(marker.unacquired_icon_color)
    marker.acquired_icon_color_gui = M.argb_to_abgr(marker.acquired_icon_color)
    result.markers[name] = marker
  end
  return result
end

return M
