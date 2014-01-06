#!/system/bin/sh

# added by StockMOD kernel, ramdisk script to reset some core VM and system values
# to more sane values, executed after any post-boot or init.d script that may be on the device

#re-set what no doubt has been changed by a rom script to more sensible values
echo 256 > /sys/block/mmcblk0/bdi/read_ahead_kb
#echo 800 > /proc/sys/vm/dirty_expire_centisecs
#echo 60 > /proc/sys/vm/dirty_ratio
#echo 40 > /proc/sys/vm/dirty_background_ratio
#echo 30 > /proc/sys/vm/vfs_cache_pressure

#set simple GPU governor as default, added by StockMOD kernel
# echo simple > /sys/devices/fdb00000.qcom,kgsl-3d0/kgsl/kgsl-3d0/pwrscale/trustzone/governor

#ondemand governor tweaks, performance/battery balance
echo 15000 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
echo 70 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
#echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_multi_core
#echo 50 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold_any_cpu_load


#we can set our own cpu sync frequencies below
# echo 1267000 > /sys/devices/system/cpu/cpufreq/ondemand/optimal_freq
# echo 1190000 > /sys/devices/system/cpu/cpufreq/ondemand/sync_freq


#disable built in kernel thermal core control in favour of userspace implementation
# echo 0 > /sys/module/msm_thermal/core_control/enabled