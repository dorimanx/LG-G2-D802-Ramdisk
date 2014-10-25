#!/sbin/busybox sh

BB=/sbin/busybox

SYSTEM=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/system | $BB grep "f2fs" | $BB wc -l);

if [ "${SYSTEM}" -eq "1" ]; then
	$BB mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/system /system -o seclabel;
else
	$BB mount -t ext4 /dev/block/platform/msm_sdcc.1/by-name/system /system -o seclabel,noauto_da_alloc,errors=continue;
fi;
