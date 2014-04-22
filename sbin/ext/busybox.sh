#!/sbin/busybox sh

BB=/sbin/busybox

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

# installe latest busybox to ROM
$BB cp /sbin/busybox /system/xbin/;
if [ -e /system/xbin/su ]; then
	$BB mv /system/xbin/su /system/
fi;
if [ -e /system/xbin/daemonsu ]; then
	$BB cp /system/xbin/daemonsu /system/;
fi;

/system/xbin/busybox --install -s /system/xbin/
chmod 06755 /system/xbin/busybox;

if [ -e /system/su ]; then
	$BB mv /system/su /system/xbin/;
	chmod 06755 /system/xbin/su;
fi;
if [ -e /system/daemonsu ]; then
	$BB mv /system/daemonsu /system/xbin/daemonsu;
	chmod 06755 /system/xbin/daemonsu;
fi;

$BB sh /sbin/ext/post-init.sh;

