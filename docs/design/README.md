# Design

`mockup.html` is the interactive mockup that settles Buttonstone's look before any addon code is written (phase 2 of the [plan](../PLAN.md)). It is a browser approximation, not an in-game capture.

Open it through a local web server, so the browser loads the sprites and the font:

```bash
python -m http.server 8765 --bind 127.0.0.1 --directory docs/design
```

Then visit <http://127.0.0.1:8765/mockup.html>.

## Where the pictures come from

| Files | Source |
| --- | --- |
| `RetailPanel`, `ClassicPanel`, `RetailBar`, `ClassicBar`, `Toggle`, `ToggleRed`, `GoldThumb`, `SilverThumb`, `Rivet` | Soundstone's sprites (`docs/assets`), cut to the sub-rectangle `Soundstone/Assets.lua` gives each |
| `ActionNormal`, `ActionHover`, `ActionPressed`, `HeaderClose` | Soundstone, unchanged |
| `MinimapBackground`, `MinimapBorder`, `MinimapHover`, `Check`, `Gear`, `ControlRetail`, `ControlClassic`, `Arrow`, `Heart` | Hourstone's preview sprites (`docs/assets`), unchanged |
| `IconHourstone`, `IconSoundstone`, `IconUmbra` | The three addons' logos, trimmed and scaled to 128 px |
| `Logo` | Buttonstone's logo, written by `tools/assets.py` from `assets/logo.png` (see [ARTWORK.md](../ARTWORK.md)) |
| `fonts/Gelasio-Regular.ttf` | Hourstone's copy of Gelasio (SIL Open Font License, `fonts/Gelasio-OFL.txt`); stands in for the client font, as in Hourstone's preview |

Soundstone, Hourstone and Umbra are by the same author and MIT licensed. The minimap, Blizzard's buttons, the tooltips, Forever's frame and the placeholder addon icons are drawn in the page itself; Forever's frame follows the measurements in Hourstone's `docs/FOREVER-THEME.md`. In the game Buttonstone uses the client's own art there.
