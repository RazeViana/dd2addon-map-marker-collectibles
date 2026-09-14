-- Availability is separate from acquired state, category visibility and map fog.
local M = {}

local function signature(markers)
  local keys = {}
  for _, marker in ipairs(markers) do keys[#keys + 1] = marker.key end
  return table.concat(keys, '|')
end

function M.create(game, metadata)
  local self = { error=nil, unknown_count=0, errors={}, unknown_counts={} }
  local records = type(metadata) == 'table' and metadata.schema_version == 1
    and type(metadata.chests) == 'table' and metadata.chests or {}

  local function evaluate_variant(rule, snapshot, settings, quest_cache, event_cache)
    local unknown = false
    if rule.world ~= 'any' then
      if rule.world == 'unmoored' and settings.reveal_unmoored_chests == true then
        -- Early reveal overrides only this world restriction.
      elseif rule.world == 'unmoored' or rule.world == 'normal' then
        if type(snapshot.unmoored) ~= 'boolean' then unknown = true
        elseif snapshot.unmoored ~= (rule.world == 'unmoored') then return false end
      else unknown = true end
    end
    if rule.unsupported then unknown = true end
    if rule.event_flag then
      local event = event_cache[rule.event_flag]
      if event == nil then
        event = game:check_event(rule.event_flag, snapshot)
        event_cache[rule.event_flag] = event
        if type(event) ~= 'boolean' then event_cache[rule.event_flag] = 'unknown' end
      end
      if event == false then return false end
      if event ~= true then unknown = true end
    end
    local quests = rule.quests or {}
    local mode = rule.quest_mode or 'and'
    local quest_unknown, any_true = false, false
    if mode ~= 'and' and mode ~= 'or' then unknown = true end
    for _, quest in ipairs(quests) do
      local key = tostring(quest.id) .. ':' .. tostring(quest.finish)
      local result = quest_cache[key]
      if result == nil then
        result = game:check_quest(quest.id, quest.finish, snapshot)
        quest_cache[key] = result
        if type(result) ~= 'boolean' then quest_cache[key] = 'unknown' end
      end
      if mode == 'and' and result == false then return false end
      if result == true then any_true = true
      elseif result ~= false then quest_unknown = true end
    end
    if #quests > 0 then
      if mode == 'or' then
        if not any_true and not quest_unknown then return false end
        if not any_true then unknown = true end
      elseif quest_unknown then unknown = true end
    end
    if unknown then return nil end
    return true
  end

  function self:filter(markers, settings, kind)
    kind = kind or 'default'
    self.error, self.unknown_count = nil, 0
    self.errors[kind], self.unknown_counts[kind] = nil, 0
    if settings.hide_unavailable_chests == false then return markers, signature(markers) end
    local visible, snapshot, quest_cache, event_cache = {}, nil, {}, {}
    for _, marker in ipairs(markers) do
      local kind = marker.marker_type
      local show = true
      if kind and kind.fog_setting == 'hide_unexplored_chests' and marker.acquired ~= true then
        show = false
        local record = records[marker.key]
        local unknown = false
        if record and record.gimmick_id == kind.gimmick_id and type(record.variants) == 'table'
            and #record.variants > 0 then
          snapshot = snapshot or game:snapshot()
          for _, rule in ipairs(record.variants) do
            local result = evaluate_variant(rule, snapshot, settings, quest_cache, event_cache)
            if result == true then show = true; break end
            if result == nil then unknown = true end
          end
        else unknown = true end
        if not show and unknown then self.unknown_count = self.unknown_count + 1 end
      end
      if show then visible[#visible + 1] = marker end
    end
    if self.unknown_count > 0 then
      self.error = tostring(self.unknown_count) .. ' unopened chest(s) hidden because availability could not be confirmed.'
      if snapshot and snapshot.error then self.error = self.error .. ' ' .. snapshot.error end
    end
    self.errors[kind], self.unknown_counts[kind] = self.error, self.unknown_count
    return visible, signature(visible)
  end

  function self:reset()
    self.error, self.unknown_count = nil, 0
    self.errors, self.unknown_counts = {}, {}
    game:reset()
  end
  return self
end

return M
