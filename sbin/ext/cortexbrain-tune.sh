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

# change mode for /tmp/
mount -o remount,rw /;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
PIDOFCORTEX=$$;
# (since we don't have the recovery source code I can't change the ".dori" dir, so just leave it there for history)
DATA_DIR=/data/.dori;
WAS_IN_SLEEP_MODE=1;
NOW_CALL_STATE=0;
TELE_DATA=init;

# ==============================================================
# INITIATE
# ==============================================================

# get values from profile
PROFILE=$(cat $DATA_DIR/.active.profile);
. "$DATA_DIR"/"$PROFILE".profile;

# check if dumpsys exist in ROM
if [ -e /system/bin/dumpsys ]; then
	DUMPSYS_STATE=1;
else
	DUMPSYS_STATE=0;
fi;

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
		echo "$cortexbrain_read_ahead_kb" > /sys/block/mmcblk0/queue/read_ahead_kb;

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

CPU_GOV_TWEAKS()
{
	if [ "$cortexbrain_cpu" == "on" ]; then
		local SYSTEM_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor);

		local sampling_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_rate";
		if [ ! -e "$sampling_rate_tmp" ]; then
			sampling_rate_tmp="/dev/null";
		fi;

		local up_threshold_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold";
		if [ ! -e "$up_threshold_tmp" ]; then
			up_threshold_tmp="/dev/null";
		fi;

		local high_grid_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/high_grid_load";
		if [ ! -e "$high_grid_load_tmp" ]; then
			high_grid_load_tmp="/dev/null";
		fi;

		local high_grid_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/high_grid_step";
		if [ ! -e "$high_grid_step_tmp" ]; then
			high_grid_step_tmp="/dev/null";
		fi;

		local middle_grid_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/middle_grid_load_freq";
		if [ ! -e "$middle_grid_load_tmp" ]; then
			middle_grid_load_tmp="/dev/null";
		fi;

		local middle_grid_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/middle_grid_step";
		if [ ! -e "$middle_grid_step_tmp" ]; then
			middle_grid_step_tmp="/dev/null";
		fi;

		local optimal_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/optimal_freq";
		if [ ! -e "$optimal_freq_tmp" ]; then
			optimal_freq_tmp="/dev/null";
		fi;

		local optimal_max_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/optimal_max_freq";
		if [ ! -e "$optimal_max_freq_tmp" ]; then
			optimal_max_freq_tmp="/dev/null";
		fi;

		local sampling_down_factor_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_down_factor";
		if [ ! -e "$sampling_down_factor_tmp" ]; then
			sampling_down_factor_tmp="/dev/null";
		fi;

		local down_differential_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_differential";
		if [ ! -e "$down_differential_tmp" ]; then
			down_differential_tmp="/dev/null";
		fi;

		local sampling_rate_min_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_rate_min";
		if [ ! -e "$sampling_rate_min_tmp" ]; then
			sampling_rate_min_tmp="/dev/null";
		fi;

		local sync_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sync_freq";
		if [ ! -e "$sync_freq_tmp" ]; then
			sync_freq_tmp="/dev/null";
		fi;

		local up_threshold_any_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_any_cpu_load";
		if [ ! -e "$up_threshold_any_cpu_load_tmp" ]; then
			up_threshold_any_cpu_load_tmp="/dev/null";
		fi;

		local up_threshold_multi_core_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_multi_core";
		if [ ! -e "$up_threshold_multi_core_tmp" ]; then
			up_threshold_multi_core_tmp="/dev/null";
		fi;

		echo "$sampling_rate" > "$sampling_rate_tmp";
		echo "$up_threshold" > "$up_threshold_tmp";
		echo "$high_grid_load" > "$high_grid_load_tmp";
		echo "$high_grid_step" > "$high_grid_step_tmp";
		echo "$middle_grid_load" > "$middle_grid_load_tmp";
		echo "$middle_grid_step" > "$middle_grid_step_tmp";
		echo "$optimal_freq" > "$optimal_freq_tmp";
		echo "$optimal_max_freq" > "$optimal_max_freq_tmp"
		echo "$sampling_down_factor" > "$sampling_down_factor_tmp";
		echo "$down_differential" > "$down_differential_tmp";
		echo "$sampling_rate_min" > "$sampling_rate_min_tmp";
		echo "$sync_freq" > "$sync_freq_tmp";
		echo "$up_threshold_any_cpu_load" > "$up_threshold_any_cpu_load_tmp";
		echo "$up_threshold_multi_core" > "$up_threshold_multi_core_tmp";
		
		log -p i -t "$FILE_NAME" "*** CPU_GOV_TWEAKS: $state ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
