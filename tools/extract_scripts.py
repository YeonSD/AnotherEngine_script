from pathlib import Path
import argparse
import hashlib
import re
import shutil
import zlib

from rubymarshal.reader import loads


def safe_name(value):
    if isinstance(value, bytes):
        text = value.decode("utf-8", "replace")
    else:
        text = str(value)
    text = text.strip() or "section"
    text = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", text)
    text = re.sub(r"\s+", " ", text)
    return text[:80]


def main():
    parser = argparse.ArgumentParser(description="Extract RGSS Scripts.rxdata into .rb files.")
    parser.add_argument("rxdata", type=Path)
    parser.add_argument("out_dir", type=Path)
    parser.add_argument("--clean", action="store_true")
    args = parser.parse_args()

    if args.clean and args.out_dir.exists():
        shutil.rmtree(args.out_dir)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    scripts = loads(args.rxdata.read_bytes())
    manifest = []
    used = set()
    for index, row in enumerate(scripts):
        section_id, name, compressed = row
        code = zlib.decompress(compressed)
        base = f"{index:03d}_{safe_name(name)}.rb"
        filename = base
        suffix = 1
        while filename.lower() in used:
            filename = f"{base[:-3]}_{suffix}.rb"
            suffix += 1
        used.add(filename.lower())
        (args.out_dir / filename).write_bytes(code)
        manifest.append(
            f"{index}\t{section_id}\t{safe_name(name)}\t{filename}\t{hashlib.sha256(code).hexdigest()}"
        )
    (args.out_dir / "manifest.tsv").write_text("\n".join(manifest) + "\n", encoding="utf-8")
    print(f"Extracted {len(scripts)} sections to {args.out_dir}")


if __name__ == "__main__":
    main()
