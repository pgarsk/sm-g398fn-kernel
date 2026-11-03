#!/bin/sh
# Apply the GSI + hardening config on top of exynos7885-xcover4s_defconfig.
# Usage (inside a configured kernel tree): sh hardening.sh
set -e
C="scripts/config --file .config"

# Samsung features that block GSIs (DEFEX kills GSI init services, FIVE/PROCA need Samsung userspace)
$C -d SECURITY_DEFEX -d PROCA -d FIVE -d FIVE_TEE_DRIVER

# SELinux: always enforcing, cannot be switched off at runtime or via the cmdline
$C -d SECURITY_SELINUX_DEVELOP -d SECURITY_SELINUX_BOOTPARAM

# Cortex-A53/A73 are ARMv8.0 without hardware PAN: emulate it so the kernel
# cannot accidentally dereference user memory (blocks ret2usr exploits)
$C -e ARM64_SW_TTBR0_PAN

# No loadable modules: the stock vendor ships none, and it removes the rootkit-LKM path
$C -d MODULES

# Information leaks
$C -e SECURITY_DMESG_RESTRICT -d KALLSYMS_ALL -d MAGIC_SYSRQ

# Cheap memory-corruption detectors that turn exploit primitives into a BUG()
$C -e DEBUG_LIST -e BUG_ON_DATA_CORRUPTION -e SCHED_STACK_END_CHECK
# SYN floods on an open port (adb over Wi-Fi, a hotspot) no longer fill the backlog
$C -e SYN_COOKIES
# Free-list pointers inside freed slab objects are XORed with a per-cache secret and their address
# (backport in the kernel tree), so overwriting one no longer hands out an attacker-chosen address
$C -e SLAB_FREELIST_HARDENED

# ptrace only of descendants (Yama scope 1). debuggerd's handler opens itself to crash_dump with
# PR_SET_PTRACER_ANY, so tombstones still work
$C -e SECURITY_YAMA
# Oops = panic, a fuller 32 KiB mmap floor and full mmap ASLR from the first process on (init sets
# the same at runtime; this also covers the time before it)
$C -e PANIC_ON_OOPS --set-val DEFAULT_MMAP_MIN_ADDR 32768 \
   --set-val ARCH_MMAP_RND_BITS 24 --set-val ARCH_MMAP_RND_COMPAT_BITS 16
$C -e DEBUG_CREDENTIALS -e DEBUG_NOTIFIERS

# Samsung debug interfaces that leak to any reader: /proc/tima_debug_log (2 MiB of the hypervisor
# log region, world-readable), /proc/last_kmsg (the previous boot's kernel log, world-readable),
# the deleted-file path log (PROC_DLOG)
$C -d TIMA_LOG -d SEC_DEBUG_LAST_KMSG -d PROC_DLOG
# The retail "user crash key" (Vol-Down + Power x9, Vol-Up x5, Power x3, from the lockscreen) panics
# into upload mode. It is armed exactly when force upload is off (sec_debug_enter_upload() == 0), so
# FORCE_UPLOAD stays: without it the panic path would dump the secure region on this debug level
$C -d SEC_UPLOAD -d EXYNOS_SNAPSHOT_CRASH_KEY
# Unused protocol and leftovers of FIVE: Phonet (the modem uses its own IPC), the integrity
# subsystem, asymmetric keys (no module signing without modules), ANT (no HAL in the vendor)
$C -d PHONET -d INTEGRITY -d ASYMMETRIC_KEY_TYPE -d SCSC_ANT

$C --set-str LOCALVERSION "-hardened"
