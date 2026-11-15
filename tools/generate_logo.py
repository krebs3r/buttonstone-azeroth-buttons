#!/usr/bin/env python3
"""Generates logo candidates for Buttonstone with OpenAI's image API.

Set OPENAI_API_KEY in your environment first, never in a file of this repository:

    $env:OPENAI_API_KEY = "..."        # PowerShell, for this window only
    python tools/generate_logo.py --variant grid --count 4
    python tools/generate_logo.py --variant orbit --count 4

Candidates land in dist/logo/ (ignored by Git), each with the prompt it was made from.
Every call costs money on the key's account; --count sets how many images one call makes.

By default the Soundstone and Hourstone logos go along as references, so the stone is
the same object in all three logos. They are read from the sibling checkouts next to this
repository; without them the small copies in docs/design/assets are used. --no-reference
sends the prompt alone. --prompt-file sends a prompt of your own.

Standard library only. See docs/ARTWORK.md for the brief.
"""
import argparse
import base64
import datetime
import json
import mimetypes
import os
import re
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
API = "https://api.openai.com/v1/images"
MODELS = "https://api.openai.com/v1/models"
OUT = ROOT / "dist" / "logo"

REFERENCES = [
    ROOT.parent / "soundstone-azeroth-audio" / "docs" / "curseforge" / "logo-400.png",
    ROOT.parent / "hourstone-azeroth-hours" / "docs" / "assets" / "Logo.png",
]
FALLBACK_REFERENCES = [
    ROOT / "docs" / "design" / "assets" / "IconSoundstone.png",
    ROOT / "docs" / "design" / "assets" / "IconHourstone.png",
]

COMMON = """Use case: addon logo for a World of Warcraft interface addon, third in a family.
Input image 1 is the Soundstone logo, input image 2 the Hourstone logo, both by the same author.
Draw the Buttonstone logo as their sibling: the SAME pale rounded grey/off-white teleportation
stone with the glowing cyan-blue spiral rune and the warm bronze mounting details, painted in
the same fantasy item style, the same light from the upper left and the same restrained gold
metal with soft bevel. The stone must look like the same object as in the references.
Output: one square image, the logo centered with about 8 percent transparent padding on every
side. Genuinely transparent background: no checkerboard, no backdrop, no frame, no plate,
no text, no letters, no watermark, no shadow outside the objects. A strong, simple silhouette
that still reads at 18 by 18 pixels on a minimap button: few, large shapes, no fine detail.
"""

PROMPTS = {
    "grid": COMMON + """
Composition, like the Hourstone logo with the stone on the left and the hourglass overlapping it:
the stone on the left, slightly tilted; overlapping its lower right, a compact 2 by 2 cluster of
four rounded-square gold-metal buttons, like small action buttons, each with a slightly darker
recessed face and a bright upper edge. The four buttons touch each other and read as one block.
""",
    "orbit": COMMON + """
Composition: the stone in the center. Around it, four small round buttons with gold rims and dark
faces sit on an invisible circle, as addon buttons sit on the rim of a minimap, two on the left and
two on the right, slightly overlapping the stone's edge, as if the stone gathers them. Each small
button shows only a simple glowing blue dot, no symbols.
""",
}


def references(disabled):
    if disabled:
        return []
    found = [p for p in REFERENCES if p.is_file()]
    if len(found) == len(REFERENCES):
        return found
    return [p for p in FALLBACK_REFERENCES if p.is_file()]


