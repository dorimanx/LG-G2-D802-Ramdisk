#!/sbin/busybox sh

# Created By Dorimanx and Dairinin

ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep rw | wc -l)
SYSTEM_MOUNT=$(mount | grep system | cut -c69-70 | grep rw | wc -l)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$SYSTEM_MOUNT" -eq "0" ]; then
	$BB mount -o remount,rw /system;
fi;

# allow custom user jobs
if [ ! -e /data/crontab/root ]; then
	mkdir /data/crontab/;
	/sbin/cp /res/crontab_service/cron-root /data/crontab/root;
	chown 0:0 /data/crontab/root;
	chmod 777 /data/crontab/root;
fi;

if [ ! -e /var/spool/cron/crontabs/root ]; then
	mkdir -p /var/spool/cron/crontabs/;
	/sbin/cp -a /data/crontab/root /var/spool/cron/crontabs/;
	chown 0:0 /var/spool/cron/crontabs/*;
	chmod 777 /var/spool/cron/crontabs/*;
fi;
echo "root:x:0:0::/var/spool/cron/crontabs:/sbin/sh" > /etc/passwd;

# set timezone
TZ=UTC

# set cron timezone
export TZ

#Set Permissions to scripts
chown 0:0 /data/crontab/cron-scripts/*;
chmod 777 /data/crontab/cron-scripts/*;

# use /var/spool/cron/crontabs/ call the crontab file "root"
if [ -e /system/xbin/busybox ] || [ -e /system/bin/busybox ]; then
		nohup /sbin/busybox crond -c /var/spool/cron/crontabs/
fi;
