#!/sbin/busybox sh

# Kernel Tuning by Dorimanx.

BB=/sbin/busybox

# protect init from oom
echo "-1000" > /proc/1/oom_score_adj;

OPEN_RW()
{
        $BB mount -o remount,rw /;
        $BB mount -o remount,rw /system;
}
OPEN_RW;

# fix perms
chmod -R 755 /res/
chmod -R 755 /sbin/
chmod 6755 /sbin/busybox

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

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod 755 /system/etc/init.d/;
fi;

(
	if [ ! -d /data/init.d_bkp ]; then
		mkdir /data/init.d_bkp;
	fi;
	mv /system/etc/init.d/* /data/init.d_bkp/;
        # run ROM scripts
        if [ -e /system/etc/init.galbi.post_boot.sh ]; then
                $BB sh /system/etc/init.galbi.post_boot.sh
        else
                echo "No ROM Boot script detected"
        fi;
	mv /data/init.d_bkp/* /system/etc/init.d/
)&

sleep 5;
OPEN_RW;

# cleaning
$BB rm -rf /cache/lost+found/* 2> /dev/null;
$BB rm -rf /data/lost+found/* 2> /dev/null;
$BB rm -rf /data/tombstones/* 2> /dev/null;
$BB rm -rf /data/anr/* 2> /dev/null;

# critical Permissions fix
$BB chown -R root:system /sys/devices/system/cpu/;
$BB chown -R system:system /data/anr;
$BB chown -R root:radio /data/property/;
$BB chmod -R 777 /tmp/;
$BB chmod -R 6755 /sbin/ext/;
$BB chmod -R 0777 /dev/cpuctl/;
$BB chmod -R 0777 /data/system/inputmethod/;
$BB chmod -R 0777 /sys/devices/system/cpu/;
$BB chmod -R 0777 /data/anr/;
$BB chmod 0744 /proc/cmdline;
$BB chmod -R 0770 /data/property/;
$BB chmod -R 0400 /data/tombstones;

# oom and mem perm fix
chmod 666 /sys/module/lowmemorykiller/parameters/cost;
chmod 666 /sys/module/lowmemorykiller/parameters/adj;

# enable force fast charge on USB to charge faster
echo "1" > /sys/kernel/fast_charge/force_fast_charge;
chmod 444 /sys/kernel/fast_charge/force_fast_charge;

# Disable ROM CPU controller
#mv /system/bin/mpdecision /system/bin/mpdecision.disabled
#pkill -f "/system/bin/mpdecision";

echo "1" > /sys/devices/system/cpu/cpu1/online;
echo "1" > /sys/devices/system/cpu/cpu2/online;
echo "1" > /sys/devices/system/cpu/cpu3/online;

# make sure we own the device nodes
chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
chown system /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias
chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
#chown system /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
#chown system /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
#chown system /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
#chown system /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
#chown system /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
#chown system /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
chown root.system /sys/devices/system/cpu/cpu1/online
chown root.system /sys/devices/system/cpu/cpu2/online
chown root.system /sys/devices/system/cpu/cpu3/online
chmod 666 /sys/devices/system/cpu/cpu1/online
chmod 666 /sys/devices/system/cpu/cpu2/online
chmod 666 /sys/devices/system/cpu/cpu3/online
chmod 666 /sys/module/intelli_plug/parameters/*

chown -R root:root /data/property;
chmod -R 0700 /data/property

# some nice thing for dev
if [ ! -e /cpufreq ]; then
        $BB ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
        $BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;
fi;

#for no_debug in $(find /sys/ -name *debug*); do
#       echo "0" > "$no_debug";
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
#        echo 0 > /sys/module/pm_8x60/modes/cpu1/retention/idle_enabled
#        echo 0 > /sys/module/pm_8x60/modes/cpu2/retention/idle_enabled
#        echo 0 > /sys/module/pm_8x60/modes/cpu3/retention/idle_enabled
fi

# set minimum frequencies
echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
#echo 300000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
#echo 300000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
#echo 300000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq

echo 0 > /sys/module/msm_thermal/core_control/enabled
echo 1 > /dev/cpuctl/apps/cpu.notify_on_migrate

# Tweak some VM settings for system smoothness
echo 20 > /proc/sys/vm/dirty_background_ratio
echo 40 > /proc/sys/vm/dirty_ratio

# set ondemand GPU governor as default
echo ondemand > /sys/devices/fdb00000.qcom,kgsl-3d0/kgsl/kgsl-3d0/pwrscale/trustzone/governor

# set default readahead
echo 1024 > /sys/block/mmcblk0/bdi/read_ahead_kb
echo 1024 > /sys/block/mmcblk0/queue/read_ahead_kb

# make sure our max gpu clock is set via sysfs
echo 450000000 > /sys/class/kgsl/kgsl-3d0/max_gpuclk

lgodl_prop=$(getprop persist.service.lge.odl_on)
if [ "$lgodl_prop" == "true" ]; then
        start lg_dm_dev_router
fi

# correct decoder support
setprop lpa.decode false

# Fix ROM dev wrong sets.
setprop persist.adb.notify 0
setprop persist.service.adb.enable 1
setprop dalvik.vm.execution-mode int:jit
setprop pm.sleep_mode 1

# fix owners on critical folders
$BB chown -R root:root /tmp;
$BB chown -R root:root /res;
$BB chown -R root:root /sbin;
$BB chown -R root:root /lib;

PIDOFINIT=$(pgrep -f "/sbin/ext/post-init.sh");
for i in $PIDOFINIT; do
	echo "-600" > /proc/"$i"/oom_score_adj;
done;

if [ ! -d /data/.dori ]; then
	$BB mkdir -p /data/.dori;
fi;

# reset config-backup-restore
if [ -f /data/.dori/restore_running ]; then
	rm -f /data/.dori/restore_running;
fi;

# reset profiles auto trigger to be used by kernel ADMIN, in case of need, if new value added in default profiles
# just set numer $RESET_MAGIC + 1 and profiles will be reset one time on next boot with new kernel.
RESET_MAGIC=3;
if [ ! -e /data/.dori/reset_profiles ]; then
	echo "0" > /data/.dori/reset_profiles;
fi;
if [ "$(cat /data/.dori/reset_profiles)" -eq "$RESET_MAGIC" ]; then
	echo "no need to reset profiles";
else
	rm -f /data/.dori/*.profile;
	echo "$RESET_MAGIC" > /data/.dori/reset_profiles;
fi;

[ ! -f /data/.dori/default.profile ] && cp -a /res/customconfig/default.profile /data/.dori/default.profile;
[ ! -f /data/.dori/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.dori/battery.profile;
[ ! -f /data/.dori/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.dori/performance.profile;
[ ! -f /data/.dori/extreme_performance.profile ] && cp -a /res/customconfig/extreme_performance.profile /data/.dori/extreme_performance.profile;
[ ! -f /data/.dori/extreme_battery.profile ] && cp -a /res/customconfig/extreme_battery.profile /data/.dori/extreme_battery.profile;

$BB chmod -R 0777 /data/.dori/;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

# Apps and ROOT Install
$BB sh /sbin/ext/install.sh;

# busybox addons
if [ -e /system/xbin/busybox ] && [ ! -e /sbin/ifconfig ]; then
	$BB ln -s /system/xbin/busybox /sbin/ifconfig;
fi;

######################################
# Loading Modules
######################################
(
	sleep 20;
	# order of modules load is important

	if [ "$cifs_module" == "on" ]; then
		if [ -e /system/lib/modules/cifs.ko ]; then
			$BB insmod /system/lib/modules/cifs.ko;
		else
			$BB insmod /lib/modules/cifs.ko;
		fi;
	fi;
)&

# enable kmem interface for everyone by GM
echo "0" > /proc/sys/kernel/kptr_restrict;

# disable debugging on some modules
if [ "$logger" == "off" ]; then
	echo "0" > /sys/module/kernel/parameters/initcall_debug;
	echo "0" > /sys/module/alarm/parameters/debug_mask;
	echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
	echo "0" > /sys/module/binder/parameters/debug_mask;
	echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
fi;

# for ntfs automounting
mkdir /mnt/ntfs
mount -t tmpfs -o mode=0777,gid=1000 tmpfs /mnt/ntfs

OPEN_RW;

(
	COUNTER=0;
	echo "0" > /tmp/uci_done;
	$BB chmod 666 /tmp/uci_done;

	while [ "$(cat /tmp/uci_done)" != "1" ]; do
		if [ "$COUNTER" -ge "40" ]; then
			break;
		fi;
		pkill -f "com.gokhanmoral.stweaks.app";
		echo "Waiting For UCI to finish";
		sleep 3;
		COUNTER=$((COUNTER+1));
		# max 2min
	done;

        # Enable ROM CPU Controller
#	if [ "$(pgrep -f "mpdecision" | wc -l)" -eq "0" ]; then
#		mv /system/bin/mpdecision.disabled /system/bin/mpdecision
#		/system/bin/mpdecision --no_sleep --avg_comp &
#	fi;

	# Cortex parent should be ROOT/INIT and not STweaks
	nohup /sbin/ext/cortexbrain-tune.sh;
	CORTEX=$(pgrep -f "/sbin/ext/cortexbrain-tune.sh");
	echo "-900" > /proc/"$CORTEX"/oom_score_adj;

	# script finish here, so let me know when
	TIME_NOW=$(date)
	echo "$TIME_NOW" > /data/boot_log_dm
)&

(
	# stop uci.sh from running all the PUSH Buttons in stweaks on boot
	$BB mount -o remount,rw /;
	$BB chown -R root:system /res/customconfig/actions/;
	$BB chmod -R 6755 /res/customconfig/actions/;
	$BB mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
	$BB chmod 6755 /res/no-push-on-boot/*;

	# apply STweaks settings
	echo "booting" > /data/.dori/booting;
	chmod 777 /data/.dori/booting;
	pkill -f "com.gokhanmoral.stweaks.app";
	nohup $BB sh /res/uci.sh restore;
	UCI_PID=$(pgrep -f "/res/uci.sh");
	echo "-800" > /proc/"$UCI_PID"/oom_score_adj;
	OPEN_RW;
	echo "1" > /tmp/uci_done;

	# restore all the PUSH Button Actions back to there location
	$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	pkill -f "com.gokhanmoral.stweaks.app";

	# update cpu tunig after profiles load
	$BB rm -f /data/.dori/booting;

	# correct oom tuning, if changed by apps/rom
	$BB sh /res/uci.sh oom_config_screen_on "$oom_config_screen_on";
	$BB sh /res/uci.sh oom_config_screen_off "$oom_config_screen_off";
)&

(
	# ROOT activation if supersu used
	if [ -e /system/app/SuperSU.apk ] && [ -e /system/xbin/daemonsu ]; then
		if [ "$(pgrep -f "daemonsu" | wc -l)" -eq "0" ]; then
			/system/xbin/daemonsu --auto-daemon &
		fi;
	fi;
)&

(
	# Start any init.d scripts that may be present in the rom or added by the user
	if [ "$init_d" == "on" ]; then
		chmod 755 /system/etc/init.d/*;
		$BB run-parts /system/etc/init.d/;
	fi;
)&