def multipart(fields, files):
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in fields:
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
    for name, path in files:
        kind = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        head = f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"; filename="{path.name}"\r\nContent-Type: {kind}\r\n\r\n'
        parts.append(head.encode() + path.read_bytes() + b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


class ApiError(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.message = message


def call(url, key, body=None, content_type=None):
    headers = {"Authorization": f"Bearer {key}"}
    if content_type:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(url, data=body, method="GET" if body is None else "POST", headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=600) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        try:
            detail = json.loads(detail)["error"]["message"]
        except (ValueError, KeyError, TypeError):
            pass
        raise ApiError(error.code, detail) from None
    except urllib.error.URLError as error:
        sys.exit(f"The image API could not be reached: {error.reason}")


def version_of(model_id):
    match = re.match(r"gpt-image-(\d+(?:\.\d+)*)", model_id)
    return tuple(int(part) for part in match.group(1).split(".")) if match else ()


def image_models(key):
    data = call(MODELS, key).get("data", [])
    return sorted({m["id"] for m in data if "image" in m.get("id", "")})


def pick_model(ids):
    """The newest gpt-image model; a full model before a mini, the plain alias before a dated snapshot."""
    candidates = [i for i in ids if i.startswith("gpt-image-")]
    if not candidates:
        return None
    return max(candidates, key=lambda i: (version_of(i), "mini" not in i, -len(i), i))


def request_images(key, model, prompt, refs, args):
    fields = {"model": model, "prompt": prompt, "n": str(args.count), "size": args.size, "quality": args.quality}
    if not args.opaque:
        fields["background"] = "transparent"
    # Parameters a model may not take; dropped one at a time when the API names them.
    optional = ["background", "quality"]
    while True:
        try:
            if refs:
                body, content_type = multipart(list(fields.items()), [("image[]", p) for p in refs])
                return call(f"{API}/edits", key, body, content_type), fields
            payload = dict(fields, n=args.count)
            return call(f"{API}/generations", key, json.dumps(payload).encode(), "application/json"), fields
        except ApiError as error:
            dropped = next((name for name in optional if name in fields and name in error.message.lower()), None)
            if error.code != 400 or not dropped:
                raise
            print(f"{model} does not take '{dropped}'; trying again without it.")
            del fields[dropped]


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--variant", choices=sorted(PROMPTS), default="grid")
    parser.add_argument("--prompt-file", type=Path, help="a prompt of your own instead of a variant")
    parser.add_argument("--count", type=int, default=4, help="images per call (default 4)")
    parser.add_argument("--model", default=os.environ.get("OPENAI_IMAGE_MODEL", "auto"),
                        help="image model; 'auto' (default) takes the newest gpt-image model the key can use")
    parser.add_argument("--list-models", action="store_true", help="list the image models the key can use and stop")
    parser.add_argument("--quality", default="high", choices=["low", "medium", "high", "auto"])
    parser.add_argument("--size", default="1024x1024")
    parser.add_argument("--no-reference", action="store_true", help="send the prompt without the two family logos")
    parser.add_argument("--opaque", action="store_true", help="do not ask for a transparent background")
    args = parser.parse_args()

    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        sys.exit("OPENAI_API_KEY is not set. Set it in this terminal only; never write it into a file here.")
    if not 1 <= args.count <= 10:
        sys.exit("--count must be between 1 and 10.")

    try:
        model = args.model
        if args.list_models or model == "auto":
            ids = image_models(key)
            print("Image models for this key:", ", ".join(ids) or "none")
            if args.list_models:
                return
            model = pick_model(ids)
            if not model:
                sys.exit("No gpt-image model is available to this key; name one with --model.")
            print("Using", model)

        prompt = args.prompt_file.read_text(encoding="utf-8") if args.prompt_file else PROMPTS[args.variant]
        label = args.prompt_file.stem if args.prompt_file else args.variant
        refs = references(args.no_reference)
        if refs:
            print("References:", ", ".join(str(p.relative_to(ROOT.parent)) for p in refs))
        result, fields = request_images(key, model, prompt, refs, args)
    except ApiError as error:
        sys.exit(f"The image API refused the request ({error.code}): {error.message}")

    OUT.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    saved = []
    for index, item in enumerate(result.get("data", []), 1):
        if item.get("b64_json"):
            data = base64.b64decode(item["b64_json"])
        elif item.get("url"):
            with urllib.request.urlopen(item["url"], timeout=120) as response:
                data = response.read()
        else:
            continue
        path = OUT / f"{stamp}-{label}-{index}.png"
        path.write_bytes(data)
        saved.append(path)
    settings = "\n".join(f"{name}: {value}" for name, value in fields.items() if name != "prompt")
    (OUT / f"{stamp}-{label}.prompt.txt").write_text(
        f"{settings}\nreferences: {', '.join(p.name for p in refs) or 'none'}\n\n{prompt}", encoding="utf-8")

    if not saved:
        sys.exit("The API answered without an image.")
    for path in saved:
        print(path.relative_to(ROOT))


if __name__ == "__main__":
    main()