# this needed for cpu tweaks apply from STweaks in real time
apply_cpu="$2";
#if [ "$apply_cpu" == "update" ] || [ "$cortexbrain_background_process" -eq "0" ]; then
#	CPU_GOV_TWEAKS;
#fi;

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
		echo "8192" > /proc/sys/vm/min_free_kbytes;

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

# ==============================================================
# TCP-TWEAKS
# ==============================================================
TCP_TWEAKS()
{
	if [ "$cortexbrain_tcp" == "on" ]; then
		echo "0" > /proc/sys/net/ipv4/tcp_timestamps;
		echo "1" > /proc/sys/net/ipv4/tcp_rfc1337;
		echo "1" > /proc/sys/net/ipv4/tcp_workaround_signed_windows;
		echo "1" > /proc/sys/net/ipv4/tcp_low_latency;
		echo "1" > /proc/sys/net/ipv4/tcp_mtu_probing;
		echo "2" > /proc/sys/net/ipv4/tcp_frto_response;
		echo "1" > /proc/sys/net/ipv4/tcp_no_metrics_save;
		echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse;
		echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle;
		echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout;
		echo "0" > /proc/sys/net/ipv4/tcp_ecn;
		echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "40" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
		echo "2500" > /proc/sys/net/core/netdev_max_backlog;
		echo "1" > /proc/sys/net/ipv4/route/flush;

		log -p i -t "$FILE_NAME" "*** TCP_TWEAKS ***: enabled";
	else
		echo "1" > /proc/sys/net/ipv4/tcp_timestamps;
		echo "0" > /proc/sys/net/ipv4/tcp_rfc1337;
		echo "0" > /proc/sys/net/ipv4/tcp_workaround_signed_windows;
		echo "0" > /proc/sys/net/ipv4/tcp_low_latency;
		echo "0" > /proc/sys/net/ipv4/tcp_mtu_probing;
		echo "0" > /proc/sys/net/ipv4/tcp_frto_response;
		echo "0" > /proc/sys/net/ipv4/tcp_no_metrics_save;
		echo "0" > /proc/sys/net/ipv4/tcp_tw_reuse;
		echo "0" > /proc/sys/net/ipv4/tcp_tw_recycle;
		echo "60" > /proc/sys/net/ipv4/tcp_fin_timeout;
		echo "2" > /proc/sys/net/ipv4/tcp_ecn;
		echo "9" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "75" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
		echo "1000" > /proc/sys/net/core/netdev_max_backlog;
		echo "0" > /proc/sys/net/ipv4/route/flush;

		log -p i -t "$FILE_NAME" "*** TCP_TWEAKS ***: disabled";
	fi;

	if [ "$cortexbrain_tcp_ram" == "on" ]; then
		echo "4194304" > /proc/sys/net/core/wmem_max;
		echo "4194304" > /proc/sys/net/core/rmem_max;
		echo "20480" > /proc/sys/net/core/optmem_max;
		echo "4096 87380 4194304" > /proc/sys/net/ipv4/tcp_wmem;
		echo "4096 87380 4194304" > /proc/sys/net/ipv4/tcp_rmem;

		log -p i -t "$FILE_NAME" "*** TCP_RAM_TWEAKS ***: enabled";
	else
		echo "131071" > /proc/sys/net/core/wmem_max;
		echo "131071" > /proc/sys/net/core/rmem_max;
		echo "10240" > /proc/sys/net/core/optmem_max;
		echo "4096 16384 262144" > /proc/sys/net/ipv4/tcp_wmem;
		echo "4096 87380 704512" > /proc/sys/net/ipv4/tcp_rmem;

		log -p i -t "$FILE_NAME" "*** TCP_RAM_TWEAKS ***: disable";
	fi;
}
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	TCP_TWEAKS;
fi;

