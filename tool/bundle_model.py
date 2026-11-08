#!/usr/bin/env python3
"""Download an ASR model (plus the VAD) into assets/bundled_models/ for a
"built-in model" APK build.

Usage: python3 tool/bundle_model.py <asr-model-id> [<asr-model-id> ...]

Files are taken from assets/config/model_config.json, verified against their
sha256, and stored flat as <id>__<version>__<name> (Flutter asset directories
are not recursive). manifest.json maps the app's relative path
models/<id>/<version>/<name> to the asset, which BundledModelStore reads.
"""

import hashlib
import json
import shutil
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "assets" / "config" / "model_config.json"
OUT = ROOT / "assets" / "bundled_models"


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def fetch(file: dict, dest: Path) -> None:
    if dest.exists() and dest.stat().st_size == file["size"] and sha256_of(dest) == file["sha256"]:
        print(f"  {dest.name}: already present")
        return
    for url in file["urls"]:
        print(f"  {dest.name} <- {url}")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "VisioIridis-CI"})
            with urllib.request.urlopen(req, timeout=120) as resp, dest.open("wb") as out:
                shutil.copyfileobj(resp, out, 1 << 20)
        except Exception as e:  # try the next mirror
            print(f"    failed: {e}")
            continue
        if dest.stat().st_size == file["size"] and sha256_of(dest) == file["sha256"]:
            return
        print("    size/sha256 mismatch")
    dest.unlink(missing_ok=True)
    sys.exit(f"could not download {file['name']}")


def main(model_ids: list[str]) -> None:
    if not model_ids:
        sys.exit(__doc__)
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    by_id = {m["id"]: m for m in config["asrModels"]}
    missing = [i for i in model_ids if i not in by_id]
    if missing:
        sys.exit(f"unknown model id(s): {missing}; known: {sorted(by_id)}")

    OUT.mkdir(parents=True, exist_ok=True)
    files = {}
    for model in [config["vad"], *(by_id[i] for i in model_ids)]:
        print(f"{model['id']} ({model['version']})")
        for file in model["files"]:
            asset_name = f"{model['id']}__{model['version']}__{file['name']}"
            fetch(file, OUT / asset_name)
            rel = f"models/{model['id']}/{model['version']}/{file['name']}"
            files[rel] = {"asset": f"assets/bundled_models/{asset_name}", "size": file["size"]}

    manifest = {"models": model_ids, "files": files}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    total = sum(f["size"] for f in files.values())
    print(f"bundled {len(files)} files, {total / 1e6:.1f} MB")


if __name__ == "__main__":
    main(sys.argv[1:])
