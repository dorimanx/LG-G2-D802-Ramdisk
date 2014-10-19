#!/sbin/busybox sh

wait /dev/block/platform/msm_sdcc.1/by-name/cache
CACHE=$(/sbin/busybox blkid /dev/block/mmcblk0p35 | /sbin/busybox grep "f2fs")

if [ "${CACHE}" != "" ]; then
	/sbin/busybox mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/cache /cache -o seclabel,nosuid,nodev,noauto_da_alloc,errors=continue
else
	/sbin/busybox mount -t ext4 /dev/block/platform/msm_sdcc.1/by-name/cache /cache -o seclabel,nosuid,nodev,noauto_da_alloc,errors=continue;
fi;
