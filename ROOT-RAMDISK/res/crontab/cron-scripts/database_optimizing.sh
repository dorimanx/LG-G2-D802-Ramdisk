#!/sbin/busybox sh

(
	PROFILE=`cat /data/.dori/.active.profile`;
	. /data/.dori/${PROFILE}.profile;

	if [ "$cron_db_optimizing" == "on" ]; then
		while [ ! `cat /proc/loadavg | cut -c1-4` \< "3.50" ]; do
			echo "Waiting For CPU to cool down";
			sleep 30;
		done;

		for i in `find /data -iname "*.db"`; do 
			/system/xbin/sqlite3 $i 'VACUUM;';
			/system/xbin/sqlite3 $i 'REINDEX;';
		done;

		for i in `find /sdcard -iname "*.db"`; do
			/system/xbin/sqlite3 $i 'VACUUM;';
			/system/xbin/sqlite3 $i 'REINDEX;';
		done;

		date +%H:%M-%D-%Z > /data/crontab/cron-db-optimizing;
		echo "Done! DB Optimized" >> /data/crontab/cron-db-optimizing;
	fi;
)&

