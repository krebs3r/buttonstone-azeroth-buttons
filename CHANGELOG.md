# Changelog

## 0.1.1 — 17 November 2026

- New name: **Buttonstone – Azeroth Minimap Buttons**. The addon list, the options window and the main button's tooltip show it; the addon folder, your settings and `/bst` stay as they are.

## 0.1.0 — 16 November 2026

- Gathers every LibDBIcon button and the buttons addons make themselves (such as Hourstone's, Soundstone's and Umbra's) into one panel; Blizzard's frames, map pins and protected frames are left alone.
- The panel: a grid sorted by name, 4 columns, opening towards the side with more room, closing shortly after the mouse leaves, Escape closes it. Uniform slots in Retail's gold or Classic's iron plates.
- The main button on the minimap rim, dragged along it, or detached with `/bst detach` and dragged anywhere; `/bst attach`, `/bst reset`, `/bst list`.
- A button given back (excluded) returns to its own place at once, without `/reload`.
- The options window, in the client's look: attach the main button to the minimap or place it freely, show Buttonstone in the minimap's addon list, columns and size in steps, direction, uniform slots, header and auto-close, and every button with a checkbox to exclude it; the list grows to twelve buttons before it scrolls. Opened by right-clicking the main button, by the panel's gear, from the minimap's addon list and with `/bst`.
- Retail and WoW: Forever show Buttonstone in Blizzard's addon list by the minimap clock: a click shows the buttons, a right-click the options.
- With another button collector active (MinimapButtonButton, MinimapButtonFrame), Buttonstone leaves the buttons to it and says so, instead of both pulling at them.
- WoW: Forever wears its own look: Blizzard's bronze window frame with the title in its strip and the gear as a red header button, the frame cut to its metal band without the header, and the action bar's icon frames around the slots. A piece the client lacks falls back to a flat look on its own.
- Foundation: one TOC per client family (Retail, Mists of Pandaria Classic, TBC Anniversary, Classic Era, WoW: Forever), saved settings with the approved defaults, `/buttonstone` and `/bst` (`version`, `help`), English and German.
