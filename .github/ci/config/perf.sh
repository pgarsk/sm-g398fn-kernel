#!/bin/sh
# Performance tuning for the XCover 4s kernel (run after hardening.sh and slim.sh).
set -e
C="scripts/config --file .config"

# Scheduler statistics cost on every enqueue, dequeue and wakeup (no static key in 4.4). SCHED_DEBUG
# stays: Android's init writes sched_latency_ns and friends, which only exist with it, and
# kernel/panic.c calls sysrq_sched_debug_show() unconditionally
$C -d SCHEDSTATS

# RT_GROUP_SCHED stays: Samsung's HMP/RT load tracking does not build without it. Its hazard (child
# cpuctl groups have rt_runtime_us 0) does not hit here: the API 30 task profiles leave every task in
# the cpuctl root, which has the 950 ms budget

# ARMv8 CRC32 instructions for ext4's journal_checksum (crc32c on every commit); checks the CPU
# feature at init. (GHASH_ARM64_CE does not build here: Samsung changed kernel_neon_begin())
$C -e CRYPTO_CRC32_ARM64

# exynos-snapshot logs every context switch, IRQ and hrtimer into its ring buffer; Samsung's own
# switch turns that off at debug level 0 (retail: sec_debug.level=0). Per-IRQ/tasklet dump summary
# logging goes too
$C -e SEC_DEBUG_SNAPSHOT_DISABLE -d SEC_DUMP_SUMMARY

# Deadline I/O scheduler available next to CFQ (default unchanged until measured)
$C -e IOSCHED_DEADLINE

# -O2 instead of -Os is not used: Samsung's global -Werror trips over GCC 4.9's maybe-uninitialized
# false positives at -O2, and whether such a kernel boots here is untested
