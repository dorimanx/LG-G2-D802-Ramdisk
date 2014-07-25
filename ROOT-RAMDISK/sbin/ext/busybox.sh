#!/sbin/busybox sh

BB=/sbin/busybox

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

# installe latest busybox to ROM
$BB cp /sbin/busybox /system/xbin/;
/system/xbin/busybox --install -s /system/xbin/
if [ -e /system/xbin/wget ]; then
	rm /system/xbin/wget;
fi;
if [ -e /system/wget/wget ]; then
	chmod 755 /system/wget/wget;
fi;
chmod 06755 /system/xbin/busybox;
chmod 06755 /system/xbin/su;
chmod 06755 /system/xbin/daemonsu;

$BB sh /sbin/ext/post-init.sh;

