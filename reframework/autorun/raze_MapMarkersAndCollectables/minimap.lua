local nearby = require("raze_MapMarkersAndCollectables.nearby")
local M = {}

function M.create(options)
  local self = { count = 0, height_count = 0, owned = {}, candidates = nil, refreshed_at = -math.huge, ui = nil,
    update_count = 0, status = "Waiting for the minimap HUD" }

  function self:invalidate()
    self.candidates = nil
  end

  function self:clear()
    local failed, first_error = {}, nil
    self.count, self.height_count = 0, 0
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
      self.owned, self.count, self.height_count, self.candidates = {}, 0, 0, nil
      self.ui = ui
    end
  end

  function self:after(ui)
    local settings = options.settings
    self.count, self.height_count = 0, 0
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
    local function borrow_slot()
      while cursor < count do
        local ref = pool:get_Item(cursor)
        cursor = cursor + 1
        if ref and not ref:get_Visible() then
          -- Record state before the first write so partial failures can be undone.
          local saved = { ref = ref, icon_type = ref:get_IconType(), color = ref:get_Color(),
            position = ref:get_Position(), rotation = ref:get_Rotation(), scale = ref:get_Scale(),
            sequence = ref.Sprite and ref.Sprite:get_UVSequenceNo(),
            pattern = ref.Sprite and ref.Sprite:get_UVPatternNo() }
          self.owned[#self.owned + 1] = saved
          return ref, saved
        end
      end
    end
    local indicators = {}
    for _, marker in ipairs(selected) do
      local pos = ui:getIconPos(options.vector(marker.pos))
      if pos.x * pos.x + pos.y * pos.y <= screen_radius * screen_radius then
        local slot, saved = borrow_slot()
        if slot == nil then break end
        slot:set_IconType(options.native_type and options.native_type(marker.icon_type) or marker.icon_type)
        if options.apply_icon then options.apply_icon(ui, slot, marker.icon_type) end
        slot:set_Position(pos)
        -- Only directional markers need camera-relative heading; keep collectible glyphs upright.
        slot:set_Rotation(0)
        local scale = options.get_icon_scale and options.get_icon_scale() or 1
        slot:set_Scale(saved.scale * scale)
        options.set_color(slot, marker.icon_color)
        slot:set_Visible(true)
        self.count = self.count + 1
        if settings.height_indicators and options.apply_height and slot.Sprite then
          local difference = marker.pos.y - origin.y
          if math.abs(difference) > (settings.height_tolerance or 3) then
            indicators[#indicators + 1] = { x = pos.x, y = pos.y, z = pos.z,
              direction = difference > 0 and 1 or -1, color = marker.icon_color,
              scale = saved.scale * scale, height = math.abs(slot.Sprite:get_Size().h) }
          end
        end
      end
    end
    -- Collectible markers get priority; arrows use only the slots still available.
    local arrow_slot
    for _, indicator in ipairs(indicators) do
      local slot = arrow_slot or borrow_slot()
      if not slot then break end
      -- Keep an unshown slot available if this arrow is clipped or has no artwork.
      arrow_slot = slot
      slot:set_IconType(31)
      slot:set_Scale(indicator.scale * 0.6)
      if options.apply_height(ui, slot, indicator.direction) then
        local offset = (indicator.height + math.abs(slot.Sprite:get_Size().h)) / 2 + 2
        local pos = options.vector({ x = indicator.x, y = indicator.y - indicator.direction * offset, z = indicator.z })
        if pos.x * pos.x + pos.y * pos.y <= screen_radius * screen_radius then
          slot:set_Position(pos)
          slot:set_Rotation(0)
          options.set_color(slot, indicator.color)
          slot:set_Visible(true)
          if slot.TexBG then slot.TexBG:set_Visible(false) end
          self.height_count = self.height_count + 1
          arrow_slot = nil
        end
      end
    end
  end

  function self:destroy(ui)
    if self.ui == ui then
      self.owned, self.ui, self.candidates, self.count, self.height_count = {}, nil, nil, 0, 0
    end
  end
  return self
end

return M
