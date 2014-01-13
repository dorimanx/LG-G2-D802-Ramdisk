#!/system/bin/sh

# Custom replacement for the default /system/etc/init.galbi.post_boot.sh script
# Added by and modified by StockMOD kernel

# Ondemand governor tweaked for performance

target=$(getprop ro.board.platform)

chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
chown system /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias
chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

chmod -R 0700 /data/property

# wifi mac load fix
chown system:wifi /dev/block/mmcblk0p13
chmod 0660 /dev/block/mmcblk0p13

case "$target" in
	"msm8974")
		echo 2 > /sys/module/lpm_resources/enable_low_power/l2
		echo 1 > /sys/module/lpm_resources/enable_low_power/pxo
		echo 1 > /sys/module/lpm_resources/enable_low_power/vdd_dig
		echo 1 > /sys/module/lpm_resources/enable_low_power/vdd_mem
		echo 1 > /sys/module/pm_8x60/modes/cpu0/power_collapse/suspend_enabled
		echo 1 > /sys/module/pm_8x60/modes/cpu1/power_collapse/suspend_enabled
		echo 1 > /sys/module/pm_8x60/modes/cpu2/power_collapse/suspend_enabled
		echo 1 > /sys/module/pm_8x60/modes/cpu3/power_collapse/suspend_enabled
		echo 1 > /sys/module/pm_8x60/modes/cpu0/power_collapse/idle_enabled

		soc_revision=$(cat /sys/devices/soc0/revision)
		if [ "$soc_revision" != "1.0" ]; then
			log -p i -t POSTBOOT SOC="$soc_revision", Do not enable Retention
			echo 0 > /sys/module/pm_8x60/modes/cpu0/retention/idle_enabled
			echo 0 > /sys/module/pm_8x60/modes/cpu1/retention/idle_enabled
			echo 0 > /sys/module/pm_8x60/modes/cpu2/retention/idle_enabled
			echo 0 > /sys/module/pm_8x60/modes/cpu3/retention/idle_enabled
		fi

		# set ondemand governor as default for all CPUs
		echo 1 > /sys/devices/system/cpu/cpu1/online
		echo 1 > /sys/devices/system/cpu/cpu2/online
		echo 1 > /sys/devices/system/cpu/cpu3/online
		echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		echo "ondemand" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
		echo "ondemand" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
		echo "ondemand" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor

		# Tweak the sampling rates and load thresholds
		echo 7000 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
		echo 60 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
		echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_any_cpu_load
		echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_multi_core
		echo 20 > /sys/devices/system/cpu/cpufreq/ondemand/down_differential
		echo 20 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
		echo 20 > /sys/devices/system/cpu/cpufreq/ondemand/down_differential_multi_core

		# tweak some other settings
		echo 0 > /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
		echo 0 > /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias

		# set sync frequencies
		echo 960000 > /sys/devices/system/cpu/cpufreq/ondemand/optimal_freq
		echo 960000 > /sys/devices/system/cpu/cpufreq/ondemand/sync_freq
		echo 960000 > /sys/devices/system/cpu/cpufreq/ondemand/optimal_max_freq

		# set minimum frequencies
		echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
		echo 300000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
		echo 300000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
		echo 300000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq

		# set default max fequencies, userspace apps can override this
		#echo 2265000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		#echo 2265000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
		#echo 2265000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
		#echo 2265000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq

		# set grid steps
		echo 7 > /sys/devices/system/cpu/cpufreq/ondemand/middle_grid_step
		echo 40 > /sys/devices/system/cpu/cpufreq/ondemand/middle_grid_load
		echo 14 > /sys/devices/system/cpu/cpufreq/ondemand/high_grid_step
		echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/high_grid_load

		# make sure we own the device nodes
		chown root.system /sys/devices/system/cpu/mfreq
		chmod 220 /sys/devices/system/cpu/mfreq
		chown root.system /sys/devices/system/cpu/cpu1/online
		chown root.system /sys/devices/system/cpu/cpu2/online
		chown root.system /sys/devices/system/cpu/cpu3/online
		chmod 664 /sys/devices/system/cpu/cpu1/online
		chmod 664 /sys/devices/system/cpu/cpu2/online
		chmod 664 /sys/devices/system/cpu/cpu3/online

		echo 0 > /sys/module/msm_thermal/core_control/enabled
		echo 1 > /dev/cpuctl/apps/cpu.notify_on_migrate
	;;
