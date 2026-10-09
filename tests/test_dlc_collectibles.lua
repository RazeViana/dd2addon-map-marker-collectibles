local dlc = require('raze_MapMarkersAndCollectables.dlc_collectibles')
local reads, mask = {}, 64
local field = { is_static=function() return true end, get_data=function() return mask end }
local api = { find_type_definition=function(name)
  assert(name == 'app.Gm83_169')
  return {get_field=function(_, name) assert(name == 'FreeBitGet'); return field end}
end }
local context = {isOnFreeBit=function(_, bit) reads[#reads+1]=bit; return bit == 64 end}
local callbacks, diagnostics = dlc.coin_callbacks(api, function() return context end, 'context')
local args = {all={generate_manager={isNeverGenerate=function() return false end}},
  collectible_id={ToString=function() return 'coin' end}, gimmick_map={}}
assert(callbacks[1](args) == nil, 'absence of never-generate proof implies acquired')
assert(callbacks[2](args) == nil, 'unloaded coin was treated as locally observed')
assert(callbacks[3](args) == true and reads[1] == 64, 'pickup history used an assumed token bit')
assert(diagnostics.error == nil)
mask=0
callbacks, diagnostics = dlc.coin_callbacks(api, function() return context end, 'context')
assert(callbacks[3](args) == nil and diagnostics.error, 'invalid static mask was used to read saves')
mask=16
assert(callbacks[3](args) == false and reads[#reads] == 16,
  'a temporarily uninitialized static field did not recover')
assert(diagnostics.error == nil)
args.gimmick_map.coin={get_IsGetFreeBit=function() return true end}
assert(callbacks[2](args) == true)
args.gimmick_map.coin.get_IsGetFreeBit=function() return false end
assert(callbacks[2](args) == nil, 'a nearby uncollected coin must not override saved acquisition')
local types, names = {existing={}}, {'existing'}
local guid1='00000001-0000-0000-0000-000000000000'
local guid2='00000002-0000-0000-0000-000000000000'
local files = {['755.json']={locations={[guid1]={x=1,y=2,z=3}}},
  ['757.json']={locations={[guid2]={x=4,y=5,z=6}}}}
local generic = {unacquired_icon_type=25,acquired_icon_type=25,
  unacquired_icon_color=0xFFFFFFFF,acquired_icon_color=0xAAAAAAAA,
  unacquired_show=false,acquired_show=false}
dlc.register(types, names, function(path) return files[path:match('[^/]+$')] end,
  {'chest'}, callbacks, function(color) return {unacquired_icon_type=25,acquired_icon_type=25,
    unacquired_icon_color=color,acquired_icon_color=color,
    unacquired_show=false,acquired_show=false} end)
assert(#names == 5 and names[1] == 'existing', 'DLC categories changed existing ordering')
assert(types['Norgan Ducats'].object_icon == 86 and types['Norgan Ducats'].get_state_callbacks == callbacks)
assert(types['Norgan Chests'].object_icon == 84 and types['Norgan Rare Chests'].object_icon == 85)
local trial=types['Lost Rites Chests']
assert(trial.data.locations[guid1].x == 1 and trial.data.locations[guid2].x == 4)
assert(trial.data.gimmick_ids[guid1] == 755 and trial.data.gimmick_ids[guid2] == 757,
  'grouped trial chests lost their actual native type')
assert(trial.live_acquired == true, 'repeatable trial chests cached acquisition indefinitely')
local settings_util = require('raze_MapMarkersAndCollectables.settings')
local artwork = require('raze_MapMarkersAndCollectables.object_icons')
local fresh = settings_util.normalize({object_icons=false}, names, types, generic)
for name, icon in pairs({['Norgan Ducats']=86,['Norgan Chests']=84,
    ['Norgan Rare Chests']=85,['Lost Rites Chests']=85}) do
  assert(types[name].requires_dlc == true, 'expansion category lacks its DLC guard')
  assert(fresh.markers[name].unacquired_show == true and fresh.markers[name].acquired_show == false,
    'new DLC markers must default to showing uncollected items')
  for _, state in ipairs({'unacquired','acquired'}) do
    assert(artwork.resolve_type(types[name],fresh.markers[name],state,false) == icon,
      'new DLC artwork must be the category default even with legacy global symbols')
  end
end
local chosen = settings_util.normalize({markers={['Norgan Chests']={
  unacquired_show=false,unacquired_icon_style='native',acquired_icon_style='small',
  unacquired_icon_color=0xFF123456}}}, names, types, generic)
assert(chosen.markers['Norgan Chests'].unacquired_show == false
  and chosen.markers['Norgan Chests'].unacquired_icon_style == 'native'
  and chosen.markers['Norgan Chests'].acquired_icon_style == 'small'
  and chosen.markers['Norgan Chests'].unacquired_icon_color == 0xFF123456,
  'DLC defaults overwrote saved visibility or artwork choices')
local base={schema_version=1,chests={base={gimmick_id=10,variants={{world='any'}}}}}
local extra={schema_version=1,records={coin={gimmick_id=894,variants={{world='normal'}}}}}
local merged=dlc.availability_catalog(base,extra)
assert(merged.chests.base and merged.chests.coin and not base.chests.coin,
  'DLC availability changed the original catalog')
local policy=require('raze_MapMarkersAndCollectables.chest_availability').create({
  snapshot=function() return {unmoored=false} end, reset=function() end}, merged)
local coin={key='coin',gimmick_id=894,marker_type={availability=true,gimmick_id=894},acquired=false}
local trial_marker={key='trial',gimmick_id=755,marker_type=trial,acquired=false}
merged.chests.trial={gimmick_id=755,variants={{world='normal',unsupported='Trial activation unverified'}}}
local visible=policy:filter({coin,trial_marker},{},'fullmap')
assert(#visible == 1 and visible[1] == coin, 'DLC world/trial requirements were bypassed')
assert(#policy:filter({trial_marker},{hide_unavailable_chests=false}) == 1, 'explicit previews were blocked')
coin.acquired=true
assert(#policy:filter({coin},{}) == 1, 'DLC availability suppressed acquired history')
local normalized=require('raze_MapMarkersAndCollectables.settings').normalize(
  {hide_unexplored_ducats=true}, {}, {}, {})
assert(normalized.hide_unexplored_ducats == true, 'Ducat fog preference was discarded')
