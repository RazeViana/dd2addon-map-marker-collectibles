local icons = require('raze_MapMarkersAndCollectables.object_icons')
local settings = require('raze_MapMarkersAndCollectables.settings')
assert(type(icons.resolve_type) == 'function', 'per-category artwork selection is missing')
local kind = { object_icon = 80 }
local configured = { unacquired_icon_type = 14, acquired_icon_type = 25,
  unacquired_icon_style = 'default', acquired_icon_style = 'default' }
assert(icons.resolve_type(kind, configured, 'unacquired', true) == 80)
assert(icons.resolve_type(kind, configured, 'unacquired', false) == 14)
configured.unacquired_icon_style = 'sunken'
assert(icons.resolve_type(kind, configured, 'unacquired', false) == 82,
  'explicit category artwork must override the global default')
assert(icons.resolve_type(kind, configured, 'acquired', false) == 25,
  'unacquired appearance changed acquired appearance')
configured.acquired_icon_style = 'native'
assert(icons.resolve_type(kind, configured, 'acquired', true) == 25)
for style, expected in pairs({small=80, medium=78, large=81, sunken=82, special=79, sphinx=83}) do
  configured.unacquired_icon_style = style
  assert(icons.resolve_type(kind, configured, 'unacquired', true) == expected)
end
for style, expected in pairs({norgan=84, norgan_rare=85, norgan_ducat=86}) do
  configured.unacquired_icon_style = style
  assert(icons.valid_style(style))
  assert(icons.resolve_type(kind, configured, 'unacquired', false) == expected,
    'DLC artwork must override the global native-symbol preference')
end

local generic = { unacquired_show = false, acquired_show = false,
  unacquired_icon_type = 25, acquired_icon_type = 25,
  unacquired_icon_color = 0xFFFFFFFF, acquired_icon_color = 0xAAAAAAAA }
local types = { Chest = kind }
local migrated = settings.normalize({object_icons=false, markers={Chest={
  unacquired_icon_type=14, acquired_icon_color=0xAA123456}}}, {'Chest'}, types, generic)
assert(migrated.markers.Chest.unacquired_icon_style == 'default')
assert(icons.resolve_type(kind, migrated.markers.Chest, 'unacquired', migrated.object_icons) == 14,
  'migration lost the saved native glyph')
assert(migrated.markers.Chest.acquired_icon_color == 0xAA123456, 'migration lost custom colors')
for _, invalid in ipairs({false, 80, 'invalid', {}}) do
  local got = settings.normalize({markers={Chest={unacquired_icon_style=invalid,
    acquired_icon_style='special'}}}, {'Chest'}, types, generic)
  assert(got.markers.Chest.unacquired_icon_style == 'default')
  assert(got.markers.Chest.acquired_icon_style == 'special')
end
local saved = settings.normalize({markers={Chest={unacquired_icon_style='large'}}}, {'Chest'}, types, generic)
local reloaded = settings.normalize(saved, {'Chest'}, types, generic)
assert(icons.resolve_type(kind, reloaded.markers.Chest, 'unacquired', true) == 81,
  'saved per-category artwork did not survive reload')
