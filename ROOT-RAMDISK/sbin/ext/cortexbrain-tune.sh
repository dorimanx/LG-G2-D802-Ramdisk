#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda
# Johnbeetee
# Alucard_24@xda

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT.
#
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

BB=/sbin/busybox

# change mode for /tmp/
ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep rw | wc -l)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	mount -o remount,rw /;
fi;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
PIDOFCORTEX=$$;
# (since we don't have the recovery source code I can't change the ".dori" dir, so just leave it there for history)
DATA_DIR=/data/.dori;

# ==============================================================
# INITIATE
# ==============================================================

# get values from profile
PROFILE=$(cat $DATA_DIR/.active.profile);
. "$DATA_DIR"/"$PROFILE".profile;

# ==============================================================
# I/O-TWEAKS
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local i="";

		local MMC=$(find /sys/block/mmc*);
		for i in $MMC; do
			echo "$scheduler" > "$i"/queue/scheduler;
			echo "0" > "$i"/queue/rotational;
			echo "0" > "$i"/queue/iostats;
			echo "1" > "$i"/queue/rq_affinity;
		done;

		# This controls how many requests may be allocated
		# in the block layer for read or write requests.
		# Note that the total allocated number may be twice
		# this amount, since it applies only to reads or writes
		# (not the accumulated sum).
		echo "128" > /sys/block/mmcblk0/queue/nr_requests; # default: 128

		# our storage is 16/32GB, best is 1024KB readahead
		# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
		echo "$read_ahead_kb" > /sys/block/mmcblk0/queue/read_ahead_kb;
		echo "$read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb;

		echo "45" > /proc/sys/fs/lease-break-time;

		log -p i -t "$FILE_NAME" "*** IO_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	IO_TWEAKS;
fi;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
	if [ "$cortexbrain_kernel_tweaks" == "on" ]; then
		echo "0" > /proc/sys/vm/oom_kill_allocating_task;
		echo "0" > /proc/sys/vm/panic_on_oom;
		echo "30" > /proc/sys/kernel/panic;

		log -p i -t "$FILE_NAME" "*** KERNEL_TWEAKS ***: enabled";
	else
		echo "kernel_tweaks disabled";
	fi;
	if [ "$cortexbrain_memory" == "on" ]; then
		echo "32 32" > /proc/sys/vm/lowmem_reserve_ratio;

		log -p i -t "$FILE_NAME" "*** MEMORY_TWEAKS ***: enabled";
	else
		echo "memory_tweaks disabled";
	fi;
}
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	KERNEL_TWEAKS;
fi;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
	if [ "$cortexbrain_system" == "on" ]; then
		setprop windowsmgr.max_events_per_sec 240;

		log -p i -t "$FILE_NAME" "*** SYSTEM_TWEAKS ***: enabled";
	else
		echo "system_tweaks disabled";
	fi;
}
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	SYSTEM_TWEAKS;
fi;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
	if [ "$cortexbrain_memory" == "on" ]; then
		echo "$dirty_background_ratio" > /proc/sys/vm/dirty_background_ratio; # default: 10
		echo "$dirty_ratio" > /proc/sys/vm/dirty_ratio; # default: 20
		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
		echo "1" > /proc/sys/vm/overcommit_memory; # default: 1
		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		echo "4096" > /proc/sys/vm/min_free_kbytes;

		log -p i -t "$FILE_NAME" "*** MEMORY_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	MEMORY_TWEAKS;
fi;

# if crond used, then give it root perent - if started by STweaks, then it will be killed in time
CROND_SAFETY()
{
	if [ "$crontab" == "on" ]; then
		pkill -f "crond";
		/res/crontab_service/service.sh;

		log -p i -t "$FILE_NAME" "*** CROND_SAFETY ***";

		return 1;
	else
		return 0;
	fi;
}

IO_SCHEDULER()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local state="$1";
		local sys_mmc0_scheduler_tmp="/sys/block/mmcblk0/queue/scheduler";
		local new_scheduler="";
		local tmp_scheduler=$(cat "$sys_mmc0_scheduler_tmp" | sed -n 's/^.*\[\([a-z|A-Z]*\)\].*/\1/p');

		if [ ! -e "$sys_mmc1_scheduler_tmp" ]; then
			sys_mmc1_scheduler_tmp="/dev/null";
		fi;

		local ext_tmp_scheduler=$(cat "$sys_mmc1_scheduler_tmp" | sed -n 's/^.*\[\([a-z|A-Z]*\)\].*/\1/p');

		if [ "$state" == "awake" ]; then
			new_scheduler="$scheduler";
			if [ "$tmp_scheduler" != "$scheduler" ]; then
				echo "$scheduler" > "$sys_mmc0_scheduler_tmp";
			fi;
		elif [ "$state" == "sleep" ]; then
			new_scheduler="$sleep_scheduler";
			if [ "$tmp_scheduler" != "$sleep_scheduler" ]; then
				echo "$sleep_scheduler" > "$sys_mmc0_scheduler_tmp";
			fi;
		fi;

		log -p i -t "$FILE_NAME" "*** IO_SCHEDULER: $state - $new_scheduler ***: done";
	else
		log -p i -t "$FILE_NAME" "*** Cortex IO_SCHEDULER: Disabled ***";
	fi;
}

