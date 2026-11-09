#!/usr/bin/env python3
"""Build a dependency-free 1.44 MiB BIOS floppy image using NASM."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build"
IMAGE_SIZE = 1_474_560
SECTOR_SIZE = 512
KERNEL_SECTORS = 17
KERNEL_LIMIT = SECTOR_SIZE * KERNEL_SECTORS


def create_image(boot: bytes, kernel: bytes) -> bytes:
    if len(boot) != SECTOR_SIZE:
        raise ValueError(f"boot sector must be exactly {SECTOR_SIZE} bytes")
    if boot[510:512] != b"\x55\xaa":
        raise ValueError("boot sector is missing the 0x55AA signature")
    if len(kernel) > KERNEL_LIMIT:
        raise ValueError(
            f"kernel is {len(kernel)} bytes; maximum is {KERNEL_LIMIT} bytes"
        )

    image = bytearray(IMAGE_SIZE)
    image[:SECTOR_SIZE] = boot
    image[SECTOR_SIZE : SECTOR_SIZE + len(kernel)] = kernel
    return bytes(image)


def main() -> int:
    nasm = shutil.which("nasm")
    if nasm is None:
        print(
            "NASM was not found. Install NASM 2.15+ and add it to PATH.",
            file=sys.stderr,
        )
        return 2

    BUILD_DIR.mkdir(exist_ok=True)
    boot_path = BUILD_DIR / "boot.bin"
    kernel_path = BUILD_DIR / "kernel.bin"
    image_path = BUILD_DIR / "oedge-os.img"

    commands = [
        [nasm, "-f", "bin", "-o", str(boot_path), str(ROOT / "boot" / "boot.asm")],
        [nasm, "-f", "bin", "-o", str(kernel_path), str(ROOT / "kernel" / "kernel.asm")],
    ]
    for command in commands:
        result = subprocess.run(command, cwd=ROOT, check=False)
        if result.returncode:
            return result.returncode

    try:
        image = create_image(boot_path.read_bytes(), kernel_path.read_bytes())
    except (OSError, ValueError) as error:
        print(f"Could not create disk image: {error}", file=sys.stderr)
        return 1

    image_path.write_bytes(image)
    print(f"Built {image_path.relative_to(ROOT)} ({len(image)} bytes)")
    print(f"Kernel: {kernel_path.stat().st_size} / {KERNEL_LIMIT} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
