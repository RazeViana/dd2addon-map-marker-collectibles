-- Map Markers and Collectables by Raze - runtime diagnostics
-- Kept independent so the report can be generated even if the map script fails to load.
local diagnostics = require("raze_MapMarkersAndCollectables.diagnostics")
local filename = "raze_MapMarkersAndCollectables_minimap_diagnostics.json"
local status = ""

local function export_report()
  local ok, report = pcall(diagnostics.collect, sdk)
  if not ok then
    status = "Could not inspect the runtime: " .. tostring(report)
    log.error("Map Markers and Collectables by Raze: " .. status)
    return
  end
  local saved, error_message = diagnostics.export(json, filename, report)
  if saved then
    status = "Saved to reframework/data/" .. filename
    log.info("Map Markers and Collectables by Raze: " .. status)
  else
    status = tostring(error_message)
    log.error("Map Markers and Collectables by Raze: " .. status)
  end
end

-- Metadata is available at script startup; use the button again after loading a save
-- to include whether the minimap HUD is present.
export_report()
re.on_draw_ui(function()
  if imgui.tree_node("Map Markers and Collectables by Raze - Diagnostics") then
    imgui.text("Runtime information for minimap compatibility and troubleshooting.")
    imgui.text("Export while a save is loaded and the minimap is visible.")
    if imgui.button("Export Minimap Diagnostics") then export_report() end
    imgui.text(status)
    imgui.tree_pop()
  end
end)
