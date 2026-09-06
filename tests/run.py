"""Run the Lua checks with Lua 5.4 through Lupa; no game installation required."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools" / "python"))
from lupa.lua54 import LuaRuntime

for path in sorted((ROOT / "tests").glob("test_*.lua")):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().TEST_ROOT = ROOT.as_posix()
    lua.execute("package.path = ... .. '/reframework/autorun/?.lua;' .. package.path", ROOT.as_posix())
    if path.name == "test_diagnostics.lua":
        lua.execute("package.path = ... .. '/scripts/development/reframework/autorun/?.lua;' .. package.path", ROOT.as_posix())
    lua.execute(path.read_text(encoding="utf-8"), name=path.name)
    print(f"PASS {path.name}")
lua = LuaRuntime(unpack_returned_tuples=True)
for path in sorted((ROOT / "reframework").rglob("*.lua")):
    lua.compile(path.read_text(encoding="utf-8"), name=path.relative_to(ROOT).as_posix())
print("PASS syntax for all runtime Lua files")
for path in sorted((ROOT / "scripts/development").rglob("*.lua")):
    lua.compile(path.read_text(encoding="utf-8"), name=path.relative_to(ROOT).as_posix())
print("PASS syntax for development Lua files")
sys.path.insert(0, str(ROOT / "scripts"))
from icon_assets import validate
validate()
print("PASS icon assets and unchanged native atlas entries")
