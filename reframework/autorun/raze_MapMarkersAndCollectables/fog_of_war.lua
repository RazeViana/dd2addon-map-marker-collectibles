local M = {}

local function is_local_map(ui, kind)
  if not ui then return false end
  -- Use the native displayed-map mode: local-area IDs alone do not tell us
  -- whether the full map/minimap is currently showing the field or a local map.
  if kind == "fullmap" then return ui.IsFieldMap == false end
  if kind == "minimap" then return ui.IsDispField == false end
  return false
end

local function should_filter(marker, settings, show_local_chests)
  local key = marker.marker_type and marker.marker_type.fog_setting
  return key ~= nil and settings[key] == true
    and not (key == "hide_unexplored_chests" and show_local_chests)
end

function M.create(api, vector, report_error)
  local self = { errors = {} }
  local is_mask_off

  local function set_error(kind, message)
    if message and self.errors[kind] ~= message and report_error then report_error(kind .. ": " .. message) end
    self.errors[kind] = message
  end

  function self:filter(markers, ui, kind, settings)
    local show_local_chests = settings.hide_unexplored_chests == true and is_local_map(ui, kind)
    local has_filtered_markers = false
    for _, marker in ipairs(markers) do
      if should_filter(marker, settings, show_local_chests) then has_filtered_markers = true; break end
    end
    if not has_filtered_markers then set_error(kind, nil); return markers end

    -- Resolve the displayed area's mask each pass; do not retain a mask across
    -- area transitions or save loads. Both map UIs expose LocalAreaNow.
    local ok, mask = pcall(function()
      local manager = api.get_managed_singleton("app.GuiManager")
      if not manager or not ui or ui.LocalAreaNow == nil then error("Fog data is not ready", 0) end
      local info = manager:getMaskInfo(ui.LocalAreaNow)
      if not info or not info.MaskBit or info.MaskBit:get_Length() == 0 then
        error("Fog data is not ready", 0)
      end
      if not is_mask_off then
        local definition = api.find_type_definition("app.GuiManager.MapMaskInfo")
        -- TDB 83 also has an (Int32, Int32) overload. Use the native world-position query.
        is_mask_off = definition and definition:get_method("isMaskOff(via.vec3)")
        if not is_mask_off then error("Fog visibility lookup is unavailable", 0) end
      end
      return info
    end)

    local result, failure = {}, not ok and tostring(mask) or nil
    for _, marker in ipairs(markers) do
      if not should_filter(marker, settings, show_local_chests) then
        result[#result + 1] = marker
      elseif ok then
        -- Unknown visibility stays hidden. Never call a setter or change saved fog.
        local queried, revealed = pcall(function() return is_mask_off(mask, vector(marker.pos)) end)
        if queried and revealed == true then
          result[#result + 1] = marker
        elseif not queried or type(revealed) ~= "boolean" then
          failure = tostring(revealed)
        end
      end
    end
    set_error(kind, failure and ("Markers hidden where fog cannot be read: " .. failure) or nil)
    return result
  end

  return self
end

return M
