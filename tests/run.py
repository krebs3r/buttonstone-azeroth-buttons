"""Runs the addon's Lua files in Lua 5.1 against a small WoW API double, once per client.

    python tests/run.py

The files load in the order the TOC lists them. Requires lupa (requirements-dev.txt).
No WoW installation is used, and this does not replace a look in the game.
"""
from pathlib import Path
import sys

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
# Each list runs in a Lua state of its own. The second has MinimapButtonButton loaded.
RUNS = [
    (["test_core.lua", "test_collector.lua"], False),
    (["test_rival.lua"], True),
]

# name, WOW_PROJECT_ID, defines WOW_PROJECT_CAMELOT, interface, locale, has the Addons menu, look, client art
CLIENTS = [
    ("Retail", 1, False, 120105, "deDE", True, "retail", True),
    ("Mists of Pandaria Classic", 19, False, 50504, "enUS", False, "classic", True),
    ("TBC Anniversary", 5, False, 20506, "deDE", False, "classic", True),
    ("Classic Era", 2, False, 11509, "enUS", False, "classic", True),
    ("WoW: Forever", 18, True, 16001, "deDE", True, "forever", True),
    ("WoW: Forever beta", 1, False, 16001, "enUS", True, "forever", True),
    # Forever's own pieces missing: each falls back to the flat look.
    ("WoW: Forever without its art", 18, True, 16001, "deDE", True, "forever", False),
]


def toc_files():
    text = (ROOT / "Buttonstone_Mainline.toc").read_text(encoding="utf-8-sig")
    return [line.strip() for line in text.splitlines() if line.strip() and not line.startswith("#")]


def run_client(tests, rival, name, project, camelot, interface, locale, compartment, look, art):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests" / "wow_mock.lua").read_text(encoding="utf-8"))
    g = lua.globals()
    g.WOW_PROJECT_ID = project
    if camelot:
        g.WOW_PROJECT_CAMELOT = 18
    g.Mock.interface = interface
    g.Mock.locale = locale
    if not compartment:
        g.AddonCompartmentFrame = None
    if art:
        g.Mock.InstallArt()
    if rival:
        g.Mock.loaded.MinimapButtonButton = True
    g.Mock.expect = lua.table_from({"look": look, "locale": locale, "compartment": compartment, "art": art})

    load = lua.eval(
        "function(code, chunk, ns) local f, e = loadstring(code, chunk); assert(f, e); return f('Buttonstone', ns) end"
    )
    ns = lua.table()
    for file in toc_files():
        load((ROOT / file).read_text(encoding="utf-8"), "@" + file, ns)

    passed = 0
    for test in tests:
        passed += load((ROOT / "tests" / test).read_text(encoding="utf-8"), "@tests/" + test, ns)
    return passed


def main():
    total = 0
    for client in CLIENTS:
        passed = 0
        for tests, rival in RUNS:
            try:
                passed += run_client(tests, rival, *client)
            except Exception as error:  # a failed assert arrives as a LuaError
                print(f"FAIL {client[0]}{' with MinimapButtonButton' if rival else ''}: {error}")
                sys.exit(1)
        print(f"ok   {client[0]}: {passed} checks")
        total += passed
    print(f"{total} checks passed on {len(CLIENTS)} clients")


if __name__ == "__main__":
    main()
