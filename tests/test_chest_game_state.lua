local module = require("raze_MapMarkersAndCollectables.chest_game_state")
local condition_type = "app.GenerateManager.QuestFlagInfos.QuestFlagInfo"

local function fixture()
  local state = { world = false, created = {}, evaluations = {}, events = {}, released = 0 }
  state.flow = { get_IsBackStage = function()
    if state.world_throw then error("world unavailable") end
    return state.world
  end }
  state.quest = { answers = { [11020] = { [true] = true, [false] = false } } }
  state.environment = { answers = { [8] = false, [32] = true, [64] = false } }
  local environment_definition = { get_method = function(_, name)
    assert(name == "isCheckEventFlag(app.EnvironmentEvent.EventId)", "wrong environment evaluation signature")
    if state.event_method_missing then return nil end
    return function(manager, event_mask)
      state.events[#state.events + 1] = { manager = manager, mask = event_mask }
      if state.event_throw then error("event unavailable") end
      if state.event_invalid then return 1 end
      return manager.answers[event_mask]
    end
  end }
  local definition = {
    get_field = function(_, name)
      assert(name == "_QuestID" or name == "_IsFinishCheck", "unexpected native field")
      if state.missing_field == name then return nil end
      return {}
    end,
    get_method = function(_, name)
      assert(name == "evaluate(app.QuestManager)", "wrong quest evaluation signature")
      if state.missing_method then return nil end
      return function(condition, manager)
        assert(condition.retained and not condition.released, "evaluating an unowned condition")
        assert(type(condition._QuestID) == "number" and condition._QuestID % 1 == 0,
          "quest enum was not an integer")
        assert(type(condition._IsFinishCheck) == "boolean", "finish-check flag was coerced")
        state.evaluations[#state.evaluations + 1] = manager
        if state.evaluate_throw then error("evaluation unavailable") end
        if state.evaluate_invalid then return 1 end
        return manager.answers[condition._QuestID][condition._IsFinishCheck]
      end
    end
  }
  local api = {
    get_managed_singleton = function(name)
      if state.singleton_throw then error("singleton unavailable") end
      if name == "app.MainFlowManager" then return state.flow end
      if name == "app.EnvironmentLoadManager" then return state.environment end
      assert(name == "app.QuestManager", "unexpected manager access")
      return state.quest
    end,
    find_type_definition = function(name)
      if name == "app.EnvironmentLoadManager" then
        if state.event_type_missing then return nil end
        return environment_definition
      end
      assert(name == condition_type, "unexpected condition type")
      if state.missing_type then return nil end
      return definition
    end,
    create_instance = function(name, simplify)
      assert(name == condition_type and not simplify, "condition constructor was bypassed")
      if state.create_nil then return nil end
      local object = {}
      function object:add_ref() self.retained = true; return self end
      function object:release()
        assert(self.retained and not self.released, "condition released twice")
        self.released = true
        state.released = state.released + 1
      end
      function object:set_field(field, value)
        if state.set_throw then error("field write unavailable") end
        assert(field == "_QuestID" or field == "_IsFinishCheck", "unexpected condition mutation")
        self[field] = value
      end
      state.created[#state.created + 1] = object
      return object
    end
  }
  return module.create(api), state
end

-- Each pass reads the displayed world's current state and current quest manager.
local adapter, state = fixture()
local first = adapter:snapshot()
assert(first.unmoored == false and first.quest_manager == state.quest and first.error == nil)
assert(adapter:check_quest(11020, true, first) == true)
assert(adapter:check_quest(11020, false, first) == false)
state.world = true
state.quest = { answers = { [11020] = { [true] = false, [false] = true } } }
local second = adapter:snapshot()
assert(second.unmoored == true and second.quest_manager == state.quest and second.error == nil)
assert(adapter:check_quest(11020, true, second) == false, "previous quest manager was reused")
assert(adapter:check_quest(11020, false, second) == true, "finish-check alternatives shared a condition")
assert(state.evaluations[#state.evaluations] == second.quest_manager)
assert(first.unmoored == false and first.quest_manager ~= second.quest_manager, "snapshot was mutated")
-- Cache condition definitions, not results or managers. Repeated frames allocate
-- only one native instance per distinct quest/finish-check pair.
for i = 1, 100 do
  state.world = i % 2 == 0
  state.quest.answers[11020][true] = i % 2 == 0
  local snapshot = adapter:snapshot()
  assert(snapshot.unmoored == (i % 2 == 0))
  assert(adapter:check_quest(11020, true, snapshot) == (i % 2 == 0))
end
assert(#state.created == 2, "quest conditions grew with frames or manager replacements")
adapter:reset()
assert(state.released == 2 and adapter.error == nil, "reset retained native instances or errors")
adapter:reset()
assert(state.released == 2, "repeated reset released conditions twice")
assert(adapter:check_quest(11020, true, adapter:snapshot()) == true and #state.created == 3,
  "reset reused a released quest condition")

-- Missing world information remains unknown while independent quest checks work.
for _, failure in ipairs({ "missing_manager", "missing_getter", "throw", "nonboolean" }) do
  local current, env = fixture()
  if failure == "missing_manager" then env.flow = nil
  elseif failure == "missing_getter" then env.flow = {}
  elseif failure == "throw" then env.world_throw = true
  else env.world = 0 end
  local snapshot = current:snapshot()
  assert(snapshot.unmoored == nil and type(snapshot.error) == "string", failure)
  assert(current:check_quest(11020, true, snapshot) == true, "world failure disabled quest reads")
  assert(snapshot.error and current.error, "quest success erased another progression error")
end

-- Loading transitions can remove either manager. A later pass must recover.
adapter, state = fixture()
local original_quest, original_flow = state.quest, state.flow
state.quest, state.flow = nil, nil
local absent = adapter:snapshot()
assert(absent.quest_manager == nil and absent.unmoored == nil and absent.error)
assert(adapter:check_quest(11020, true, absent) == nil and #state.created == 0)
state.quest, state.flow = original_quest, original_flow
local recovered = adapter:snapshot()
assert(recovered.error == nil and adapter.error == nil)
assert(adapter:check_quest(11020, true, recovered) == true)
state.singleton_throw = true
local unavailable = adapter:snapshot()
assert(unavailable.quest_manager == nil and unavailable.unmoored == nil and unavailable.error)

-- Unsupported or failing native APIs never become a false or true quest result.
for _, failure in ipairs({ "missing_type", "missing_method", "missing_field", "create_nil", "set_throw",
    "evaluate_throw", "evaluate_invalid" }) do
  local current, env = fixture()
  env[failure] = failure == "missing_field" and "_QuestID" or true
  local snapshot = current:snapshot()
  assert(current:check_quest(11020, true, snapshot) == nil, failure .. " invented quest availability")
  assert(type(snapshot.error) == "string" and current.error == snapshot.error,
    failure .. " was not exposed to the caller")
  if failure == "set_throw" then
    assert(env.released == #env.created, "partly configured native condition leaked")
  end
  env[failure] = nil
  local retry = current:snapshot()
  assert(retry.error == nil and current:check_quest(11020, true, retry) == true,
    failure .. " prevented recovery")
  current:reset()
  assert(current.error == nil and env.released == #env.created, failure .. " leaked an owned condition")
end

-- Reject malformed metadata before coercion or allocation of native conditions.
adapter, state = fixture()
for _, args in ipairs({ {"11020", true}, {1.5, true}, {0/0, true}, {2147483648, true},
    {-2147483649, true}, {11020, 1}, {11020, "false"} }) do
  local snapshot = adapter:snapshot()
  assert(adapter:check_quest(args[1], args[2], snapshot) == nil and snapshot.error)
end
assert(#state.created == 0, "invalid rules allocated native quest conditions")
assert(adapter:check_quest(11020, true, nil) == nil and adapter.error, "missing snapshot was not handled")
adapter:reset()
assert(adapter.error == nil)

-- Event IDs are masks, not bit indexes. Native evaluation receives the exact
-- single flag and the manager from the current pass; results are never cached.
adapter, state = fixture()
local event_snapshot = adapter:snapshot()
assert(event_snapshot.environment_manager == state.environment, "environment manager was not captured")
assert(adapter:check_event(8, event_snapshot) == false)
assert(adapter:check_event(32, event_snapshot) == true)
assert(adapter:check_event(64, event_snapshot) == false)
assert(state.events[1].mask == 8 and state.events[2].mask == 32 and state.events[3].mask == 64,
  "event masks were converted to indexes or combined")
state.environment = { answers = { [8] = true, [32] = false, [64] = true } }
event_snapshot = adapter:snapshot()
assert(adapter:check_event(8, event_snapshot) == true and adapter:check_event(32, event_snapshot) == false)
assert(state.events[#state.events].manager == state.environment, "old environment manager was reused")
state.environment.answers[8] = false
assert(adapter:check_event(8, adapter:snapshot()) == false, "native event result was cached")
assert(#state.created == 0, "event query allocated or mutated a quest condition")

for _, failure in ipairs({ "event_type_missing", "event_method_missing", "event_throw", "event_invalid" }) do
  local current, env = fixture()
  env[failure] = true
  local snapshot = current:snapshot()
  assert(current:check_event(8, snapshot) == nil and snapshot.error and current.error, failure)
  env[failure] = nil
  assert(current:check_event(32, current:snapshot()) == true, failure .. " prevented event recovery")
  current:reset()
  assert(current.error == nil)
end
adapter, state = fixture()
state.environment = nil
local missing_event = adapter:snapshot()
assert(missing_event.environment_manager == nil and missing_event.error)
assert(adapter:check_event(8, missing_event) == nil)
assert(adapter:check_quest(11020, true, missing_event) == true,
  "missing environment manager disabled independent quest evaluation")
state.environment = { answers = { [8] = true } }
assert(adapter:check_event(8, adapter:snapshot()) == true and adapter.error == nil)
local event_calls = #state.events
for _, mask in ipairs({0, -1, 3, 40, "8", 1.5, math.huge}) do
  local snapshot = adapter:snapshot()
  assert(adapter:check_event(mask, snapshot) == nil and snapshot.error,
    "unsupported combined or invalid event mask was evaluated")
end
assert(#state.events == event_calls, "invalid event masks reached the native API")
assert(adapter:check_event(8, nil) == nil and adapter.error)
