#!/system/bin/sh

# Custom replacement for the default /system/etc/init.galbi.post_boot.sh script
# Added by and modified by StockMOD kernel

target=$(getprop ro.board.platform)

# protect init from oom
echo "-1000" > /proc/1/oom_score_adj;

sysrw;
mount -o remount,rw /;

# oom and mem perm fix
chmod 666 /sys/module/lowmemorykiller/parameters/cost;
chmod 666 /sys/module/lowmemorykiller/parameters/adj;

# clean old modules from /system and add new from ramdisk
if [ ! -d /system/lib/modules ]; then
	busybox mkdir /system/lib/modules;
fi;
cd /lib/modules/;
for i in *.ko; do
	busybox rm -f /system/lib/modules/"$i";
done;
cd /;

busybox cp /lib/modules/*.ko /system/lib/modules/;
chmod 755 /system/lib/modules/*.ko;
chmod 755 /lib/modules/*.ko;

# make sure we own the device nodes
chown system /sys/devices/system/cpu/cpufreq/*
chown system /sys/devices/system/cpu/cpufreq/ondemand/*
chown system /sys/devices/system/cpu/cpu*/cpufreq/*
chmod 664 /sys/devices/system/cpu/cpufreq/*
chmod 664 /sys/devices/system/cpu/cpu*/cpufreq/*

chmod -R 0700 /data/property

# some nice thing for dev
if [ ! -e /cpufreq ]; then
	busybox ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
	busybox ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;
fi;

# disable debugging on modules, adming can enable any time.
echo "0" > /sys/module/kernel/parameters/initcall_debug;
echo "0" > /sys/module/alarm/parameters/debug_mask;
echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
echo "0" > /sys/module/binder/parameters/debug_mask;
echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;

#for no_debug in $(find /sys/ -name *debug*); do
#	echo "0" > "$no_debug";
#done;

# wifi mac load fix
chown system.wifi /dev/block/mmcblk0p13
chmod 0660 /dev/block/mmcblk0p13

# CPU tuning
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
echo 10000 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_any_cpu_load
echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_multi_core
echo 10 > /sys/devices/system/cpu/cpufreq/ondemand/down_differential
echo 4 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor

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

# set grid steps
echo 7 > /sys/devices/system/cpu/cpufreq/ondemand/middle_grid_step
echo 40 > /sys/devices/system/cpu/cpufreq/ondemand/middle_grid_load
echo 14 > /sys/devices/system/cpu/cpufreq/ondemand/high_grid_step
echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/high_grid_load

echo 0 > /sys/module/msm_thermal/core_control/enabled
echo 1 > /dev/cpuctl/apps/cpu.notify_on_migrate

emmc_boot=$(getprop ro.boot.emmc)
case "$emmc_boot"
	in "true")
		if [ -e  /sys/devices/platform/rs300000a7.65536 ]; then
			chown system /sys/devices/platform/rs300000a7.65536/force_sync
			chown system /sys/devices/platform/rs300000a7.65536/sync_sts
			chown system /sys/devices/platform/rs300100a7.65536/force_sync
			chown system /sys/devices/platform/rs300100a7.65536/sync_sts
		fi;
	;;
esac

# Tweak some VM settings for system smoothness
echo 40 > /proc/sys/vm/dirty_background_ratio
echo 60 > /proc/sys/vm/dirty_ratio

# set ondemand GPU governor as default
echo ondemand > /sys/devices/fdb00000.qcom,kgsl-3d0/kgsl/kgsl-3d0/pwrscale/trustzone/governor

# Post-setup services
start mpdecision

#set default readahead
echo 512 > /sys/block/mmcblk0/bdi/read_ahead_kb

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
			busybox mkdir /data/connectivity/
			chown system.system /data/connectivity/
			chmod 775 /data/connectivity/
			busybox mkdir /data/connectivity/nsrm/
			chown system.system /data/connectivity/nsrm/
			chmod 775 /data/connectivity/nsrm/
			busybox cp /system/etc/cne/NsrmConfiguration.xml /data/connectivity/nsrm/
			busybox cp /system/etc/cne/libcnelog.so /data/connectivity/
			chown system.system /data/connectivity/nsrm/NsrmConfiguration.xml
			chmod 775 /data/connectivity/nsrm/NsrmConfiguration.xml
		fi
	;;
esac

lgodl_prop=$(getprop persist.service.lge.odl_on)
if [ "$lgodl_prop" == "true" ]; then
	start lg_dm_dev_router
fi

# correct decoder support
setprop lpa.decode=false

(
	# Start any init.d scripts that may be present in the rom or added by the user
	if [ -d /system/etc/init.d ]; then
		chmod 755 /system/etc/init.d/*;
		run-parts /system/etc/init.d/;
	fi;
)&

# write OK to check that all done.

TIME_NOW=$(date)
echo "$TIME_NOW" > /data/boot_log_dm

