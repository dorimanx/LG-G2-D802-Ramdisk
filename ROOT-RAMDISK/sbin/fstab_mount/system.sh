#!/sbin/busybox sh

wait /dev/block/platform/msm_sdcc.1/by-name/system
SYSTEM=$(/sbin/busybox blkid /dev/block/mmcblk0p34 | /sbin/busybox grep "f2fs");

if [ "${SYSTEM}" != "" ]; then
	/sbin/busybox mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/system /system -o seclabel,noauto_da_alloc,errors=continue;
else
	/sbin/busybox mount -t ext4 /dev/block/platform/msm_sdcc.1/by-name/system /system -o seclabel,noauto_da_alloc,errors=continue;
fi;
