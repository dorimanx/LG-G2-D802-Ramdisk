#!/sbin/busybox sh

stop
sync
sync
mount -o remount,ro /system
mount -o remount,ro /cache
echo "rebooting to recovery now"
sleep 2;
reboot recovery

