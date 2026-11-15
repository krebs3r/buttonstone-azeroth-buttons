# Artwork

## The logo

`assets/logo.png` is the master: 1024 × 1024 RGBA, SHA-256 `d44841ed1d870085723fd9e6dfc08fa3fc7e6cf5ea39a7cb571ab34a71936d21`. It shows the **same teleportation stone** as Soundstone and Hourstone, with a 2 × 2 block of gold buttons overlapping its lower right, as the hourglass overlaps Hourstone's stone: many buttons gathered into one.

It was chosen by the author on 15 November 2026 from eight candidates (variant `grid`, candidate 2 of 4). It was generated with OpenAI's image API through `tools/generate_logo.py`:

| Setting | Value |
| --- | --- |
| Model | `gpt-image-2.6-flare` |
| Endpoint | image edits, with two references: Soundstone's `docs/curseforge/logo-400.png` and Hourstone's `docs/assets/Logo.png` |
| Size, quality, background | 1024 × 1024, high, transparent |

<details>
<summary>The prompt, verbatim</summary>

```text
Use case: addon logo for a World of Warcraft interface addon, third in a family.
Input image 1 is the Soundstone logo, input image 2 the Hourstone logo, both by the same author.
Draw the Buttonstone logo as their sibling: the SAME pale rounded grey/off-white teleportation
stone with the glowing cyan-blue spiral rune and the warm bronze mounting details, painted in
the same fantasy item style, the same light from the upper left and the same restrained gold
metal with soft bevel. The stone must look like the same object as in the references.
Output: one square image, the logo centered with about 8 percent transparent padding on every
side. Genuinely transparent background: no checkerboard, no backdrop, no frame, no plate,
no text, no letters, no watermark, no shadow outside the objects. A strong, simple silhouette
that still reads at 18 by 18 pixels on a minimap button: few, large shapes, no fine detail.

Composition, like the Hourstone logo with the stone on the left and the hourglass overlapping it:
the stone on the left, slightly tilted; overlapping its lower right, a compact 2 by 2 cluster of
four rounded-square gold-metal buttons, like small action buttons, each with a slightly darker
recessed face and a bright upper edge. The four buttons touch each other and read as one block.
```

</details>

`python tools/assets.py` builds everything else from the master. It trims the transparent margin to 3 % and writes:

- `Media/Logo.tga`: 256 × 256, uncompressed 32-bit BGRA with alpha, top-left origin, as Hourstone's textures. The addon uses it for the minimap button, the panel header, the options window and the addon list.
- `docs/curseforge/logo-400.png`: the CurseForge project logo.
- `docs/design/assets/Logo.png`: the mockup's copy.

## Sprites in Media/

The panel and slot sprites are not new art. They are copied byte for byte from the family, by the same author and MIT licensed:

| Files | Source |
| --- | --- |
| `RetailPanel.tga`, `ClassicPanel.tga`, `ActionNormal.tga`, `ActionHover.tga`, `ActionPressed.tga` | Soundstone's `Soundstone/Media/`, commit `ecb4109` |
| `Gear.tga` | Hourstone's `Hourstone/Media/`, commit `5a020bc` |

`Assets.lua` records the sub-rectangle each sprite fills, as `Soundstone/Assets.lua` does. The main button's disc, border and highlight are Blizzard's tracking-button textures (file IDs 136467, 136430 and 136477), referenced from the client and not redistributed.

On WoW: Forever the panel wears the client's own art, referenced by name and drawn by the client, never redistributed here: the `ButtonFrameTemplateNoPortrait` nine-slice and its `UI-Frame-Metal-*` atlases, the ground `Interface\FrameGeneral\UI-Background-Rock` and `_UI-Frame-TopTileStreaks`, Blizzard's `UIPanelButtonTemplate` with the gear `Interface\WorldMap\GEAR_64GREY`, and the icon frames `UI-HUD-ActionBar-IconFrame`, `-Down` and `-Mouseover`. Where a piece is missing, its flat stand-in is drawn in code with `Interface\Buttons\WHITE8X8`.

## Making new candidates

The brief: the family's stone, painted in the same style, plus Buttonstone's own gold element. The background is transparent, with no text, frame or plate and about 8 % padding. The silhouette has to read at 18 × 18 pixels, and the gold stays restrained and softly bevelled. Two compositions are in the script (`PROMPTS`): `grid` (the chosen one) and `orbit` (four small round buttons around the stone, as on a minimap's rim).

`tools/generate_logo.ps1` asks for the OpenAI key with hidden input. It keeps the key in its own process only, runs both variants and removes the key again when it ends:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\generate_logo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\generate_logo.ps1 -Count 2 -Variants grid
```

`tools/generate_logo.py` is the script underneath and reads the key from `OPENAI_API_KEY`. Never put the key into a file of this repository. Each call costs money on the key's account. The images and the prompt used land in `dist/logo/`, which Git ignores.

By default the script asks the API which image models the key can use and takes the newest `gpt-image` model. `--list-models` only lists them, and `--model` (or `$OPENAI_IMAGE_MODEL`) names one. `gpt-image-1` was withdrawn from the API in October 2026. `--prompt-file` sends a prompt of your own, and `--no-reference` sends the prompt without the two family logos. If a model rejects `background` or `quality`, the script tries once more without that parameter.