esac

emmc_boot=$(getprop ro.boot.emmc)
case "$emmc_boot"
	in "true")
		chown system /sys/devices/platform/rs300000a7.65536/force_sync
		chown system /sys/devices/platform/rs300000a7.65536/sync_sts
		chown system /sys/devices/platform/rs300100a7.65536/force_sync
		chown system /sys/devices/platform/rs300100a7.65536/sync_sts
	;;
esac

# Tweak some VM settings for system smoothness
echo 500 > /proc/sys/vm/dirty_expire_centisecs
echo 20 > /proc/sys/vm/dirty_background_ratio
echo 30 > /proc/sys/vm/dirty_ratio
echo 50 > /proc/sys/vm/vfs_cache_pressure

# set simple GPU governor as default
echo simple > /sys/devices/fdb00000.qcom,kgsl-3d0/kgsl/kgsl-3d0/pwrscale/trustzone/governor

# Post-setup services
start mpdecision

#set default readahead
echo 1024 > /sys/block/mmcblk0/bdi/read_ahead_kb

# make sure our max gpu clock is set via sysfs
echo 450000000 > /sys/class/kgsl/kgsl-3d0/max_gpuclk

targetProd=$(getprop ro.product.name)
case "$targetProd" in
	"g2_dcm_jp")
		echo 300000 > /sys/devices/system/cpu/cpufreq/ondemand/lcdoff_optimal_max_freq
		echo 11 > /sys/devices/system/cpu/cpufreq/ondemand/lcdoff_middle_grid_step
		echo 12 > /sys/devices/system/cpu/cpufreq/ondemand/lcdoff_middle_grid_load
		echo 14 > /sys/devices/system/cpu/cpufreq/ondemand/lcdoff_high_grid_step
		echo 53 > /sys/devices/system/cpu/cpufreq/ondemand/lcdoff_high_grid_load
esac

# LGE_CHANGE_S, [LGE_DATA][CNE_NSRM], ct-radio@lge.com, 2012-04-05
targetProd=$(getprop ro.product.name)
case "$targetProd" in
	"g2_lgu_kr" | "vu3_lgu_kr" | "z_lgu_kr" | "z_kddi_jp" | "g2_kddi_jp")
		targetPath=$(getprop lg.data.nsrm.policypath)
		if [ ! -s "$targetPath" ]; then
			mkdir /data/connectivity/
			chown system.system /data/connectivity/
			chmod 775 /data/connectivity/
			mkdir /data/connectivity/nsrm/
			chown system.system /data/connectivity/nsrm/
			chmod 775 /data/connectivity/nsrm/
			cp /system/etc/cne/NsrmConfiguration.xml /data/connectivity/nsrm/
			cp /system/etc/cne/libcnelog.so /data/connectivity/
			chown system.system /data/connectivity/nsrm/NsrmConfiguration.xml
			chmod 775 /data/connectivity/nsrm/NsrmConfiguration.xml
		fi
	;;
esac

lgodl_prop=$(getprop persist.service.lge.odl_on)
if [ "$lgodl_prop" == "true" ]; then
	start lg_dm_dev_router
fi

(
	# Start any init.d scripts that may be present in the rom or added by the user
	if [ -d /system/etc/init.d ]; then
		chmod 755 /system/etc/init.d/*;
		run-parts /system/etc/init.d/;
	fi;
)&
