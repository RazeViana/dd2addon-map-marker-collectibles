local nearby = require("raze_MapMarkersAndCollectables.nearby")
local M = {}

function M.create(options)
  local self = { count = 0, owned = {}, candidates = nil, refreshed_at = -math.huge, ui = nil,
    update_count = 0, status = "Waiting for the minimap HUD" }

  function self:invalidate()
    self.candidates = nil
  end

  function self:clear()
    local failed, first_error = {}, nil
    self.count = 0
    for _, saved in ipairs(self.owned) do
      local ok, err = pcall(function()
        local ref = saved.ref
        ref:set_Visible(false)
        ref:set_IconType(saved.icon_type)
        if saved.sequence ~= nil then
          ref.Sprite:set_UVSequenceNo(saved.sequence)
          ref.Sprite:set_UVPatternNo(saved.pattern)
        end
        ref:set_Color(saved.color)
        ref:set_Position(saved.position)
        ref:set_Rotation(saved.rotation)
        ref:set_Scale(saved.scale)
      end)
      if not ok then
        failed[#failed + 1] = saved
        first_error = first_error or err
      end
    end
    self.owned = failed
    self:invalidate()
    if #failed > 0 then error(first_error) end
  end

  function self:before(ui)
    self.update_count = self.update_count + 1
    -- Return borrowed slots before the native update can allocate them to game icons.
    if self.ui == ui then
      local candidates, refreshed_at = self.candidates, self.refreshed_at
      self:clear()
      self.candidates, self.refreshed_at = candidates, refreshed_at
    else
      -- The old HUD may already be destroyed; never dereference its sprite objects.
      self.owned, self.count, self.candidates = {}, 0, nil
      self.ui = ui
    end
  end

  function self:after(ui)
    local settings = options.settings
    self.count = 0
    if not settings.enabled then self.status = "Disabled"; return end
    if not ui.IsInit or ui.PlChara == nil or ui.MapIconList == nil then
      self.status = "Waiting for the player and minimap"; return
    end
    local origin = ui.PlUPos
    local now = options.clock()
    if self.candidates == nil or now - self.refreshed_at >= 0.5 then
      self.candidates = options.get_markers(origin, settings.radius, settings.height) or {}
      self.refreshed_at = now
    end
    local selected = nearby.select(self.candidates, origin, settings.radius, settings.height, settings.max_markers)
    self.status = ("%d nearby collectibles"):format(#selected)
    local pool = ui.MapIconList
    local cursor, count = 0, pool:get_Count()
    local screen_radius = ui.MapOutRange
    if type(screen_radius) ~= "number" or screen_radius <= 0 then return end
    for _, marker in ipairs(selected) do
      local pos = ui:getIconPos(options.vector(marker.pos))
      if pos.x * pos.x + pos.y * pos.y <= screen_radius * screen_radius then
        local slot
        while cursor < count do
          local ref = pool:get_Item(cursor)
          cursor = cursor + 1
          if ref and not ref:get_Visible() then slot = ref; break end
        end
        if slot == nil then break end
        -- Record state before the first write, so a later setter failure can be undone.
        self.owned[#self.owned + 1] = { ref = slot, icon_type = slot:get_IconType(), color = slot:get_Color(),
          position = slot:get_Position(), rotation = slot:get_Rotation(), scale = slot:get_Scale(),
          sequence = slot.Sprite and slot.Sprite:get_UVSequenceNo(),
          pattern = slot.Sprite and slot.Sprite:get_UVPatternNo() }
        slot:set_IconType(options.native_type and options.native_type(marker.icon_type) or marker.icon_type)
        if options.apply_icon then options.apply_icon(ui, slot, marker.icon_type) end
        slot:set_Position(pos)
        -- Only directional markers need camera-relative heading; keep collectible glyphs upright.
        slot:set_Rotation(0)
        local scale = options.get_icon_scale and options.get_icon_scale() or 1
        slot:set_Scale(self.owned[#self.owned].scale * scale)
        options.set_color(slot, marker.icon_color)
        slot:set_Visible(true)
        self.count = self.count + 1
      end
    end
  end

  function self:destroy(ui)
    if self.ui == ui then
      self.owned, self.ui, self.candidates, self.count = {}, nil, nil, 0
    end
  end
  return self
end

return M
