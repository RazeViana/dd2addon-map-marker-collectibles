local diagnostics = require("raze_MapMarkersAndCollectables.diagnostics")
local function type_ref(name)
  return { get_full_name = function() return name end }
end
local function method(name, param_type)
  return {
    get_name = function() return name end,
    get_param_types = function() return { type_ref(param_type) } end,
    get_param_names = function() return { "position" } end,
    get_return_type = function() return type_ref("System.Boolean") end,
    is_static = function() return false end
  }
end
local parent = {
  get_full_name = function() return "app.GUIBase" end,
  get_methods = function() return {} end,
  get_fields = function() return {{
    get_name = function() return "Visible" end,
    get_type = function() return type_ref("System.Boolean") end,
    get_offset_from_base = function() return 16 end,
    is_static = function() return false end
  }} end,
  get_parent_type = function() return nil end
}
local minimap = {
  get_full_name = function() return "app.ui020301" end,
  get_methods = function() return { method("check", "via.vec3"), method("check", "System.Int32"),
    { get_name = function() error("reflection unavailable") end } } end,
  get_fields = function() return {} end,
  get_parent_type = function() return parent end
}
local report = diagnostics.collect({
  find_type_definition = function(name) if name == "app.ui020301" then return minimap end end,
  get_managed_singleton = function() return nil end
})
assert(report.types["app.ui020301"].name == "app.ui020301")
local methods = report.types["app.ui020301"].methods
assert(#methods == 2)
assert(methods[1].parameters[1].type ~= methods[2].parameters[1].type)
assert(methods[1].returns == "System.Boolean")
assert(report.types["app.GUIBase"].fields[1].name == "Visible")
assert(report.types["app.GUIBase"].fields[1].offset == 16)
assert(report.types["app.ui040205"].missing == true)
assert(#report.errors == 1)
assert(report.minimap_instance.present == false)

-- A missing type database should still produce a usable report, not abort export.
report = diagnostics.collect({ find_type_definition = function() error("TDB not ready") end,
  get_managed_singleton = function() return nil end })
assert(report.types["app.ui020301"].missing == true)
assert(#report.errors > 0)

local exported
local ok = diagnostics.export({ dump_file = function(path, value)
  assert(path == "report.json")
  exported = value
  return true
end }, "report.json", report)
assert(ok == true and exported == report)
assert(diagnostics.export({ dump_file = function() return false end }, "report.json", report) == false)
assert(diagnostics.export({ dump_file = function() error("write denied") end }, "report.json", report) == false)
