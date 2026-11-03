#!/bin/sh
# Strip everything an XCover 4s running a GSI does not need (attack surface reduction).
# Usage (inside a configured kernel tree, after hardening.sh): sh slim.sh
set -e
C="scripts/config --file .config"
off() { for o in "$@"; do $C -d "$o"; done; }

# HID: keep the generic driver (USB/Bluetooth keyboards, mice, gamepads still work), drop vendor quirk drivers
off HID_A4TECH HID_ACRUX HID_ACRUX_FF HID_APPLE HID_BELKIN HID_CHERRY HID_CHICONY HID_PRODIKEYS \
    HID_CYPRESS HID_DRAGONRISE HID_EMS_FF HID_ELECOM HID_EZKEY HID_HOLTEK HID_KEYTOUCH HID_KYE \
    HID_UCLOGIC HID_WALTOP HID_GYRATION HID_TWINHAN HID_KENSINGTON HID_LCPOWER HID_LOGITECH \
    HID_LOGITECH_DJ HID_LOGITECH_HIDPP HID_MAGICMOUSE HID_MICROSOFT HID_MONTEREY HID_NINTENDO \
    HID_NTRIG HID_ORTEK HID_PANTHERLORD HID_PETALYNX HID_PICOLCD HID_PRIMAX HID_ROCCAT HID_SAITEK \
    HID_SAMSUNG HID_SONY HID_SPEEDLINK HID_SUNPLUS HID_GREENASIA HID_SMARTJOYPLUS HID_SYNAPTICS_BT \
    HID_TIVO HID_TOPSEED HID_THRUSTMASTER HID_WACOM HID_WIIMOTE HID_ZEROPLUS HID_ZYDACRON HID_OVR \
    HID_MADCATZ USB_HIDDEV

# Input devices a phone never has
off INPUT_JOYSTICK JOYSTICK_XPAD INPUT_TABLET KEYBOARD_ATKBD INPUT_MOUSEDEV

# USB host: no USB network adapters, USB-serial, modems, printers, USB sound cards (OTG storage + HID stay)
off USB_NET_DRIVERS USB_USBNET USB_RTL8150 USB_RTL8152 USB_ACM USB_PRINTER USB_WDM USB_SERIAL \
    SND_USB SND_USB_AUDIO USB_DEBUG_DETAILED_LOG
# USB gadget: drop Samsung diag/SideSync/modem functions and MIDI (adb, MTP, PTP, tethering stay)
off USB_CONFIGFS_F_DM USB_CONFIGFS_F_CONN_GADGET USB_F_CONN_GADGET USB_CONFIGFS_F_MIDI USB_F_MIDI \
    USB_DUN_SUPPORT

# TV tuners and other media sub-drivers (camera, codecs, FM radio stay)
off MEDIA_SUBDRV_AUTOSELECT MEDIA_ATTACH MEDIA_TUNER
off $(sed -n 's/^CONFIG_\(MEDIA_TUNER_[A-Z0-9_]*\)=y/\1/p' .config)
off DVB_AU8522 DVB_AU8522_V4L DVB_TUNER_DIB0070 DVB_TUNER_DIB0090

# Legacy VPN (PPTP/L2TP was removed in Android 12) and unneeded tunnels
off PPP PPPOLAC PPPOPNS IPV6_SIT IPV6_MIP6 NET_KEY IP_PNP
# Netfilter connection-tracking helpers for old protocols (H.323 & co. have a long CVE history)
off NF_CONNTRACK_AMANDA NF_CONNTRACK_H323 NF_CONNTRACK_IRC NF_CONNTRACK_NETBIOS_NS NF_CONNTRACK_BROADCAST \
    NF_CONNTRACK_PPTP NF_CONNTRACK_SANE NF_CT_PROTO_DCCP NF_CT_PROTO_SCTP NF_CT_PROTO_UDPLITE \
    NF_CONNTRACK_PROC_COMPAT NETFILTER_XT_MATCH_SCTP NETFILTER_XT_MATCH_U32 NETFILTER_XT_MATCH_STRING \
    NETFILTER_XT_MATCH_TIME NETFILTER_XT_TARGET_TRACE
