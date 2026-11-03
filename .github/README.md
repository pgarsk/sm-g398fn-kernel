# sm-g398fn-kernel

Linux 4.4.302 kernel for the **Samsung Galaxy XCover 4s (SM-G398FN)**, based on Samsung's source release, with security fixes and hardening.

## Origin

| Part | Source |
|---|---|
| Base | Samsung's kernel source package for the SM-G398FN, firmware CWF1 (4.4.177), from [opensource.samsung.com](https://opensource.samsung.com/) |
| 4.4.302 | Android Common Kernel `android-4.4-p`, merged in |
| CIP | about 400 CVE fixes from CIP `linux-4.4.y-st` |
| Own changes | hardening, security fixes, Mali, cpufreq |

[CHANGES](CHANGES) lists every change made to Samsung's source package, one line per commit with date and subject.

## Building

GCC 4.9 has to be in `toolchain/` (see below). With Samsung's defconfig:

```bash
export ARCH=arm64 PLATFORM_VERSION=11 ANDROID_MAJOR_VERSION=r
make exynos7885-xcover4s_defconfig
make -j"$(nproc)" HOSTCFLAGS=-fcommon KCFLAGS=-DCONFIG_ALLOW_OLD_GCC_ARM64
```

The kernel ends up in `arch/arm64/boot/Image`.

## License

GPL-2.0-only, like the Linux kernel itself; see [COPYING](../COPYING). This covers all changes in this repository too.

Not under the GPL:

- Firmware in `firmware/`: the files from the upstream kernel are listed with their licenses in `firmware/WHENCE`. The others (touchscreen, grip sensor, ACPM, FIVE trustlet) came with Samsung's source package without a license of their own and are unchanged here.
- `security/samsung/defex_lsm/defex_packed_rules.bin`: Samsung's precompiled Defex rules.

## Toolchain

The Makefile expects GCC 4.9 in `toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/`. Samsung's source package ships an AOSP prebuilt (GPLv3) there; it is not part of this repository. To fetch the matching AOSP build:

```bash
git init toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
cd toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
git fetch --depth 1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 a3a5fbd5089af2412289cdc5f61458388b2fb6c3
git checkout FETCH_HEAD
```

- Binaries: AOSP [`platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9`](https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+/a3a5fbd5089a), commit `a3a5fbd5089a` from October 2019, the last one that still has GCC. Samsung's copy is a different build from the same sources (identical `repo.prop`).
- Source: according to `repo.prop`, [`toolchain/gcc`](https://android.googlesource.com/toolchain/gcc/+/a9d5e6fb22fe3283eeecfb97211a12c072a7b469) `a9d5e6fb22fe3283eeecfb97211a12c072a7b469` and [`toolchain/binutils`](https://android.googlesource.com/toolchain/binutils/+/bd24d23f081feb4eb1438c56ace4ae91778ae6be) `bd24d23f081feb4eb1438c56ace4ae91778ae6be`, built with [`toolchain/build`](https://android.googlesource.com/toolchain/build/+/58be6006bb71abb97d7cdff7be3e73d55bbc22b8) `58be6006bb71abb97d7cdff7be3e73d55bbc22b8`. The other sources (gmp, mpfr, mpc, isl and more) are listed in `repo.prop` too and live under [android.googlesource.com/toolchain](https://android.googlesource.com/toolchain/).