# ==============================================================
# FIREWALL-TWEAKS
# ==============================================================
FIREWALL_TWEAKS()
{
	if [ "$cortexbrain_firewall" == "on" ]; then
		# ping/icmp protection
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts;
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all;
		echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses;

		log -p i -t "$FILE_NAME" "*** FIREWALL_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	FIREWALL_TWEAKS;
fi;

ALL_CORES_ON()
{
	local state="$1";
	if [ "$state" == "on" ]; then
		mv /system/bin/mpdecision /system/bin/mpdecision.disabled;
		pkill -f "/system/bin/mpdecision";
		echo "1" > /sys/devices/system/cpu/cpu1/online;
		echo "1" > /sys/devices/system/cpu/cpu2/online;
		echo "1" > /sys/devices/system/cpu/cpu3/online;
	elif [ "$state" == "off" ]; then
		echo "0" > /sys/devices/system/cpu/cpu1/online;
		echo "0" > /sys/devices/system/cpu/cpu2/online;
		echo "0" > /sys/devices/system/cpu/cpu3/online;
	elif [ "$state" == "auto" ]; then
		if [ "$(pgrep -f "mpdecision" | wc -l)" -eq "0" ]; then
			mv /system/bin/mpdecision.disabled /system/bin/mpdecision;
			/system/bin/mpdecision --no_sleep --avg_comp &
                fi;
	fi;
}

CENTRAL_CPU_FREQ()
{
	local state="$1";

	local SYSTEM_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor);

	if [ "$cortexbrain_cpu" == "on" ]; then
		ALL_CORES_ON "on";

		if [ "$state" == "wake_boost" ] && [ "$wakeup_boost" -ge "0" ]; then
			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq;
			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq;
			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq;

			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq;
			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq;
			echo "$cpu_wakeup_boost_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq;
		elif [ "$state" == "awake_normal" ]; then
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq;
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq;
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq;

			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq;
			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq;
			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq;
		elif [ "$state" == "sleep_freq" ]; then
			echo "$cpu_min_sleep_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu_min_sleep_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq;
			echo "$cpu_min_sleep_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq;
			echo "$cpu_min_sleep_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq;

			echo "$cpu_max_sleep_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$cpu_max_sleep_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq;
			echo "$cpu_max_sleep_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq;
			echo "$cpu_max_sleep_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq;
			ALL_CORES_ON "off";
		elif [ "$state" == "sleep_call" ]; then
			echo "$cpu_min_sleep_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			# brain cooking prevention during call
			echo "1190400" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			ALL_CORES_ON "off";
		else
			# if wakeup boost is disabled 0 or -1
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq;
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq;
			echo "$cpu_min_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq;

			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq;
			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq;
			echo "$cpu_max_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq;
		fi;

		log -p i -t "$FILE_NAME" "*** CENTRAL_CPU_FREQ: $state ***: done";

		# Eanble ROM CPU Controller
		ALL_CORES_ON "auto"
	else
		log -p i -t "$FILE_NAME" "*** CENTRAL_CPU_FREQ: NOT CHANGED ***: done";
	fi;
}

BOOST_DELAY()
{
	# check if ROM booting now, then don't wait - creation and deletion of $DATA_DIR/booting @> /sbin/ext/post-init.sh
	if [ "$wakeup_boost" -gt "0" ] && [ ! -e "$DATA_DIR"/booting ]; then
		log -p i -t "$FILE_NAME" "*** BOOST_DELAY: ${wakeup_boost}sec ***";
		sleep "$wakeup_boost";
	fi;
}

# disable/enable ipv6
IPV6()
{
	local state='';

	if [ -e /data/data/com.cisco.anyconnec* ]; then
		local CISCO_VPN=1;
	else
		local CISCO_VPN=0;
	fi;

	if [ "$cortexbrain_ipv6" == "on" ] || [ "$CISCO_VPN" -eq "1" ]; then
		echo "0" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null;
		local state="enabled";
	else
		echo "1" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null;
		local state="disabled";
	fi;

	log -p i -t "$FILE_NAME" "*** IPV6 ***: $state";
}

NET()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "3" > /proc/sys/net/ipv4/tcp_keepalive_probes; # default: 3
		echo "1200" > /proc/sys/net/ipv4/tcp_keepalive_time; # default: 7200s
		echo "10" > /proc/sys/net/ipv4/tcp_keepalive_intvl; # default: 75s
		echo "10" > /proc/sys/net/ipv4/tcp_retries2; # default: 15
	elif [ "$state" == "sleep" ]; then
		echo "2" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "300" > /proc/sys/net/ipv4/tcp_keepalive_time;
		echo "5" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
		echo "5" > /proc/sys/net/ipv4/tcp_retries2;
	fi;

	log -p i -t "$FILE_NAME" "*** NET ***: $state";
}

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
		local tmp_scheduler=$(cat "$sys_mmc0_scheduler_tmp");

		if [ ! -e "$sys_mmc1_scheduler_tmp" ]; then
			sys_mmc1_scheduler_tmp="/dev/null";
		fi;

		local ext_tmp_scheduler=$(cat "$sys_mmc1_scheduler_tmp");

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

