local dlc = require('raze_MapMarkersAndCollectables.dlc_collectibles')
assert(type(dlc.create_access) == 'function', 'DLC access guard is missing')

local supported, initialized, installed = true, false, false
local queried = 0
local methods = {
  get_Supported = {call=function(_, receiver)
    assert(receiver == nil); return supported
  end},
  get_Initialized = {call=function(_, receiver)
    assert(receiver == nil); return initialized
  end},
  ['isInstalledDlc(System.UInt64)'] = {call=function(_, receiver, app_id)
    assert(receiver == nil and app_id == 2593290, 'wrong DLC identity or static receiver')
    queried = queried + 1
    if installed == 'error' then error('Steam is temporarily unavailable') end
    return installed
  end},
}
local api = {find_type_definition=function(name)
  assert(name == 'via.Steam'); return {get_method=function(_, name) return methods[name] end}
end}
local access = dlc.create_access(api)
assert(access:available() == false and queried == 0, 'uninitialized Steam queried DLC ownership')
initialized = true
assert(access:available() == false and queried == 1, 'non-owner enabled DLC markers')
installed = true
assert(access:available() == true and queried == 2, 'installed DLC did not recover after initialization')
supported = false
assert(access:available() == false and queried == 2, 'unsupported platform queried Steam DLC')
supported = true
for _, value in ipairs({'error', 'true', 1}) do
  installed = value
  assert(access:available() == false, 'failed or malformed ownership read enabled DLC')
end
installed = true
assert(access:available() == true, 'transient DLC access failure was permanently cached')
for _, missing in ipairs({'get_Supported', 'get_Initialized', 'isInstalledDlc(System.UInt64)'}) do
  local saved = methods[missing]
  methods[missing] = nil
  assert(dlc.create_access(api):available() == false, 'missing native method stopped base-game support')
  methods[missing] = saved
end
assert(dlc.create_access({find_type_definition=function() return nil end}):available() == false)
assert(dlc.create_access({find_type_definition=function() error('no Steam binding') end}):available() == false)
