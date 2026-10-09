-- Extended atlases preserve native patterns and add object symbols and minimap arrows.
local M = {}
M.styles = {
  { key = 'default', label = 'Follow global icon style' },
  { key = 'small', label = 'Small chest', icon = 80 },
  { key = 'medium', label = 'Medium chest', icon = 78 },
  { key = 'large', label = 'Large chest', icon = 81 },
  { key = 'sunken', label = 'Sunken chest', icon = 82 },
  { key = 'special', label = 'Special chest', icon = 79 },
  { key = 'sphinx', label = 'Sphinx chest', icon = 83 },
  { key = 'norgan', label = 'Norgan chest', icon = 84 },
  { key = 'norgan_rare', label = 'Norgan rare chest', icon = 85 },
  { key = 'norgan_ducat', label = 'Norgan Ducat', icon = 86 },
  { key = 'native', label = 'Game symbol' },
}
local style_by_key = {}
for _, style in ipairs(M.styles) do style_by_key[style.key] = style end

function M.valid_style(value)
  return type(value) == 'string' and style_by_key[value] ~= nil
end

function M.resolve_type(marker_type, marker_settings, prefix, use_objects)
  local style = style_by_key[marker_settings[prefix .. '_icon_style']] or style_by_key.default
  if style.icon then return style.icon end
  if style.key == 'native' or not use_objects then return marker_settings[prefix .. '_icon_type'] end
  return marker_type.object_icon
end
local original_paths = {
  fullmap = 'Gui/ui01/Common/map/UVS_map_01.uvs',
  minimap = 'Gui/ui01/Common/map/UVS_map_03.uvs'
}

function M.native_type(icon_type)
  return icon_type >= 76 and icon_type <= 86 and 31 or icon_type
end

function M.create(api, warn)
  local self = { states = {} }
  local function load(path)
    local resource = api.create_resource('via.uvsequence.UVSequenceResource', path)
    assert(resource, 'Could not load ' .. path)
    return resource:create_holder('via.uvsequence.UVSequenceResourceHolder'):add_ref()
  end

  function self:clear(ui, kind)
    local state = self.states[kind]
    if not state or state.ui ~= ui then return end
    for _, saved in ipairs(state.refs) do
      saved.sprite:set_UVSequenceNo(saved.sequence)
      saved.sprite:set_UVPatternNo(saved.pattern)
    end
    state.refs = {}
  end

  local function apply_pattern(ui, kind, ref, sequence, pattern)
    if not ref or not ref.Sprite then return false end
    local state = self.states[kind]
    if not state or state.ui ~= ui then
      state = { ui = ui, refs = {} }
      self.states[kind] = state
      local ok, err = pcall(function()
        local set = assert(ui.MapIconSpriteSet, 'No map sprite atlas')
        local original = set:get_UVSequence()
        local path = original:get_ResourcePath():lower()
        local custom_path = 'raze/mapmarkers/' .. kind .. '.uvs'
        assert(path == original_paths[kind]:lower() or path == custom_path, 'Another mod has replaced the map atlas')
        -- Recover the native holder if scripts were reloaded with the map still open.
        state.original = path == custom_path and load(original_paths[kind]) or original:add_ref()
        state.custom = load(custom_path)
        set:set_UVSequence(state.custom)
      end)
      if not ok then
        state.error = tostring(err)
        warn('Custom map artwork unavailable; using game symbols without height indicators. ' .. state.error)
      end
    end
    if state.error then return false end
    local sprite = ref.Sprite
    -- Minimap borrowing already captures and restores the sprite's exact UV state.
    if kind == 'fullmap' then
      state.refs[#state.refs + 1] = { sprite = sprite, sequence = sprite:get_UVSequenceNo(), pattern = sprite:get_UVPatternNo() }
    end
    sprite:set_UVSequenceNo(sequence)
    sprite:set_UVPatternNo(pattern)
    return true
  end

  function self:apply(ui, kind, ref, icon_type)
    if M.native_type(icon_type) == icon_type then return false end
    return apply_pattern(ui, kind, ref, 2, icon_type - 76)
  end

  function self:apply_height(ui, ref, direction)
    return apply_pattern(ui, 'minimap', ref, 3, direction > 0 and 0 or 1)
  end

  function self:destroy(ui, kind)
    if self.states[kind] and self.states[kind].ui == ui then self.states[kind] = nil end
  end

  function self:restore()
    for kind, state in pairs(self.states) do
      self:clear(state.ui, kind)
      if state.original then state.ui.MapIconSpriteSet:set_UVSequence(state.original) end
    end
    self.states = {}
  end
  return self
end
return M
