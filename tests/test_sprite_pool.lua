local module = require("raze_MapMarkersAndCollectables.sprite_pool")
local attachments, created, array_fail, clone_fail, attach_fail = {}, 0, false, false, false
local function sprite()
  local value = { visible=true, sequence=1, pattern=25, priority=3, position={x=1,y=2,z=0},
    rotation=0, size={w=16,h=16}, color=123, hit=true }
  function value:add_ref() return self end
  for name, field in pairs({Visible="visible",UVSequenceNo="sequence",UVPatternNo="pattern",Priority="priority",
    Position="position",Rotation="rotation",Size="size",Color="color",HitTestVisible="hit"}) do
    value["get_" .. name] = function(self) return self[field] end
    value["set_" .. name] = function(self, data) self[field] = data end
  end
  return value
end
local fields = {}
for _, key in ipairs({"Path","Sprite","TexBG","TexScale","PosRate","IconSize","IsMenu","_IconType"}) do
  fields[#fields+1] = { get_name=function() return key end, is_static=function() return false end,
    get_data=function(_, ref) return ref[key] end }
end
local function ref()
  return {Path={},Sprite=sprite(),TexBG=sprite(),TexScale=0.6,PosRate=1,IconSize={w=16,h=16},IsMenu=false,_IconType=25,
    add_ref=function(self) return self end, set_field=function(self,key,value) self[key]=value end}
end
local function array(count)
  local result={get_Length=function() return count end,add_ref=function(self) return self end}
  for i=0,count-1 do result[i]=ref() end
  return result
end
local api={
  find_type_definition=function() return {get_fields=function() return fields end} end,
  create_instance=function(name, simplify)
    created=created+1
    if clone_fail then return nil end
    if name=="via.gui.Sprite" then return sprite() end
    assert(name=="app.GUIBase.MapIconSpriteRef")
    assert(simplify == true, "icon wrappers have no parameterless constructor")
    return ref()
  end,
  create_managed_array=function(_, count) if not array_fail then return array(count) end end
}
local function sprite_set()
  return {addSprite=function(_, value)
    if attach_fail then error("attach failure") end
    attachments[#attachments+1]=value
  end}
end
local function ui()
  local items={ref(),ref()}
  return {MapIconSprite=array(2),MapIconSpriteSet=sprite_set(),MapIconBgSpriteSet=sprite_set(),MapIconBGSpriteSet=sprite_set(),
    MapIconList={get_Count=function() return #items end,get_Item=function(_, i) return items[i+1] end,
      Add=function(_, item) items[#items+1]=item end}}
end
local manager=module.create(api)
local map=ui()
local original, template=map.MapIconSprite, map.MapIconSprite[0]
assert(manager:ensure(map,"fullmap",5)==5)
assert(map.MapIconSprite~=original and map.MapIconSprite[0]==original[0] and map.MapIconSprite[1]==original[1])
assert(#attachments==6, "new foreground/background sprites were not attached")
local added=map.MapIconSprite[2]
assert(added~=template and added.Path==template.Path and added.TexScale==0.6 and added.Sprite~=template.Sprite)
assert(not added.Sprite.visible and not added.TexBG.visible and added.Sprite.pattern==25,
  "new sprites must be hidden and retain the native atlas properties")
local previous_created=created
assert(manager:ensure(map,"fullmap",5)==5 and created==previous_created, "pool grows again every update")
-- New manager after script reset must reuse the already expanded pool.
manager=module.create(api)
assert(manager:ensure(map,"fullmap",5)==5 and created==previous_created)
assert(manager:ensure(map,"minimap",4)==4 and map.MapIconList:get_Count()==4)
assert(map.MapIconList:get_Item(0).Sprite.visible, "native slots changed")
-- Turning on height indicators can grow a running minimap without replacing native entries.
local native_minimap_slot = map.MapIconList:get_Item(0)
assert(manager:ensure(map,"minimap",512)==512)
assert(map.MapIconList:get_Item(0)==native_minimap_slot and native_minimap_slot.Sprite.visible)
previous_created=created
assert(manager:ensure(map,"minimap",256)==512 and created==previous_created,
  "disabling height indicators rebuilt the minimap pool")
manager=module.create(api)
assert(manager:ensure(map,"minimap",512)==512 and created==previous_created,
  "script reset duplicated the arrow-capable pool")
-- Failure before publication leaves the native pool intact and is not retried every frame.
map=ui(); original=map.MapIconSprite; array_fail=true
local count, err=manager:ensure(map,"fullmap",5)
assert(count==2 and err and map.MapIconSprite==original)
previous_created=created
manager:ensure(map,"fullmap",5)
assert(created==previous_created)
array_fail=false; clone_fail=true; map=ui(); original=map.MapIconSprite
count,err=manager:ensure(map,"fullmap",5)
assert(count==2 and err and map.MapIconSprite==original)
clone_fail=false; attach_fail=true; map=ui(); original=map.MapIconSprite
count,err=manager:ensure(map,"fullmap",5)
assert(count==2 and err and map.MapIconSprite==original)
attach_fail=false
-- Recreated HUDs get their own pool and do not inherit a prior HUD's failure.
map=ui()
assert(manager:ensure(map,"fullmap",5)==5)
