local ok, policy = pcall(require, 'raze_MapMarkersAndCollectables.chest_availability')
assert(ok and type(policy.create) == 'function', 'chest progression filtering is missing')
local state = { unmoored=false }
local quests, events = {}, {}
local adapter = { snapshot=function() return state end,
  check_quest=function(_, id, finish) return quests[tostring(id)..':'..tostring(finish)] end,
  check_event=function(_, flag) return events[flag] end,
  reset=function() end }
local chest = { gimmick_id=10, fog_setting='hide_unexplored_chests' }
local function marker(key, acquired, kind) return {key=key, acquired=acquired, marker_type=kind or chest} end
local metadata = {schema_version=1, chests={
  common={gimmick_id=10, variants={{world='any', quests={}}}},
  back={gimmick_id=10, variants={{world='unmoored', quests={}}}},
  original={gimmick_id=10, variants={{world='normal', quests={}}}},
  gated={gimmick_id=10, variants={{world='unmoored', quests={{id=11020,finish=true}}}}},
  either={gimmick_id=10, variants={{world='any', quest_mode='or', quests={{id=1,finish=false},{id=2,finish=true}}}}},
  both={gimmick_id=10, variants={{world='any', quest_mode='and', quests={{id=1,finish=false},{id=2,finish=true}}}}},
  event={gimmick_id=10, variants={{world='any', quests={}, event_flag=32}}},
  unresolved={gimmick_id=10, variants={{world='any', unsupported='Unresolved quest table'}}},
  alternate={gimmick_id=10, variants={{world='any', quests={{id=3,finish=true}}}, {world='unmoored', quests={}}}},
}}
local filter = policy.create(adapter, metadata)
local settings = {hide_unavailable_chests=true, reveal_unmoored_chests=false}
local function visible(key, acquired)
  return #filter:filter({marker(key,acquired)}, settings) == 1
end
assert(visible('common') and visible('original') and not visible('back'))
state.unmoored=true
assert(visible('common') and visible('back') and not visible('original'), 'cached world did not refresh')
state.unmoored=false
settings.reveal_unmoored_chests=true
assert(visible('back'), 'early reveal did not bypass the Unmoored requirement')
quests['11020:true']=false
assert(not visible('gated'), 'early reveal bypassed a separate quest requirement')
quests['11020:true']=true
assert(visible('gated'))
quests['1:false']=nil; quests['2:true']=false
assert(not visible('both') and not visible('either'))
quests['2:true']=true
assert(visible('either') and not visible('both'), 'unknown quest results broke AND/OR semantics')
quests['1:false']=true
assert(visible('both'))
quests['1:false']=false
assert(not visible('both'), 'quest availability remained cached after its state changed')
assert(not visible('event'))
events[32]=true
assert(visible('event'))
events[32]=false
assert(not visible('event'))
assert(#filter:filter({marker('event'),marker('event')},settings)==0 and filter.unknown_count==0,
  'a cached false event result became unknown')
quests['11020:true']=false
assert(#filter:filter({marker('gated'),marker('gated')},settings)==0 and filter.unknown_count==0,
  'a cached false quest result became unknown')
assert(not visible('unresolved') and filter.unknown_count == 1 and filter.error,
  'unresolved availability was treated as obtainable without explanation')
assert(not visible('missing') and filter.unknown_count == 1)
assert(visible('missing',true) and visible('unresolved',true), 'progression filtering lost collected history')
local token = marker('token',false,{gimmick_id=167,fog_setting='hide_unexplored_tokens'})
assert(#filter:filter({token},settings)==1, 'chest progression affected tokens')
settings.reveal_unmoored_chests=false
state.unmoored=true
assert(visible('alternate'), 'a valid alternative placement was blocked by an unknown condition')
state.unmoored=nil
assert(not visible('back') and filter.error, 'unknown world was treated as a known state')
assert(visible('common'), 'an unknown world hid a chest with no world restriction')
local wrong_kind = marker('common',false,{gimmick_id=11,fog_setting='hide_unexplored_chests'})
assert(#filter:filter({wrong_kind},settings)==0, 'metadata for another gimmick type was applied')
settings.hide_unavailable_chests=false
local input = {marker('missing'),marker('gated'),token}
assert(filter:filter(input,settings)==input and filter.error==nil, 'explicit display override still filtered')
filter:reset()
assert(filter.error==nil and filter.unknown_count==0)

metadata.chests.trial={gimmick_id=755,variants={{world='any',unsupported='Trial rules unverified'}}}
local trial=marker('trial',false,{gimmick_id=755,requires_dlc=true,
  fog_setting='hide_unexplored_dlc_chests',availability=true})
local base_locked=marker('unresolved')
for _, case in ipairs({
  {{hide_unavailable_chests=true,hide_unavailable_dlc_chests=true},''},
  {{hide_unavailable_chests=true,hide_unavailable_dlc_chests=false},'trial'},
  {{hide_unavailable_chests=false,hide_unavailable_dlc_chests=true},'unresolved'},
  {{hide_unavailable_chests=false,hide_unavailable_dlc_chests=false},'unresolved,trial'},
}) do
  local shown=filter:filter({base_locked,trial},case[1])
  local keys={};for _,m in ipairs(shown) do keys[#keys+1]=m.key end
  assert(table.concat(keys,',') == case[2], 'base/DLC progression filters hid the wrong group')
  assert((filter.group_errors.base.default ~= nil) == case[1].hide_unavailable_chests
    and (filter.group_errors.dlc.default ~= nil) == case[1].hide_unavailable_dlc_chests,
    'grouped menu diagnostics include a different group or a disabled filter')
end
assert(#filter:filter({base_locked,trial},{hide_unavailable_chests=false}) == 2,
  'legacy shared preview preference did not carry over')
base_locked.acquired,trial.acquired=true,true
assert(#filter:filter({base_locked,trial},{hide_unavailable_chests=true,hide_unavailable_dlc_chests=true}) == 2,
  'split filters suppressed collected history')
