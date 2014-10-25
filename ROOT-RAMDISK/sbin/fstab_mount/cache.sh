#!/sbin/busybox sh

BB=/sbin/busybox

CACHE=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/cache | $BB grep "f2fs" | $BB wc -l)

if [ "${CACHE}" -eq "1" ]; then
	$BB mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/cache /cache -o seclabel,nosuid,nodev;
else
	$BB mount -t ext4 /dev/block/platform/msm_sdcc.1/by-name/cache /cache -o seclabel,nosuid,nodev,noauto_da_alloc,errors=continue;
fi;
