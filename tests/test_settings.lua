local settings = require("raze_MapMarkersAndCollectables.settings")
local names = { "Tokens", "Chests" }
local generic = { unacquired_show = false, acquired_show = false,
  unacquired_icon_type = 25, acquired_icon_type = 25,
  unacquired_icon_color = 0xFFD4AF37, acquired_icon_color = 0xCC5F4E19 }
local types = { Tokens = { settings_default = {
  unacquired_show = true, acquired_show = false,
  unacquired_icon_type = 25, acquired_icon_type = 25,
  unacquired_icon_color = 0xFF00CC00, acquired_icon_color = 0xCC006600 } }, Chests = {} }

-- Malformed settings must not stop script initialization or lose defaults.
for _, loaded in ipairs({ false, 123, "bad", {}, { markers = false } }) do
  local actual = settings.normalize(loaded, names, types, generic)
  assert(actual.markers.Tokens.unacquired_show == true)
  assert(actual.markers.Chests.unacquired_show == false)
  assert(#actual.marker_order == 2)
end
local actual = settings.normalize({ marker_order = { "Chests", "Chests", "Deleted" }, markers = {
  Tokens = { unacquired_show = false, acquired_show = "true", unacquired_icon_type = 999,
    acquired_icon_type = 1.5, unacquired_icon_color = -1 },
  Chests = { unacquired_show = true, unacquired_icon_type = 14, unacquired_icon_color = 0xFF112233 }
} }, names, types, generic)
assert(table.concat(actual.marker_order, ",") == "Chests,Tokens")
assert(actual.markers.Tokens.unacquired_show == false)
assert(actual.markers.Tokens.acquired_show == false)
assert(actual.markers.Tokens.unacquired_icon_type == 25)
assert(actual.markers.Tokens.acquired_icon_type == 25)
assert(actual.markers.Tokens.unacquired_icon_color == 0xFF00CC00)
assert(actual.markers.Chests.unacquired_icon_type == 14)
assert(actual.markers.Chests.unacquired_icon_color_gui == 0xFF332211)
assert(types.Tokens.settings_default.unacquired_show == true)

-- A current file wins; old settings are imported only when no usable current table exists.
local calls = {}
local legacy = { markers = { Tokens = { acquired_show = true } } }
local api = { load_file = function(path)
  calls[#calls + 1] = path
  if path == "old.json" then return legacy end
end }
local loaded, migrated = settings.load(api, "new.json", "old.json")
assert(loaded == legacy and migrated == true)
assert(table.concat(calls, ",") == "new.json,old.json")
calls = {}
api.load_file = function(path) calls[#calls + 1] = path; return {} end
loaded, migrated = settings.load(api, "new.json", "old.json")
assert(type(loaded) == "table" and migrated == false and #calls == 1)
api.load_file = function() error("invalid JSON") end
loaded, migrated = settings.load(api, "new.json", "old.json")
assert(loaded == nil and migrated == false)

actual = settings.normalize({minimap={enabled=false,radius=99999,height=-10,max_markers=1000}}, names, types, generic)
assert(actual.minimap.enabled == false)
assert(actual.minimap.radius == 180 and actual.minimap.height == 60 and actual.minimap.max_markers == 24)
actual = settings.normalize({minimap={enabled=true,radius=100,height=30,max_markers=5}}, names, types, generic)
assert(actual.minimap.radius == 100 and actual.minimap.height == 30 and actual.minimap.max_markers == 5)
actual = settings.normalize({minimap={max_markers=200}}, names, types, generic)
assert(actual.minimap.max_markers == 200, "expanded minimap limit is rejected")
