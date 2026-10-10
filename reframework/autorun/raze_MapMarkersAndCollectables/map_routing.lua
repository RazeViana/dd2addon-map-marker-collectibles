-- Trial worlds overlap other world coordinates; their native map IDs disambiguate them.
local M = {}

local function displayed_area(ui, kind)
  if not ui then return nil end
  if kind == 'fullmap' then
    if ui.IsFieldMap == true then return 0 end
    return ui.DetailArea
  end
  if ui.IsDispField == true then return 0 end
  return ui.MapAreaNow
end

function M.matches(marker, ui, kind)
  local area = displayed_area(ui, kind)
  if marker.map_area then return area == marker.map_area end
  -- Never place outdoor/base-game coordinates into a trial with a shared origin.
  return not (type(area) == 'number' and area >= 6001 and area <= 6012)
end

function M.in_range(marker, ui)
  if not M.matches(marker, ui, 'fullmap') then return false end
  if marker.map_area then
    local bounds = marker.map_bounds
    if not bounds then return false end
    -- These bounds come from the trial's MapTexListData, rather than a field-world range.
    return marker.pos.x >= bounds[1] and marker.pos.x <= bounds[3]
      and marker.pos.z >= bounds[2] and marker.pos.z <= bounds[4]
  end
  return ui:isInDispRange(Vector3f.new(marker.pos.x, marker.pos.y, marker.pos.z))
end

function M.filter(markers, ui, kind)
  local result = {}
  for _, marker in ipairs(markers) do
    if M.matches(marker, ui, kind) then result[#result+1] = marker end
  end
  return result
end

return M
