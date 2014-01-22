#!/sbin/busybox sh

# Kernel Tuning by Dorimanx.

BB=/sbin/busybox

# protect init from oom
echo "-1000" > /proc/1/oom_score_adj;

$BB mount -o remount,rw /;
$BB mount -o remount,rw /system;

# clean old modules from /system and add new from ramdisk
if [ ! -d /system/lib/modules ]; then
	$BB mkdir /system/lib/modules;
fi;
cd /lib/modules/;
for i in *.ko; do
	$BB rm -f /system/lib/modules/"$i";
done;
cd /;

$BB chmod 755 /lib/modules/*.ko;
$BB cp -a /lib/modules/*.ko /system/lib/modules/;

(
	# run ROM scripts
	if [ -e /system/etc/init.galbi.post_boot.sh ]; then
		$BB sh /system/etc/init.galbi.post_boot.sh
	else
		echo "No ROM Boot script detected"
	fi;
)&

sleep 10;

# oom and mem perm fix
chmod 666 /sys/module/lowmemorykiller/parameters/cost;
chmod 666 /sys/module/lowmemorykiller/parameters/adj;

# enable force fast charge on USB to charge faster
echo "1" > /sys/kernel/fast_charge/force_fast_charge;
chmod 444 /sys/kernel/fast_charge/force_fast_charge;

# make sure we own the device nodes
chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
chown system /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias
chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
chown root.system /sys/devices/system/cpu/cpu1/online
chown root.system /sys/devices/system/cpu/cpu2/online
chown root.system /sys/devices/system/cpu/cpu3/online
chmod 664 /sys/devices/system/cpu/cpu1/online
chmod 664 /sys/devices/system/cpu/cpu2/online
chmod 664 /sys/devices/system/cpu/cpu3/online

chmod -R 0700 /data/property

# some nice thing for dev
if [ ! -e /cpufreq ]; then
	$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
	$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;
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

# Tweak some VM settings for system smoothness
echo 40 > /proc/sys/vm/dirty_background_ratio
echo 60 > /proc/sys/vm/dirty_ratio

# set ondemand GPU governor as default
echo ondemand > /sys/devices/fdb00000.qcom,kgsl-3d0/kgsl/kgsl-3d0/pwrscale/trustzone/governor

# set default readahead
echo 512 > /sys/block/mmcblk0/bdi/read_ahead_kb

# make sure our max gpu clock is set via sysfs
echo 450000000 > /sys/class/kgsl/kgsl-3d0/max_gpuclk

lgodl_prop=$(getprop persist.service.lge.odl_on)
if [ "$lgodl_prop" == "true" ]; then
	start lg_dm_dev_router
fi

# correct decoder support
setprop lpa.decode false
setprop af.resampler.quality 4
setprop audio.offload.buffer.size.kb 32
setprop audio.offload.gapless.enabled true
setprop av.offload.enable true

# Fix ROM dev wrong sets.
setprop persist.adb.notify 0
setprop persist.service.adb.enable 1
setprop persist.sys.use_dithering 1
setprop dalvik.vm.execution-mode int:jit
setprop pm.sleep_mode 1

(
	# Start any init.d scripts that may be present in the rom or added by the user
	if [ -d /system/etc/init.d ]; then
		chmod 755 /system/etc/init.d/*;
		if [ ! -e /data/dori_init_run_test ]; then
			$BB run-parts /system/etc/init.d/;
		else
			echo "init.d scripts executed by ROM already"
		fi;
	fi;
)&

# write OK to check that all done.
TIME_NOW=$(date)
echo "$TIME_NOW" > /data/boot_log_dm

