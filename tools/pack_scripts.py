from pathlib import Path
import argparse
import zlib

from rubymarshal.reader import loads
from rubymarshal.writer import writes


def main():
    parser = argparse.ArgumentParser(description="Pack edited .rb files back into Scripts.rxdata using a source rxdata layout.")
    parser.add_argument("source_rxdata", type=Path)
    parser.add_argument("scripts_dir", type=Path)
    parser.add_argument("out_rxdata", type=Path)
    args = parser.parse_args()

    scripts = loads(args.source_rxdata.read_bytes())
    manifest_path = args.scripts_dir / "manifest.tsv"
    entries = []
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        index, _section_id, _name, filename, *_rest = line.split("\t")
        entries.append((int(index), filename))

    for index, filename in entries:
        code = (args.scripts_dir / filename).read_bytes()
        scripts[index][2] = zlib.compress(code)

    args.out_rxdata.parent.mkdir(parents=True, exist_ok=True)
    args.out_rxdata.write_bytes(writes(scripts))
    print(f"Packed {len(entries)} sections to {args.out_rxdata}")


if __name__ == "__main__":
    main()
