"""The five TOC files: one per client family, identical but for the Interface line.

    python -m unittest discover -s tests -p "test_*.py"
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
INTERFACES = {
    "Mainline": {"120105", "120107"},
    "Mists": {"50504"},
    "TBC": {"20506"},
    "Vanilla": {"11509"},
    "Camelot": {"16001"},
}


def read(flavor):
    return (ROOT / f"Buttonstone_{flavor}.toc").read_text(encoding="utf-8")


class TocTests(unittest.TestCase):
    def test_one_toc_per_client_family(self):
        found = {p.stem.split("_", 1)[1] for p in ROOT.glob("Buttonstone_*.toc")}
        self.assertEqual(found, set(INTERFACES))
        self.assertFalse((ROOT / "Buttonstone.toc").exists(), "a TOC without a suffix would load on every client")

    def test_interface_numbers(self):
        for flavor, wanted in INTERFACES.items():
            line = re.search(r"^## Interface: (.+)$", read(flavor), re.M)
            self.assertIsNotNone(line, flavor)
            self.assertEqual({v.strip() for v in line.group(1).split(",")}, wanted, flavor)

    def test_identical_but_for_the_interface(self):
        def body(flavor):
            return re.sub(r"^## Interface: .+$", "", read(flavor), flags=re.M)
        mainline = body("Mainline")
        for flavor in INTERFACES:
            self.assertEqual(body(flavor), mainline, f"Buttonstone_{flavor}.toc differs from Mainline")

    def test_metadata(self):
        text = read("Mainline")
        self.assertIn("## Version: @project-version@", text)
        self.assertIn("## SavedVariables: ButtonstoneDB", text)
        self.assertNotIn("﻿", text, "no byte order mark")
        icon = re.search(r"^## IconTexture: Interface\\AddOns\\Buttonstone\\(.+)$", text, re.M)
        self.assertIsNotNone(icon)
        self.assertTrue((ROOT / (icon.group(1).replace("\\", "/") + ".tga")).is_file(), "icon texture exists")

    def test_files_listed_and_present(self):
        listed = [l.strip() for l in read("Mainline").splitlines() if l.strip() and not l.startswith("#")]
        for name in listed:
            self.assertTrue((ROOT / name).is_file(), f"{name} is listed but missing")
        on_disk = sorted(p.name for p in ROOT.glob("*.lua"))
        self.assertEqual(sorted(listed), on_disk, "every Lua file at the root is listed, and nothing else")


if __name__ == "__main__":
    unittest.main()
