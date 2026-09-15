local M = {}

-- gm82_036.pfb.18 assigns GmFlagGetBeginner = GmFlag_Get_Item_1 (122).
-- GmFlag_Item_Disp_0 (18) enables the Finder's Token; it is not a pickup flag.
-- See docs/first-token-flag-audit-2026-09-14.md for the corrected prefab layout.
local FINDER_PICKUP_FLAG = 122
local marker_type = { name = "First Seeker's Token", gimmick_id = 167,
  fog_setting = 'hide_unexplored_tokens', object_icon = 76 }

function M.create(api, locations)
  local self = {}
  local function read_location(show_after_collection)
    local manager = api.get_managed_singleton('app.GimmickManager')
    if not manager then return end
    local proof = manager:get_FirstSeekerProof()
    if not proof then return end
    local empty = proof:isEmpty()
    if empty == true then return end
    if empty ~= false then error('First-token saved ID is unavailable') end
    if show_after_collection ~= true then
      local collected = manager:isGimmickFlag(FINDER_PICKUP_FLAG)
      if collected == true then return end
      if collected ~= false then error("Finder's Token collection state is unavailable") end
    end
    local key = proof:ToString():lower():match('^([%x%-]+)_0$')
    local pos = type(locations) == 'table' and key and locations[key]
    if not pos then error('First-token location is not in the token dataset') end
    return { key = 'first-token:' .. key, token_key = key, id = proof, pos = pos,
      marker_type = marker_type, acquired = false, icon_color = 0xFF0000FF }
  end

  function self:overlay(markers, enabled, icon_type, show_after_collection)
    self.error = nil
    if not enabled then return markers, '' end
    local ok, marker = pcall(read_location, show_after_collection)
    if not ok then
      self.error = 'First-token marker unavailable: ' .. tostring(marker)
      return markers, ''
    end
    if not marker then return markers, '' end
    marker.icon_type = icon_type
    local result = { marker }
    for _, existing in ipairs(markers) do
      if existing.key ~= marker.token_key or existing.marker_type.gimmick_id ~= 167 then
        result[#result + 1] = existing
      end
    end
    return result, marker.key
  end

  function self:reset() self.error = nil end
  return self
end

return M
