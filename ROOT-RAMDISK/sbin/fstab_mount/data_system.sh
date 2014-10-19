#!/sbin/busybox sh

BB=/sbin/busybox

wait /dev/block/platform/msm_sdcc.1/by-name/system
SYSTEM=$($BB blkid /dev/block/mmcblk0p34 | $BB grep "f2fs" | $BB wc -l);

SYSTEM_TYPE=0;
DATA_TYPE=0;

if [ "${SYSTEM}" -eq "1" ]; then
	$BB mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/system /system -o seclabel,noauto_da_alloc,errors=continue;
	SYSTEM_TYPE=1;
fi;



wait /dev/block/platform/msm_sdcc.1/by-name/userdata
DATA=$($BB blkid /dev/block/mmcblk0p38 | $BB grep "f2fs" | $BB wc -l)

if [ "${DATA}" -eq "1" ]; then
	$BB mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/userdata /data -o seclabel,nosuid,nodev,noauto_da_alloc,errors=continue;
	DATA_TYPE=1;
fi;

$BB mount -o remount,rw /;

if [ "$SYSTEM_TYPE" -eq "1" ] && [ "$DATA_TYPE" -eq "1" ]; then
	$BB cp /sbin/fstab_mount/fstab_data_system.g2 /fstab.g2;
else if [ "$SYSTEM_TYPE" -eq "1" ] && [ "$DATA_TYPE" -eq "0" ]; then
	$BB cp /sbin/fstab_mount/fstab_system.g2 /fstab.g2;
else if [ "$SYSTEM_TYPE" -eq "0" ] && [ "$DATA_TYPE" -eq "1" ]; then
	$BB cp /sbin/fstab_mount/fstab_data.g2 /fstab.g2;
fi;

