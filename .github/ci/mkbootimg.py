#!/usr/bin/env python3
"""Write an Android boot image (header v0/v1) that holds only a kernel: no ramdisk, second stage or DTBO.

The SM-G398FN boots from such an image. With the header values of the stock boot.img (see build.sh) the
result is byte for byte what hardmode's kernel/repack_boot.py makes from the stock image.

Usage: mkbootimg.py --kernel Image --out boot.img --kernel-addr ADDR --tags-addr ADDR
                    [--header-version 1] [--pagesize 2048] [--os-version A.B.C] [--os-patch-level YYYY-MM]
                    [--board NAME] [--cmdline "..."]
"""
import argparse
import hashlib
import struct

HDR = struct.Struct("<8s10I16s512s32s1024s")  # fields up to extra_cmdline (v0 layout)
V1_TAIL = struct.Struct("<IQI")  # recovery_dtbo_size, recovery_dtbo_offset, header_size


def pad(data, page):
    return data + b"\0" * ((page - len(data) % page) % page)


def os_version(version, patch_level):
    if not version:
        return 0
    a, b, c = (int(x) for x in version.split("."))
    y, m = (int(x) for x in patch_level.split("-"))
    assert max(a, b, c) < 128 and 2000 <= y < 2128 and 1 <= m <= 12, "os version out of range"
    return (a << 14 | b << 7 | c) << 11 | (y - 2000) << 4 | m


def main():
    num = lambda s: int(s, 0)
    ap = argparse.ArgumentParser()
    ap.add_argument("--kernel", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--kernel-addr", type=num, required=True)
    ap.add_argument("--tags-addr", type=num, required=True)
    ap.add_argument("--header-version", type=int, choices=(0, 1), default=1)
    ap.add_argument("--pagesize", type=int, choices=(2048, 4096), default=2048)
    ap.add_argument("--os-version", default="")
    ap.add_argument("--os-patch-level", default="2000-01")
    ap.add_argument("--board", default="")
    ap.add_argument("--cmdline", default="")
    args = ap.parse_args()

    board = args.board.encode()
    cmdline = args.cmdline.encode()
    assert len(board) < 16, "board name too long"
    assert len(cmdline) < 512, "cmdline too long"

    kernel = open(args.kernel, "rb").read()

    # Same id computation as AOSP mkbootimg: sha1 over each section and its size.
    sha = hashlib.sha1()
    for blob in (kernel, b"", b"") + ((b"",) if args.header_version == 1 else ()):
        sha.update(blob)
        sha.update(struct.pack("<I", len(blob)))
    img_id = sha.digest().ljust(32, b"\0")

    # Ramdisk and second stage are empty, their load addresses stay 0 as in the stock image.
    header = HDR.pack(b"ANDROID!", len(kernel), args.kernel_addr, 0, 0, 0, 0, args.tags_addr,
                      args.pagesize, args.header_version, os_version(args.os_version, args.os_patch_level),
                      board, cmdline, img_id, b"")
    if args.header_version == 1:
        header += V1_TAIL.pack(0, 0, HDR.size + V1_TAIL.size)

    with open(args.out, "wb") as f:
        f.write(pad(header, args.pagesize))
        f.write(pad(kernel, args.pagesize))


if __name__ == "__main__":
    main()
