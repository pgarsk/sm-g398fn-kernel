#!/bin/bash
# Build the kernel and pack it into flashable images for the XCover 4s (SM-G398FN), with the same steps
# as scripts/kernel.sh in hardmode. Used by .github/workflows/release.yml, runs locally as well.
# Usage: .github/ci/build.sh [output dir]         (default: out/ in the repo root)
# Environment: NAME (file name stem of the Odin package), BIG_MAX_FREQ, JOBS
set -euo pipefail
mkdir -p "${1:-$(dirname "$0")/../../out}"
OUT=$(cd "${1:-$(dirname "$0")/../../out}" && pwd)
cd "$(dirname "$0")/../.."
CI=.github/ci
NAME=${NAME:-SM-G398FN-$(git rev-parse --short=12 HEAD)}
BIG_MAX_FREQ=${BIG_MAX_FREQ:-0}  # big cluster limit in kHz, 0 = stock; see config.sh in hardmode before raising it
JOBS=${JOBS:-$(nproc)}

# GCC 4.9 from AOSP (see .github/README.md), fetched by commit so git checks the content. cc1, as and ld
# are byte-identical to Samsung's copy; only the Python wrapper in front of gcc/g++ differs: AOSP's wants
# Python 2 and sleeps 3 s per call, Samsung's runs under python3 without the sleep. Patch it the same way.
# An existing toolchain/ (e.g. Samsung's copy) is used as is.
TC=toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
TC_URL=https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
TC_REV=a3a5fbd5089af2412289cdc5f61458388b2fb6c3
if [ ! -x "$TC/bin/aarch64-linux-android-gcc" ]; then
    rm -rf "$TC" "$TC.part"
    mkdir -p "$TC.part"
    git -C "$TC.part" init -q
    for try in 1 2 3; do  # googlesource throttles now and then
        git -C "$TC.part" fetch -q --depth 1 "$TC_URL" "$TC_REV" && break
        [ $try = 3 ] && exit 1
        sleep 30
    done
    git -C "$TC.part" checkout -q FETCH_HEAD
    sed -i -e '1s|^#!/usr/bin/python$|#!/usr/bin/env python3|' -e '/^import time$/d' -e '/^ *time\.sleep(3)$/d' \
        "$TC.part/bin/aarch64-linux-android-gcc" "$TC.part/bin/aarch64-linux-android-g++"
    mv "$TC.part" "$TC"
fi

export PLATFORM_VERSION=11 ANDROID_MAJOR_VERSION=r ARCH=arm64
MAKE="make -j$JOBS HOSTCFLAGS=-fcommon KCFLAGS=-DCONFIG_ALLOW_OLD_GCC_ARM64"

# Config as hardmode builds it: Samsung's defconfig plus the GSI/hardening, slimming and performance
# changes. config/*.sh are copies of kernel/*.sh in hardmode (as of b1f4945); keep them in step.
rm -f arch/arm64/boot/Image  # never pack a stale one
$MAKE -s exynos7885-xcover4s_defconfig
sh $CI/config/hardening.sh
sh $CI/config/slim.sh
sh $CI/config/perf.sh
scripts/config --file .config --set-val HARDMODE_BIG_MAX_FREQ "$BIG_MAX_FREQ"
$MAKE -s olddefconfig
$MAKE

# Boot image with the header of the stock one (G398FNXXSJCWF1): header v1, kernel only, no ramdisk or DTB
python3 -I $CI/mkbootimg.py --kernel arch/arm64/boot/Image --out "$OUT/boot.img" \
    --header-version 1 --pagesize 2048 --kernel-addr 0x10008000 --tags-addr 0x10000100 \
    --os-version 11.0.0 --os-patch-level 2023-07 --board SRPSD03B019KU \
    --cmdline "androidboot.selinux=permissive androidboot.selinux=permissive"
cp .config "$OUT/kernel.config"

# Odin package for the AP slot: tar with boot.img plus the MD5 trailer Odin checks
epoch=$(git log -1 --format=%ct)
cd "$OUT"
tar -H ustar --owner=0 --group=0 --numeric-owner --mtime="@$epoch" -cf "$NAME-AP.tar" boot.img
md5sum -t "$NAME-AP.tar" >> "$NAME-AP.tar"
mv "$NAME-AP.tar" "$NAME-AP.tar.md5"
sha256sum boot.img "$NAME-AP.tar.md5" kernel.config > SHA256SUMS
cat SHA256SUMS
