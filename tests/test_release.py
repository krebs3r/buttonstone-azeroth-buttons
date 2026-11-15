"""What a release relies on: the changelog's shape, the package rules and the workflow's names.

    python -m unittest discover -s tests -p "test_*.py"
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ReleaseTests(unittest.TestCase):
    def test_changelog_opens_with_a_section_the_release_can_date(self):
        text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
        headings = re.findall(r"^## .*$", text, re.M)
        self.assertTrue(headings, "CHANGELOG.md has sections")
        first = headings[0]
        self.assertTrue(
            first == "## Unreleased" or re.fullmatch(r"## \d+\.\d+\.\d+ — \d{1,2} [A-Z][a-z]+ \d{4}", first),
            f"first section {first!r} is neither '## Unreleased' nor a dated release",
        )
        for heading in headings[1:]:
            self.assertRegex(heading, r"^## \d+\.\d+\.\d+ — ", "older sections are dated releases")

    def test_package_leaves_development_files_out(self):
        pkgmeta = (ROOT / ".pkgmeta").read_text(encoding="utf-8")
        self.assertIn("package-as: Buttonstone", pkgmeta)
        for folder in ("docs", "assets", "tools", "tests", ".github", "RELEASE_NOTES.md"):
            self.assertIn(f"  - {folder}", pkgmeta, f"{folder} stays out of the package")
        self.assertIn("filename: RELEASE_NOTES.md", pkgmeta, "release notes come from the workflow")

    def test_workflow_reads_the_files_that_exist(self):
        workflow = (ROOT / ".github" / "workflows" / "release.yml").read_text(encoding="utf-8")
        for name in re.findall(r"Buttonstone_\w+\.toc", workflow):
            self.assertTrue((ROOT / name).is_file(), f"{name} named in the workflow exists")
        self.assertIn("'[0-9]+.[0-9]+.[0-9]+'", workflow, "tags like 0.1.0 start it")
        self.assertIn("BigWigsMods/packager", workflow)
        self.assertIn("CF_API_KEY", workflow)
        self.assertIn("WAGO_API_TOKEN", workflow)

    def test_release_script_dates_with_the_same_dash(self):
        script = (ROOT / "tools" / "release.ps1").read_text(encoding="utf-8")
        self.assertIn("[char]0x2014", script, "the script writes the em dash the changelog test expects")


if __name__ == "__main__":
    unittest.main()
