-- Extend the game's sprite pools while preserving every existing native slot.
local M = {}
local ref_type = "app.GUIBase.MapIconSpriteRef"
local sprite_properties = { "Priority", "UVSequenceNo", "UVPatternNo", "Position", "Rotation", "Size", "Color", "HitTestVisible" }

function M.create(api)
  local self = { states = {} }
  local function allocate(name)
    -- The managed wrapper has only a parameterized constructor. Allocate its fields
    -- directly; clone_ref copies every field from an initialized native template.
    local value = api.create_instance(name, name == ref_type)
    if value == nil then error("Cannot create " .. name) end
    return value:add_ref()
  end
  local function clone_sprite(template)
    local value = allocate("via.gui.Sprite")
    value:set_Visible(false)
    for _, property in ipairs(sprite_properties) do
      value["set_" .. property](value, template["get_" .. property](template))
    end
    return value
  end
  local function clone_ref(template)
    local value = allocate(ref_type)
    -- Copy the native scale/atlas context, then give the ref its own sprites.
    for _, field in ipairs(api.find_type_definition(ref_type):get_fields()) do
      local name = field:get_name()
      if not field:is_static() and name ~= "Sprite" and name ~= "TexBG" then
        value:set_field(name, field:get_data(template))
      end
    end
    value.Sprite = clone_sprite(template.Sprite)
    value.TexBG = clone_sprite(template.TexBG)
    return value
  end

  function self:ensure(ui, kind, target)
    local mini = kind == "minimap"
    local pool = mini and ui.MapIconList or ui.MapIconSprite
    if pool == nil then return 0 end
    local count = mini and pool:get_Count() or pool:get_Length()
    if count >= target then return count end
    local state = self.states[kind]
    if state and state.ui == ui and state.error then return count, state.error end
    local template = count > 0 and (mini and pool:get_Item(0) or pool[0])
    local sprites = ui.MapIconSpriteSet
    local backgrounds = mini and ui.MapIconBGSpriteSet or ui.MapIconBgSpriteSet
    if not template or not template.Sprite or not template.TexBG or not sprites or not backgrounds then return count end
    state = { ui = ui }
    self.states[kind] = state
    local pending = {}
    local ok, err = pcall(function()
      local replacement
      if not mini then
        replacement = api.create_managed_array(ref_type, target)
        if replacement == nil then error("Cannot allocate full-map sprite array") end
        replacement:add_ref()
        for i = 0, count - 1 do replacement[i] = pool[i] end
      end
      -- Finish allocation before touching the existing sprite sets or pool.
      for i = count, target - 1 do
        local ref = clone_ref(template)
        pending[#pending + 1] = ref
        if replacement then replacement[i] = ref end
      end
      for _, ref in ipairs(pending) do
        sprites:addSprite(ref.Sprite)
        backgrounds:addSprite(ref.TexBG)
      end
      if mini then
        for _, ref in ipairs(pending) do pool:Add(ref) end
      else
        ui.MapIconSprite = replacement
      end
    end)
    if not ok then
      -- Any partially attached sprites remain hidden. Do not retry on every frame.
      state.error = tostring(err)
      return mini and pool:get_Count() or pool:get_Length(), state.error
    end
    return mini and pool:get_Count() or ui.MapIconSprite:get_Length()
  end
  function self:destroy(ui, kind)
    if self.states[kind] and self.states[kind].ui == ui then self.states[kind] = nil end
  end
  return self
end
return M
