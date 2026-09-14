-- Native progression reads. Only privately created quest conditions are written;
-- the game managers, quest state and save data are never modified.
local M = {}
local condition_type = "app.GenerateManager.QuestFlagInfos.QuestFlagInfo"

function M.create(api)
  local self = { error = nil }
  local conditions, evaluate, event_check = {}, nil, nil

  local function fail(snapshot, message)
    if type(snapshot) == "table" then
      snapshot.error = snapshot.error or message
      self.error = snapshot.error
    else
      self.error = message
    end
    return nil
  end

  local function release(condition)
    pcall(function() condition:release() end)
  end

  function self:snapshot()
    local snapshot = {}
    self.error = nil
    -- Managers can be replaced while loading saves; do not retain them here.
    local ok, value = pcall(function()
      local manager = assert(api.get_managed_singleton("app.MainFlowManager"),
        "World progression manager is unavailable")
      local unmoored = manager:get_IsBackStage()
      assert(type(unmoored) == "boolean", "World progression state is unavailable")
      return unmoored
    end)
    if ok then snapshot.unmoored = value
    else fail(snapshot, "World progression: " .. tostring(value)) end

    ok, value = pcall(function()
      return assert(api.get_managed_singleton("app.QuestManager"), "Quest manager is unavailable")
    end)
    if ok then snapshot.quest_manager = value
    else fail(snapshot, "Quest progression: " .. tostring(value)) end

    ok, value = pcall(function()
      return assert(api.get_managed_singleton("app.EnvironmentLoadManager"),
        "Environment manager is unavailable")
    end)
    if ok then snapshot.environment_manager = value
    else fail(snapshot, "Event progression: " .. tostring(value)) end
    return snapshot
  end

  function self:check_quest(quest_id, finish_check, snapshot)
    -- Preserve the native Int32 enum and Boolean inputs without coercing bad data.
    if type(quest_id) ~= "number" or quest_id % 1 ~= 0
        or quest_id < -2147483648 or quest_id > 2147483647 or type(finish_check) ~= "boolean" then
      return fail(snapshot, "Quest progression rule has invalid parameters")
    end
    if type(snapshot) ~= "table" or snapshot.quest_manager == nil then
      return fail(snapshot, "Quest manager is unavailable")
    end

    local condition = conditions[quest_id] and conditions[quest_id][finish_check]
    if not condition then
      local retained
      local ok, value = pcall(function()
        if not evaluate then
          local definition = assert(api.find_type_definition(condition_type),
            "Quest condition type is unavailable")
          assert(definition:get_field("_QuestID") and definition:get_field("_IsFinishCheck"),
            "Quest condition fields are unavailable")
          evaluate = assert(definition:get_method("evaluate(app.QuestManager)"),
            "Quest condition evaluation is unavailable")
        end
        -- Default create_instance uses the native parameterless constructor.
        local instance = assert(api.create_instance(condition_type), "Cannot create quest condition")
        retained = instance:add_ref()
        retained:set_field("_QuestID", quest_id)
        retained:set_field("_IsFinishCheck", finish_check)
        return retained
      end)
      if not ok then
        if retained then release(retained) end
        return fail(snapshot, "Quest progression: " .. tostring(value))
      end
      condition = value
      conditions[quest_id] = conditions[quest_id] or {}
      conditions[quest_id][finish_check] = condition
    end

    -- One condition per rule; never cache its result or bind it to a manager.
    local ok, value = pcall(evaluate, condition, snapshot.quest_manager)
    if not ok then return fail(snapshot, "Quest progression: " .. tostring(value)) end
    if type(value) ~= "boolean" then return fail(snapshot, "Quest progression returned an unknown result") end
    return value
  end

  function self:check_event(event_mask, snapshot)
    -- Current rules contain one UInt64 enum flag. Do not infer native semantics
    -- for combined flags or turn the mask into a bit index.
    local mask = type(event_mask) == "number" and math.tointeger(event_mask) or nil
    if not mask or mask <= 0 or (mask & (mask - 1)) ~= 0 then
      return fail(snapshot, "Event progression rule requires a single flag")
    end
    if type(snapshot) ~= "table" or snapshot.environment_manager == nil then
      return fail(snapshot, "Environment manager is unavailable")
    end

    local ok, value = pcall(function()
      if not event_check then
        local definition = assert(api.find_type_definition("app.EnvironmentLoadManager"),
          "Environment manager type is unavailable")
        event_check = assert(definition:get_method("isCheckEventFlag(app.EnvironmentEvent.EventId)"),
          "Environment event evaluation is unavailable")
      end
      return event_check(snapshot.environment_manager, mask)
    end)
    if not ok then return fail(snapshot, "Event progression: " .. tostring(value)) end
    if type(value) ~= "boolean" then return fail(snapshot, "Event progression returned an unknown result") end
    return value
  end

  function self:reset()
    for _, variants in pairs(conditions) do
      for _, condition in pairs(variants) do release(condition) end
    end
    conditions, evaluate, event_check = {}, nil, nil
    self.error = nil
  end

  return self
end

return M
