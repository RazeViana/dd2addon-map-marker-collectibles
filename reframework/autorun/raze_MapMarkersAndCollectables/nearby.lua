local M = {}

function M.in_range(pos, origin, radius, height)
  local dx, dz = pos.x - origin.x, pos.z - origin.z
  return dx * dx + dz * dz <= radius * radius and math.abs(pos.y - origin.y) <= height
end

function M.select(markers, origin, radius, height, limit)
  local candidates = {}
  if limit <= 0 then return candidates end
  for _, marker in ipairs(markers) do
    if M.in_range(marker.pos, origin, radius, height) then
      local dx, dz = marker.pos.x - origin.x, marker.pos.z - origin.z
      candidates[#candidates + 1] = { marker = marker, distance = dx * dx + dz * dz }
    end
  end
  table.sort(candidates, function(a, b)
    if a.distance == b.distance then return a.marker.key < b.marker.key end
    return a.distance < b.distance
  end)
  local selected = {}
  for index = 1, math.min(limit, #candidates) do selected[index] = candidates[index].marker end
  return selected
end

return M
