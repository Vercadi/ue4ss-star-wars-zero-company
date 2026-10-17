"""Reproduce the existing DLL patch on its exact official input. No installation."""
import argparse
from pathlib import Path
from common import patch_native, sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        output = patch_native(args.input.read_bytes())
        # Exclusive creation protects both the original DLL and existing outputs.
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("xb") as handle:
            handle.write(output)
        print(f"{sha(output)}  {args.output.name}")
    except (OSError, ValueError) as error:
        parser.exit(1, f"Refused: {error}\n")


if __name__ == "__main__":
    main()
