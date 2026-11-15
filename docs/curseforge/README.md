# Publishing Buttonstone

A pushed version tag uploads Buttonstone to GitHub, CurseForge and Wago through `.github/workflows/release.yml` and the BigWigs packager, as Umbra Unit Frames does. `tools/release.ps1` makes the tag.

## Once: the projects and the tokens

1. **CurseForge project.** In the [CurseForge authors dashboard](https://authors.curseforge.com/), create a World of Warcraft addon project:
   - name: `Buttonstone – Azeroth Buttons`
   - summary: `All your minimap buttons in one stone: gathers other addons' minimap buttons into one button and a panel in your client's look.`
   - main category: Map & Minimap
   - license: MIT
   - logo: [logo-400.png](logo-400.png)
   - description: [description.md](description.md)
   - source: `https://github.com/krebs3r/buttonstone-azeroth-buttons`, issues: the repository's issues
2. **Wago project.** On [addons.wago.io](https://addons.wago.io/), create the project with the same name, summary, logo and description.
3. **IDs into the TOCs.** Add both IDs under `## X-License: MIT` in all five `Buttonstone_*.toc` files (the TOC test keeps them identical):

   ```
   ## X-Curse-Project-ID: <CurseForge project ID>
   ## X-Wago-ID: <Wago project ID>
   ```

4. **Secrets.** In the repository's *Settings → Secrets and variables → Actions*, add `CF_API_KEY` (an API token from your CurseForge author settings) and `WAGO_API_TOKEN` (an API key from your Wago account). The same tokens as Umbra's work.

The release workflow stops before uploading anything if an ID or a token is missing.

## Every release

1. Write what changed under `## Unreleased` at the top of [CHANGELOG.md](../../CHANGELOG.md) and merge it into `main`. Every release carries a real change.
2. Install it with `tools/install.ps1` and look at it in the game.
3. On an up-to-date, clean `main`:

   ```powershell
   .\tools\release.ps1 0.1.1 -DryRun
   .\tools\release.ps1 0.1.1
   ```

   The script checks the version, the IDs, the changelog and the tests, dates the section (`## 0.1.1 — 16 November 2026`), commits `Release 0.1.1`, tags and pushes.
4. The workflow runs the tests on the tag, cuts the release notes from the newest changelog section and uploads one package with every TOC. Each site reads the client versions from the TOCs. Watch it under [Actions](https://github.com/krebs3r/buttonstone-azeroth-buttons/actions) and check the files on CurseForge and Wago after moderation.
5. Start a new `## Unreleased` section with the next change.

## The project page

Uploads do not change the project description. When [description.md](description.md) changes, copy it into the description editor on CurseForge and Wago. Its pictures load from this repository's `main` branch ([screenshots](screenshots)): in-game crops of the panel on Retail, WoW: Forever and TBC Anniversary, without character names.
