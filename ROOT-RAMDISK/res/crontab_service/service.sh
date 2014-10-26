#!/sbin/busybox sh

# Created By Dorimanx and Dairinin

BB=/sbin/busybox

ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep rw | wc -l)
SYSTEM_MOUNT=$(mount | grep system | cut -c69-70 | grep rw | wc -l)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$SYSTEM_MOUNT" -eq "0" ]; then
	$BB mount -o remount,rw /system;
fi;

$BB cp -a /res/crontab_service/cron-root /data/crontab/root;
chown 0:0 /data/crontab/root;
chmod 777 /data/crontab/root;
mkdir -p /var/spool/cron/crontabs/;
$BB cp -a /data/crontab/root /var/spool/cron/crontabs/;

chown 0:0 /var/spool/cron/crontabs/*;
chmod 777 /var/spool/cron/crontabs/*;
echo "root:x:0:0::/var/spool/cron/crontabs:/sbin/sh" > /system/etc/passwd;

# set timezone
TZ=UTC

# set cron timezone
export TZ

#Set Permissions to scripts
chown 0:0 /data/crontab/cron-scripts/*;
chmod 777 /data/crontab/cron-scripts/*;

if [ "$(pgrep -f crond | wc -l)" -ge "1" ]; then
	pkill -f "crond";
fi;

# use /var/spool/cron/crontabs/ call the crontab file "root"
$BB nohup $BB crond -f -c /var/spool/cron/crontabs/ &

$BB sh /res/crontab_service/dm_job.sh "3:00" "/sbin/busybox sh /data/crontab/cron-scripts/database_optimizing.sh"
$BB sh /res/crontab_service/dm_job.sh "4:00" "/sbin/busybox sh /data/crontab/cron-scripts/clear-file-cache.sh"
$BB sh /res/crontab_service/dm_job.sh "4:50" "/sbin/busybox sh /data/crontab/cron-scripts/zipalign.sh"
$BB sh /res/crontab_service/dm_job.sh "6:00" "/sbin/busybox sh /data/crontab/cron-scripts/fstrim.sh"
