# Buttonstone – Azeroth Buttons: plan

Status, 15 November 2026: plan approved, **mockup approved** as shown (see *Mockup defaults*), **logo chosen**. No addon code exists yet; next is phase 3.

Buttonstone gathers the minimap buttons of other addons into one button on the minimap rim and shows them in a small panel in the client's own look. It joins Hourstone – Azeroth Hours and Soundstone – Azeroth Audio and follows their conventions.

## Decisions

| Topic | Decision |
| --- | --- |
| Name | Buttonstone – Azeroth Buttons; folder and slug `buttonstone-azeroth-buttons`; addon folder `Buttonstone`; SavedVariables `ButtonstoneDB` |
| Repository | `krebs3r/buttonstone-azeroth-buttons`, public, MIT. Created on GitHub only after the mockup is approved |
| Main button | On the minimap rim, dragged along it (round and square minimaps); can be detached and placed freely |
| What it gathers | All addon buttons: LibDBIcon (also buttons created later) and recognised buttons of their own (Hourstone, Soundstone, Umbra and the like). Blizzard's buttons only when switched on one by one |
| Addon compartment | Not touched in 0.1. Buttonstone lists itself there on Retail and Forever to open its options. Showing compartment entries in the panel is a later release |
| Panel | A grid in the client's look; columns and opening direction can be set |
| Closing | Closes shortly after the mouse leaves panel and main button; setting: stay open until clicked. Escape closes it |
| Button look | Uniform slots in the client's look (round borders hidden, icon in a slot); can be switched off; buttons whose structure is unknown keep their own look |
| Order | Alphabetical in 0.1; manual order by dragging is a later release |
| Excluding | One checkbox per button in the options; takes effect at once and is undone without `/reload` (Buttonstone keeps each button's original parent, points, scale and strata) |
| Languages | English and German |
| Logo | Chosen on 15 November 2026: the stone with a 2 × 2 gold button block (`assets/logo.png`; provenance in [ARTWORK.md](ARTWORK.md)) |
| Releases | BigWigsMods/packager on a pushed tag: GitHub release, CurseForge and Wago. A tag goes live at once; testing happens locally before tagging |
| Tags | Without a leading `v`, as in Umbra: `0.1.0` |
| Slash commands | `/buttonstone` and `/bst` |
| Combat | The main button stays visible; changes to other addons' buttons wait until combat ends |

## Mockup defaults

Approved on 15 November 2026 as the mockup shows them; the mockup is the reference for every in-game comparison from now on.

| Question | Answer |
| --- | --- |
| Panel header | On: logo, title, button count and gear (gear opens the options) |
| Columns, direction, size | 4 columns, direction automatic (towards the side with the most room), panel size 100 % |
| Slot size | 32 UI units, as action buttons; 4 units between slots |
| Main button start | Lower left on the minimap rim (145° in screen degrees, 0° = right, 90° = down) |
| Forever panel | The full bronze frame with the title strip, as Soundstone's mixer; with the header off, the frame without the strip |
| Main button tooltip | Title plus three lines: click shows the buttons, right-click opens the options, drag moves it |

## Clients and looks

The look follows the client; there is no switch, as in Hourstone and Soundstone 0.4.

| Client | Interface | Look |
| --- | --- | --- |
| Retail / Midnight | 120105 | Retail sprites (Soundstone's `RetailPanel`, gold) |
| Mists of Pandaria Classic | 50504 | Classic sprites (`ClassicPanel`, iron and stone) |
| TBC Classic Anniversary | 20506 | Classic sprites |
| Classic Era | 11509 | Classic sprites |
| WoW: Forever | 16001 | Forever's own art (`ButtonFrameTemplateNoPortrait`, red header buttons, icon frames), each piece checked with `C_Texture.GetAtlasInfo`; a missing piece falls back to the flat look on its own |

Open: Forever's minimap was reskinned in 1.60.1.70425 with Retail-style atlases. Whether the main button wants Retail's or Classic's tracking-border sizes there has not been checked in the game.

## Phases

1. Local folder, `git init`, this plan. **Done.**
2. **Mockup** (`docs/design/mockup.html`): one interactive page from the real Soundstone and Hourstone sprites, all three looks, four scenes (minimap and main button, open panel, detached main button, options window). **Approved on 15 November 2026.** From now on the mockup is the reference: every first in-game state is put next to it as a screenshot. Alongside: the logo brief and generator (`docs/ARTWORK.md`).
3. GitHub repository, scaffold: five TOCs (`_Mainline`, `_Mists`, `_TBC`, `_Vanilla`, `_Camelot`, as in Umbra), `Compat.lua`, luacheck, Lua tests with a WoW mock, CI, `tools/install.ps1`. **Built on 15 November 2026:** the repository is public, the scaffold loads the settings and answers `/bst version` and `/bst help`; the TOCs name no CurseForge or Wago project until those exist. **Checked in the game the same day**, build `dev-ad619ef` installed with `tools/install.ps1`, German clients: it loads on all five; `/bst version` reports `Retail` on Retail, `Classic` on Mists of Pandaria Classic, TBC Anniversary and Classic Era, and `WoW: Forever` on Forever, where `/bst` also printed the German help.
4. Collector, main button and panel on Retail; in-game screenshot against the mockup. **Built on 15 November 2026** (Retail and Classic sprites; Forever wears the Classic sprites until phase 5); checked in the Lua stand-in on six client variants. **In the game on WoW: Forever** (Classic sprites, German client), the same day: RareScanner, Soundstone, TradeSkillMaster and WIM gathered and shown, Questie, Hourstone and Umbra gathered and left out while their addons hide them; the panel matches the mockup's Classic panel. Two faults found and fixed there: WIM resets its button's strata and level and so slid behind the panel (now shadowed like SetPoint), and the count ran under the gear (the panel now makes room for the header). **In the game on Retail** the same day: six buttons gathered into the gold panel, which matches the mockup's Retail panel; on the minimap rim only Buttonstone's button and Blizzard's expansion button remain.
5. Classic and Forever looks, each compared with the mockup.
6. Options window and locales.
7. `tools/release.ps1`, CurseForge description with in-game screenshots; 0.1.0 after the author's test on all five clients.

## Architecture (planned)

| File | Purpose |
| --- | --- |
| `Compat.lua` | Client detection (`IsRetail`, `IsForever`, `RetailStyle`, compartment), API wrappers, secret-value-safe reads |
| `Theme.lua` | The three looks and the flat fallback; palettes taken from Soundstone |
| `Collector.lua` | Finds buttons: LibDBIcon list and callback, minimap children by heuristics, optional Blizzard buttons, ignore list; takes and releases them reversibly |
| `Bundle.lua` | The panel: grid, direction, auto-close, Escape |
| `Launcher.lua` | The main button: rim position, detached position, drag |
| `Options.lua` | Options window, Blizzard settings entry, compartment entry |
| `Locale.lua`, `Core.lua` | Strings (enUS, deDE); start-up, SavedVariables with defaults and migration |

No embedded libraries: LibDBIcon is found at runtime through LibStub if another addon loaded it. MinimapButtonButton is "all rights reserved"; none of its code is used.

## Release workflow (planned)

1. Add a section to `CHANGELOG.md`.
2. `tools/release.ps1 0.1.1` checks a clean tree, the changelog section and the tests, then tags and pushes.
3. The release workflow runs BigWigsMods/packager: GitHub release, CurseForge and Wago, game versions from the TOCs, notes from the newest changelog section. A missing token stops the run before anything is uploaded (taken from Umbra).

One-time setup by the author: create the CurseForge and Wago projects (IDs go into the TOCs), set `CF_API_KEY` and `WAGO_API_TOKEN` as repository secrets.

## Roadmap after 0.1

Small releases, each with a real change: manual order by dragging; compartment entries in the panel; highlighting newly found buttons; more languages; profiles.
