#!/sbin/busybox sh

BB=/sbin/busybox;

case "$1" in
	LiveAcpu_pvs)
		$BB echo "`$BB cat /data/.dori/acpu_pvs`"
	;;
	LiveSpeed_bin)
		$BB echo "`$BB cat /data/.dori/speed_bin`"
	;;
	LiveDefaultGPUGovernor)
		$BB echo "`$BB cat /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/governor`"
	;;
	LiveDefaultCPUGovernor)
		CPU0_GOV=$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_governor_cpu0);
		CPU1_GOV=$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_governor_cpu1);
		CPU2_GOV=$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_governor_cpu2);
		CPU3_GOV=$(cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_governor_cpu3);
		echo "CPU0 GOV: $CPU0_GOV@nCPU1 GOV: $CPU1_GOV@nCPU2 GOV: $CPU2_GOV@nCPU3 GOV: $CPU3_GOV";
	;;
	LiveGPUFrequency)
		GPUFREQ="$((`$BB cat /sys/class/kgsl/kgsl-3d0/gpuclk` / 1000000)) MHz";
		$BB echo "$GPUFREQ";
	;;
	LiveGPU_MAX_MIN_Freq)
		GPU_MAX_FREQ="$(expr `cat /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/max_freq` / 1000000)MHz";
		GPU_MIN_FREQ="$(expr `cat /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/min_freq` / 1000000)MHz";
		echo "Max GPU Freq: $GPU_MAX_FREQ@nMin GPU Freq: $GPU_MIN_FREQ"
	;;
	LiveIOReadAheadSize)
		$BB echo "`$BB cat /sys/block/mmcblk0/queue/read_ahead_kb`";
	;;
	LiveIOScheduler)
		$BB echo "`$BB cat /sys/block/mmcblk0/queue/scheduler`";
	;;
	LiveTCPCongestion)
		$BB echo "`$BB cat /proc/sys/net/ipv4/tcp_congestion_control`";
	;;
	LiveCPU_MAX_MIN_Freq)
		CPU0_FREQMAX="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu0` / 1000)MHz"
		CPU0_FREQMIN="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu0` / 1000)MHz"
		CPU1_FREQMAX="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu1` / 1000)MHz"
		CPU1_FREQMIN="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu1` / 1000)MHz"
		CPU2_FREQMAX="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu2` / 1000)MHz"
		CPU2_FREQMIN="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu2` / 1000)MHz"
		CPU3_FREQMAX="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_max_freq_cpu3` / 1000)MHz"
		CPU3_FREQMIN="$(expr `cat /sys/devices/system/cpu/cpufreq/all_cpus/scaling_min_freq_cpu3` / 1000)MHz"
		echo "Max CPU0 Freq: $CPU0_FREQMAX@nMin CPU0 Freq: $CPU0_FREQMIN@nMax CPU1 Freq: $CPU1_FREQMAX@nMin CPU1 Freq: $CPU1_FREQMIN@nMax CPU2 Freq: $CPU2_FREQMAX@nMin CPU2 Freq: $CPU2_FREQMIN@nMax CPU3 Freq: $CPU3_FREQMAX@nMin CPU3 Freq: $CPU3_FREQMIN"
	;;
	LiveBatteryTemperature)
		BAT_C=`$BB awk '{ print $1 / 10 }' /sys/class/power_supply/battery/temp`;
		BAT_F=`$BB awk "BEGIN { print ( ($BAT_C * 1.8) + 32 ) }"`;
		BAT_H=`$BB cat /sys/class/power_supply/battery/health`;

		$BB echo "$BAT_C°C | $BAT_F°F@nHealth: $BAT_H";
	;;
	LiveCPUTemperature)
		CPU_C=`$BB cat /sys/class/thermal/thermal_zone5/temp`;
		CPU_F=`$BB awk "BEGIN { print ( ($CPU_C * 1.8) + 32 ) }"`;

		$BB echo "$CPU_C°C | $CPU_F°F";
	;;
	LiveMemory)
		while read TYPE MEM KB; do
			if [ "$TYPE" = "MemTotal:" ]; then
				TOTAL="$((MEM / 1024)) MB";
			elif [ "$TYPE" = "MemFree:" ]; then
				CACHED=$((MEM / 1024));
			elif [ "$TYPE" = "Cached:" ]; then
				FREE=$((MEM / 1024));
			fi;
		done < /proc/meminfo;
		
		FREE="$((FREE + CACHED)) MB";
		$BB echo "Total: $TOTAL@nFree: $FREE";
	;;
	LiveTime)
		STATE="";
		CNT=0;
		SUM=`$BB awk '{s+=$2} END {print s}' /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state`;
		
		while read FREQ TIME; do
			if [ "$CNT" -ge $2 ] && [ "$CNT" -le $3 ]; then
				FREQ="$((FREQ / 1000)) MHz:";
				if [ $TIME -ge "100" ]; then
					PERC=`$BB awk "BEGIN { print ( ($TIME / $SUM) * 100) }"`;
					PERC="`$BB printf "%0.1f\n" $PERC`%";
					TIME=$((TIME / 100));
					STATE="$STATE $FREQ `$BB echo - | $BB awk -v "S=$TIME" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'` ($PERC)@n";
				fi;
			fi;
			CNT=$((CNT+1));
		done < /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state;
		
		STATE=${STATE%??};
		$BB echo "$STATE";
	;;
	LiveUpTime)
		TOTAL=`$BB awk '{ print $1 }' /proc/uptime`;
		AWAKE=$((`$BB awk '{s+=$2} END {print s}' /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state` / 100));
		SLEEP=`$BB awk "BEGIN { print ($TOTAL - $AWAKE) }"`;
		
		PERC_A=`$BB awk "BEGIN { print ( ($AWAKE / $TOTAL) * 100) }"`;
		PERC_A="`$BB printf "%0.1f\n" $PERC_A`%";
		PERC_S=`$BB awk "BEGIN { print ( ($SLEEP / $TOTAL) * 100) }"`;
		PERC_S="`$BB printf "%0.1f\n" $PERC_S`%";
		
		TOTAL=`$BB echo - | $BB awk -v "S=$TOTAL" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'`;
		AWAKE=`$BB echo - | $BB awk -v "S=$AWAKE" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'`;
		SLEEP=`$BB echo - | $BB awk -v "S=$SLEEP" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'`;
		$BB echo "Total: $TOTAL (100.0%)@nSleep: $SLEEP ($PERC_S)@nAwake: $AWAKE ($PERC_A)";
	;;
	LiveUnUsed)
		UNUSED="";
		while read FREQ TIME; do
			FREQ="$((FREQ / 1000)) MHz";
			if [ $TIME -lt "100" ]; then
				UNUSED="$UNUSED$FREQ, ";
			fi;
		done < /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state;
		
		UNUSED=${UNUSED%??};
		$BB echo "$UNUSED";
	;;
esac;
