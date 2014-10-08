#!/sbin/busybox sh

(
	PROFILE=`cat /data/.dori/.active.profile`;
	. /data/.dori/${PROFILE}.profile;

	if [ "$cron_fstrim" == "on" ]; then
		/sbin/busybox fstrim /system
		/sbin/busybox fstrim /data
		date +%H:%M-%D-%Z > /data/crontab/cron-fstrim;
		echo "FS Trimmed" >> /data/crontab/cron-fstrim;
	fi;
)&

