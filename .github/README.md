# hardmode-kernel

Kernel für das **Samsung Galaxy XCover 4s (SM-G398FN)** aus dem Projekt [hardmode](https://github.com/pgarsk/hardmode): Linux 4.4.302, gehärtet und verschlankt. Gebaut wird er dort mit `scripts/kernel.sh`, das auch die Konfiguration setzt und das Boot-Image packt.

## Herkunft

| Stand | Quelle |
|---|---|
| Basis | Samsungs Kernel-Quellpaket für das SM-G398FN, Firmware CWF1 (4.4.177), von [opensource.samsung.com](https://opensource.samsung.com/) |
| 4.4.302 | Android Common Kernel `android-4.4-p`, hineingemergt |
| CIP | rund 400 CVE-Fixes aus CIP `linux-4.4.y-st` |
| hardmode | eigene Commits: Härtung, Sicherheitsfixes, Mali, cpufreq |

Der erste Commit (`50a0a93a0`) ist Samsungs Quellpaket. Jede Änderung danach ist ein eigener Commit mit Datum, `git log 50a0a93a0..` zeigt alle.

Der einzige Branch ist `main`, er läuft auf dem Gerät. Frühere Branches sind als Tags erhalten:

- `archive/hardmode`: kleinerer Stand ohne die CIP-Serie
- `archive/clang-clean`: Versuch mit Clang, bootloopt

## Lizenz

GPL-2.0-only wie der Linux-Kernel selbst, siehe [COPYING](../COPYING). Das gilt auch für alle Änderungen in diesem Repo.

Nicht unter der GPL stehen:

- Firmware in `firmware/`: Die Dateien aus dem Upstream-Kernel stehen mit ihren Lizenzen in `firmware/WHENCE`. Die übrigen (Touchscreen, Grip-Sensor, ACPM, FIVE-Trustlet) hat Samsung seinem Quellpaket ohne eigene Lizenz beigelegt; sie liegen hier unverändert.
- `security/samsung/defex_lsm/defex_packed_rules.bin`: Samsungs vorkompilierte Defex-Regeln.

## Toolchain

Das Makefile erwartet GCC 4.9 unter `toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/`. Samsung hat dafür ein AOSP-Prebuilt (GPLv3) ins Quellpaket gelegt. Es liegt nicht mehr in diesem Repo, nur ältere Commits enthalten es noch.

- Binärdateien: AOSP [`platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9`](https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+/a3a5fbd5089a), Commit `a3a5fbd5089a` vom Oktober 2019, der letzte Stand mit GCC. Samsungs Kopie ist ein anderer Build aus denselben Quellständen (gleiche `repo.prop`).
- Quellcode: laut `repo.prop` [`toolchain/gcc`](https://android.googlesource.com/toolchain/gcc/+/a9d5e6fb22fe3283eeecfb97211a12c072a7b469) `a9d5e6fb22fe3283eeecfb97211a12c072a7b469` und [`toolchain/binutils`](https://android.googlesource.com/toolchain/binutils/+/bd24d23f081feb4eb1438c56ace4ae91778ae6be) `bd24d23f081feb4eb1438c56ace4ae91778ae6be`, gebaut mit [`toolchain/build`](https://android.googlesource.com/toolchain/build/+/58be6006bb71abb97d7cdff7be3e73d55bbc22b8) `58be6006bb71abb97d7cdff7be3e73d55bbc22b8`. Die übrigen Quellstände (gmp, mpfr, mpc, isl und weitere) stehen ebenfalls in `repo.prop` und liegen unter [android.googlesource.com/toolchain](https://android.googlesource.com/toolchain/).