CPU_GOVERNOR()
{
	
	ALL_CORES_ON "on";
	local scaling_governor0_tmp="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor";
	local scaling_governor1_tmp="/sys/devices/system/cpu/cpu1/cpufreq/scaling_governor";
	local scaling_governor2_tmp="/sys/devices/system/cpu/cpu2/cpufreq/scaling_governor";
	local scaling_governor3_tmp="/sys/devices/system/cpu/cpu3/cpufreq/scaling_governor";
	local tmp_governor=$(cat $scaling_governor0_tmp);

	if [ "$cortexbrain_cpu" == "on" ]; then
		if [ "$tmp_governor" != "$default_cpu_gov" ]; then
			echo "$default_cpu_gov" > "$scaling_governor0_tmp";
			echo "$default_cpu_gov" > "$scaling_governor1_tmp";
			echo "$default_cpu_gov" > "$scaling_governor2_tmp";
			echo "$default_cpu_gov" > "$scaling_governor3_tmp";
		fi;

		local USED_GOV_NOW=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor);

		log -p i -t "$FILE_NAME" "*** CPU_GOVERNOR: set $state GOV $USED_GOV_NOW ***: done";
	else
		log -p i -t "$FILE_NAME" "*** CPU_GOVERNOR: NO CHANGED ***: done";
	fi;
	ALL_CORES_ON "auto"
}

CALL_STATE()
{
	if [ "$DUMPSYS_STATE" -eq "1" ]; then

		# check the call state, not on call = 0, on call = 2
		local state_tmp=$(echo "$TELE_DATA" | awk '/mCallState/ {print $1}');

		if [ "$state_tmp" != "mCallState=0" ]; then
			NOW_CALL_STATE=1;
		else
			NOW_CALL_STATE=0;
		fi;

		log -p i -t "$FILE_NAME" "*** CALL_STATE: $NOW_CALL_STATE ***";
	else
		NOW_CALL_STATE=0;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	# Do not touch this
	CALL_STATE;

	# Check call state, if on call dont sleep
	if [ "$NOW_CALL_STATE" -eq "1" ]; then
		CENTRAL_CPU_FREQ "awake_normal";
		NOW_CALL_STATE=0;
		log -p i -t "$FILE_NAME" "*** AWAKE_MODE - CALL STATE ***: done";
	else
		# not on call, check if was powerd by USB on sleep, or didnt sleep at all
		if [ "$WAS_IN_SLEEP_MODE" -eq "1" ]; then
			CPU_GOVERNOR;
			#CPU_GOV_TWEAKS;
			CENTRAL_CPU_FREQ "wake_boost";
			NET "awake";
			IO_SCHEDULER "awake";
			BOOST_DELAY;
			CENTRAL_CPU_FREQ "awake_normal";
		else
			CENTRAL_CPU_FREQ "wake_boost";
			BOOST_DELAY;
			CENTRAL_CPU_FREQ "awake_normal";
		fi;
		log -p i -t "$FILE_NAME" "*** AWAKE_MODE - WAKEUP ***: done";
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	WAS_IN_SLEEP_MODE=0;

	# we only read the config when the screen turns off ...
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	# we only read tele-data when the screen turns off ...
	if [ "$DUMPSYS_STATE" -eq "1" ]; then
		TELE_DATA=$(dumpsys telephony.registry);
	fi;

	# Check call state
	CALL_STATE;

	# check if we on call
	if [ "$NOW_CALL_STATE" -eq "0" ]; then
		WAS_IN_SLEEP_MODE=1;
		CROND_SAFETY;
		CENTRAL_CPU_FREQ "sleep_freq";
		IO_SCHEDULER "sleep";
		NET "sleep";
		IPV6;

		log -p i -t "$FILE_NAME" "*** SLEEP mode ***";
	else
		# Check if on call
		if [ "$NOW_CALL_STATE" -eq "1" ]; then
			CENTRAL_CPU_FREQ "sleep_call";
			NOW_CALL_STATE=1;

			log -p i -t "$FILE_NAME" "*** on call: SLEEP aborted! ***";
		else
			# Early Wakeup detected
			log -p i -t "$FILE_NAME" "*** early wake up: SLEEP aborted! ***";
		fi;
	fi;
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ] && [ "$(pgrep -f "/sbin/ext/cortexbrain-tune.sh" | wc -l)" -eq "2" ]; then
	(while true; do
		while [ "$(cat /proc/sys/vm/vfs_cache_pressure)" != "60" ]; do
			sleep "2";
		done;
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /proc/sys/vm/vfs_cache_pressure)" != "20" ]; do
			sleep "2";
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