off TCP_CONG_BIC TCP_CONG_WESTWOOD TCP_CONG_HTCP
# Ethernet vendor menus (no wired NIC on a phone)
for v in AMD ARC BROADCOM EZCHIP HISILICON INTEL I825XX MARVELL MICREL MICROCHIP NATSEMI 8390 QUALCOMM \
         RENESAS ROCKER SAMSUNG SEEQ SMSC STMICRO SYNOPSYS VIA WIZNET; do off NET_VENDOR_$v; done
off NET_CADENCE

# Filesystems Android does not use (ext4, f2fs, vfat, Samsung exFAT, fuse stay)
off EXT2_FS EXT3_FS MSDOS_FS ECRYPT_FS BLK_DEV_RAM SDFAT_DBG_MSG SDFAT_STATISTICS

# Legacy crypto
off CRYPTO_ARC4 CRYPTO_DES CRYPTO_TWOFISH

off CGROUP_DEBUG SND_VERBOSE_PROCFS SND_SUPPORT_OLD_API
# No driver on this device produces device coredumps (DEV_COREDUMP is off); drop the mechanism too
off ALLOW_DEV_COREDUMP

# Round 2 -------------------------------------------------------------------
# Profilers, test frameworks and debug views (debugfs/sysfs/proc info leaks, no runtime function).
# Kept on because Samsung code does not build without them: SDFAT_DEBUG, F2FS_STAT_FS, ECT_DUMP,
# ION_EXYNOS_STAT_LOG, MMC_DW_DEBUG, MALI_EXYNOS_TRACE, SCSC_WIFILOGGER_DEBUGFS
off GATOR MALI_GATOR_SUPPORT MALI_KUTF MALI_DEBUG_SYS MALI_DEBUG_KERNEL_SYSFS \
    CMA_DEBUGFS ZSMALLOC_STAT ARM_EXYNOS_DEVFREQ_DEBUG \
    CMUCAL_DEBUG TOUCHSCREEN_DUMP_MODE SAMSUNG_LMKD_DEBUG TIMER_STATS \
    THERMAL_EMULATION
# Code for hardware this phone does not have (server SoCs, PS/2, wired Ethernet, foreign-arch XZ filters)
off COMMON_CLK_XGENE CAVIUM_ERRATUM_22375 CAVIUM_ERRATUM_23154 CAVIUM_ERRATUM_27456 SERIO SERIO_LIBPS2 \
    ETHERNET PHYLIB XZ_DEC_IA64 XZ_DEC_POWERPC XZ_DEC_SPARC XZ_DEC_X86 CRAMFS CPU_IDLE_GOV_LADDER \
    I2C_COMPAT RTC_INTF_PROC
# Legacy interfaces: uevent helper (classic root-exec vector), sysfs(2), 16-bit UID syscalls,
# /dev/keychord (dropped by Android 11 init), wireless extensions (nl80211 is used instead)
off UEVENT_HELPER SYSFS_SYSCALL UID16 INPUT_KEYCHORD CFG80211_WEXT
# Core dumps: Android never writes them (RLIMIT_CORE=0), they only help an attacker read process memory
off COREDUMP ELF_CORE
# Initramfs decompressors the boot image never needs (it has no ramdisk; gzip/lz4 stay as a fallback)
off RD_BZIP2 RD_LZMA RD_XZ RD_LZO
# Network features Android does not use: IPsec BEET mode, ip6ip6 tunnels, userspace packet queueing,
# /proc/net/nf_conntrack, the kernel LOG target
off INET_XFRM_MODE_BEET INET6_XFRM_MODE_BEET IPV6_TUNNEL NETFILTER_NETLINK_QUEUE NETFILTER_XT_TARGET_NFQUEUE \
    NF_CONNTRACK_PROCFS NETFILTER_XT_TARGET_LOG
# Samsung services that only talk to Samsung's own userspace (absent in a GSI): Knox network
# monitoring (hooks into the network stack), Knox Active Protection, Defex event monitor,
# factory self-test (NAD), memory deduplication and per-process reclaim knobs
off KNOX_NCM KNOX_KAP SECURITY_DSMS SEC_NAD SEC_NAD_API SEC_NAD_BALANCER SEC_SUPPORT_SECOND_NAD \
    KSM PROCESS_RECLAIM
