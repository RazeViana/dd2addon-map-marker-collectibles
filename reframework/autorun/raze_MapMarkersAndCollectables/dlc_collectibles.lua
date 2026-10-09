-- DLC categories use the same map, acquisition and appearance controls as existing items.
local M = {}

function M.create_access(api)
  local methods
  local function resolve()
    local definition = api.find_type_definition('via.Steam')
    if not definition then return end
    local result = {
      supported=definition:get_method('get_Supported'),
      initialized=definition:get_method('get_Initialized'),
      installed=definition:get_method('isInstalledDlc(System.UInt64)'),
    }
    if result.supported and result.initialized and result.installed then return result end
  end
  return {available=function()
    local ok, available = pcall(function()
      methods = methods or resolve()
      if not methods or methods.supported:call(nil) ~= true
          or methods.initialized:call(nil) ~= true then return false end
      return methods.installed:call(nil, 2593290) == true
    end)
    return ok and available == true
  end}
end

function M.availability_catalog(base, dlc)
  local result = {schema_version=1, chests={}}
  for key, value in pairs(type(base)=='table' and type(base.chests)=='table' and base.chests or {}) do result.chests[key]=value end
  for key, value in pairs(type(dlc)=='table' and dlc.schema_version==1
      and type(dlc.records)=='table' and dlc.records or {}) do
    assert(result.chests[key]==nil, 'Duplicate DLC collectible identity: '..key)
    result.chests[key]=value
  end
  return result
end

function M.coin_callbacks(api, get_context, context_type)
  local diagnostics, pickup_mask = {}, nil
  local function read_mask()
    if pickup_mask then return pickup_mask end
    local ok, value = pcall(function()
      local definition=api.find_type_definition('app.Gm83_169')
      local field=definition and definition:get_field('FreeBitGet')
      return field and field:is_static() and field:get_data(nil) or nil
    end)
    if ok and type(value)=='number' and value%1==0 and value>0 and value<=0x40000000
        and (value & (value-1))==0 then
      pickup_mask=value
      diagnostics.error=nil
      return pickup_mask
    end
    diagnostics.error="Norgan Ducat pickup history is unavailable. Only confirmed nearby pickups and never-generate records can hide collected Ducats."
  end
  return {
    function(args)
      if args.all.generate_manager:isNeverGenerate(args.collectible_id)==true then return true end
    end,
    function(args)
      local gimmick=args.gimmick_map[args.collectible_id:ToString()]
      if gimmick and gimmick:get_IsGetFreeBit()==true then return true end
    end,
    function(args)
      local bit=read_mask()
      if not bit then return nil end
      local context=get_context(args, context_type)
      if context then return context:isOnFreeBit(bit) end
    end,
  }, diagnostics
end

function M.register(types, names, load, chest_callbacks, coin_callbacks, chest_defaults)
  local prefix='raze_MapMarkersAndCollectables/'
  local function add(name, definition)
    definition.label=name
    definition.availability=true
    definition.requires_dlc=true
    types[name]=definition
    names[#names+1]=name
  end
  local function defaults(color, style)
    local result=chest_defaults(color)
    result.unacquired_show=true
    result.unacquired_icon_style=style
    result.acquired_icon_style=style
    return result
  end
  add('Norgan Ducats', {
    name='Norgan Ducat', gimmick_id=894, object_icon=86,
    fog_setting='hide_unexplored_ducats', data=load(prefix..'894.json'),
    get_state_callbacks=coin_callbacks,
    settings_default={unacquired_icon_type=25,acquired_icon_type=25,
      unacquired_icon_color=0xFF6FD6FF,acquired_icon_color=0xA0376B7F,
      unacquired_icon_style='norgan_ducat',acquired_icon_style='norgan_ducat',
      unacquired_show=true,acquired_show=false},
  })
  for _, item in ipairs({{'Norgan Chests',826,84,0xFFF0D0A0},
      {'Norgan Rare Chests',885,85,0xFFFFA8DA}}) do
    add(item[1], {name=item[1]=='Norgan Chests' and 'Norgan Chest' or 'Norgan Rare Chest',
      gimmick_id=item[2],object_icon=item[3],fog_setting='hide_unexplored_chests',
      data=load(prefix..item[2]..'.json'),get_state_callbacks=chest_callbacks,
      settings_default=defaults(item[4],item[2]==826 and 'norgan' or 'norgan_rare')})
  end
  local merged={locations={},gimmick_ids={}}
  for _, kind in ipairs({755,757,758,795}) do
    local data=load(prefix..kind..'.json')
    for key, position in pairs(type(data)=='table' and data.locations or {}) do
      assert(merged.locations[key]==nil,'Duplicate Lost Rites chest: '..key)
      merged.locations[key]=position
      merged.gimmick_ids[key]=kind
    end
  end
  add('Lost Rites Chests', {name='Lost Rites Chest',gimmick_ids={755,757,758,795},
    object_icon=85,fog_setting='hide_unexplored_chests',data=merged,
    get_state_callbacks=chest_callbacks,live_acquired=true,
    settings_default=defaults(0xFFDDB7FF,'norgan_rare'),
    tooltip='Fixed chest placements in the Lost Rites dungeons. Trial activation and renewal are unverified; unopened locations stay hidden with progression filtering enabled. Disable that filter only to preview placements.'})
end

return M