GOV_TUNING()
{
	GOV_NAME=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor);

	if [ -e /cpugov/$GOV_NAME/sync_freq ]; then
		echo "1574400" > /cpugov/$GOV_NAME/sync_freq;
	fi;
	if [ -e /cpugov/$GOV_NAME/optimal_freq ]; then
		echo "1574400" > /cpugov/$GOV_NAME/optimal_freq;
	fi;
	if [ -e /cpugov/$GOV_NAME/optimal_max_freq ]; then
		echo "1574400" > /cpugov/$GOV_NAME/optimal_max_freq;
	fi;
}

CPU_CENTRAL_CONTROL()
{
	if [ "$cortexbrain_cpu" == "on" ]; then

		local state="$1";
		GOV_NAME=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor);

		if [ "$state" == "awake" ]; then
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			#GOV_TUNING;
		elif [ "$state" == "sleep" ]; then
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			if [ "$suspend_max_freq" -lt "2803200" ]; then
				echo "$suspend_max_freq" > /sys/kernel/msm_cpufreq_limit/suspend_max_freq;
			fi;
		fi;
		log -p i -t "$FILE_NAME" "*** CPU_CENTRAL_CONTROL max_freq:${cpu_max_freq} min_freq:${cpu_min_freq}***: done";
	else
		if [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)" -ge "729600" ]; then
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
		fi;
	fi;
}

HOTPLUG_CONTROL()
{
	if [ "$hotplug" == "default" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "0" ]; then
			echo "1" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
			/system/bin/stop mpdecision
			/system/bin/start mpdecision
			$BB renice -n -20 -p $(pgrep -f "/system/bin/start mpdecision");
		fi;
		if [ "$(ps | grep "mpdecision" | wc -l)" -lt "2" ]; then
			/system/bin/start mpdecision
			$BB renice -n -20 -p $(pgrep -f "/system/bin/start mpdecision");
		fi;
		if [ "$(ps | grep /system/bin/thermal-engine | wc -l)" -ge "1" ]; then
			$BB renice -n -20 -p $(pgrep -f "/system/bin/thermal-engine");
		fi;
	elif [ "$hotplug" == "msm_hotplug" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "0" ]; then
			echo "1" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ "$(ps | grep /system/bin/thermal-engine | wc -l)" -ge "1" ]; then
			$BB renice -n -20 -p $(pgrep -f "/system/bin/thermal-engine");
		fi;
	elif [ "$hotplug" == "intelli" ]; then
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "0" ]; then
			echo "1" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ "$(ps | grep /system/bin/thermal-engine | wc -l)" -ge "1" ]; then
			$BB renice -n -20 -p $(pgrep -f "/system/bin/thermal-engine");
		fi;
	elif [ "$hotplug" == "alucard" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "0" ]; then
			echo "1" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ "$(ps | grep /system/bin/thermal-engine | wc -l)" -ge "1" ]; then
			$BB renice -n -20 -p $(pgrep -f "/system/bin/thermal-engine");
		fi;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	IO_SCHEDULER "awake";
	CPU_CENTRAL_CONTROL "awake";
	HOTPLUG_CONTROL;
	log -p i -t "$FILE_NAME" "*** AWAKE_MODE - WAKEUP ***: done";
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off ...
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	CROND_SAFETY;
	IO_SCHEDULER "sleep";
	CPU_CENTRAL_CONTROL "sleep";

	log -p i -t "$FILE_NAME" "*** SLEEP mode ***";
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ] && [ "$(pgrep -f "/sbin/ext/cortexbrain-tune.sh" | wc -l)" -eq "2" ]; then
	(while true; do
		while [ "$(cat /sys/power/autosleep)" != "off" ]; do
			sleep "3";
		done;
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /sys/power/autosleep)" != "mem" ]; do
			sleep "3";
		done;
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" -eq "0" ]; then
		echo "Cortex background disabled!"
	else
		echo "Cortex background process already running!";
	fi;
fi;

# ==============================================================
# Logic Explanations
#
# This script will manipulate all the system / cpu / battery behavior
# Based on chosen STWEAKS profile+tweaks and based on SCREEN ON/OFF state.
#
# When User select battery/default profile all tuning will be toward battery save.
# But user loose performance -20% and get more stable system and more battery left.
#
# When user select performance profile, tuning will be to max performance on screen ON.
# When screen OFF all tuning switched to max power saving. as with battery profile,
# So user gets max performance and max battery save but only on screen OFF.
#
# This script change governors and tuning for them on the fly.
# Also switch on/off hotplug CPU core based on screen on/off.
# This script reset battery stats when battery is 100% charged.
# This script tune Network and System VM settings and ROM settings tuning.
# This script changing default MOUNT options and I/O tweaks for all flash disks and ZRAM.
#
# TODO: add more description, explanations & default vaules ...
#
