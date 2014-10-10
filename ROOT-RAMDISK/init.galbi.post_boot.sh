#!/system/bin/sh
# Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

target=`getprop ro.board.platform`

setprop ro.config.xnihps "true"

case "$target" in
    "msm8974")
	if [ -d /sys/module/lpm_resources/enable_low_power ]; then
        	echo 4 > /sys/module/lpm_resources/enable_low_power/l2
        	echo 1 > /sys/module/lpm_resources/enable_low_power/pxo
        	echo 1 > /sys/module/lpm_resources/enable_low_power/vdd_dig
        	echo 1 > /sys/module/lpm_resources/enable_low_power/vdd_mem
	fi;
        echo 1 > /sys/module/msm_pm/modes/cpu0/power_collapse/suspend_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu1/power_collapse/suspend_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu2/power_collapse/suspend_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu3/power_collapse/suspend_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu0/power_collapse/idle_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu1/power_collapse/idle_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu2/power_collapse/idle_enabled
        echo 1 > /sys/module/msm_pm/modes/cpu3/power_collapse/idle_enabled
        echo 0 > /sys/module/msm_pm/modes/cpu0/retention/idle_enabled
        echo 0 > /sys/module/msm_pm/modes/cpu1/retention/idle_enabled
        echo 0 > /sys/module/msm_pm/modes/cpu2/retention/idle_enabled
        echo 0 > /sys/module/msm_pm/modes/cpu3/retention/idle_enabled
        echo 1 > /sys/devices/system/cpu/cpu1/online
        echo 1 > /sys/devices/system/cpu/cpu2/online
        echo 1 > /sys/devices/system/cpu/cpu3/online

        if [ -f /sys/devices/soc0/soc_id ]; then
            soc_id=`cat /sys/devices/soc0/soc_id`
        else
            soc_id=`cat /sys/devices/system/soc/soc0/id`
        fi
        case "$soc_id" in
            "208" | "211" | "214" | "217" | "209" | "212" | "215" | "218" | "194" | "210" | "213" | "216")
                echo 1 > /sys/module/cpubw_krait/parameters/enable
                echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
                echo "interactive" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
                echo "interactive" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
                echo "interactive" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
                echo "20000 1400000:40000 1700000:20000" > /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay
                echo 90 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
                echo 1497600 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
                echo "85 1500000:90 1800000:70" > /sys/devices/system/cpu/cpufreq/interactive/target_loads
                echo 40000 > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
                echo 20 > /sys/module/cpu_boost/parameters/boost_ms
                echo 1728000 > /sys/module/cpu_boost/parameters/sync_threshold
                echo 100000 > /sys/devices/system/cpu/cpufreq/interactive/sampling_down_factor
                echo 1497600 > /sys/module/cpu_boost/parameters/input_boost_freq
                echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
                setprop ro.qualcomm.perf.cores_online 2
            ;;
        esac

        chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
        chown system /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
        chown root.system /sys/devices/system/cpu/cpu1/online
        chown root.system /sys/devices/system/cpu/cpu2/online
        chown root.system /sys/devices/system/cpu/cpu3/online
        chmod 664 /sys/devices/system/cpu/cpu1/online
        chmod 664 /sys/devices/system/cpu/cpu2/online
        chmod 664 /sys/devices/system/cpu/cpu3/online
        echo 1 > /dev/cpuctl/apps/cpu.notify_on_migrate
	chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
	chown system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
	chown system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
    ;;
esac

emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot" in
    "true")
	if [ -d /sys/devices/platform/rs300000a7.65536 ]; then
        	chown system /sys/devices/platform/rs300000a7.65536/force_sync
        	chown system /sys/devices/platform/rs300000a7.65536/sync_sts
        	chown system /sys/devices/platform/rs300100a7.65536/force_sync
        	chown system /sys/devices/platform/rs300100a7.65536/sync_sts
	fi;
    ;;
esac

# Post-setup services
start mpdecision
echo 1024 > /sys/block/mmcblk0/bdi/read_ahead_kb
#include LGE POWER SAVE Feature
start gbmonitor

# Install AdrenoTest.apk if not already installed
if [ -f /data/prebuilt/AdrenoTest.apk ]; then
    if [ ! -d /data/data/com.qualcomm.adrenotest ]; then
        pm install /data/prebuilt/AdrenoTest.apk
    fi
fi

# Install SWE_Browser.apk if not already installed
if [ -f /data/prebuilt/SWE_Browser.apk ]; then
    if [ ! -d /data/data/org.codeaurora.swe.browser ]; then
        pm install /data/prebuilt/SWE_Browser.apk
    fi
fi

# 2013-10-07 ct-radio@lge.com LGP_DATA_TCPIP_NSRM [START]
targetProd=`getprop ro.product.name`
case "$targetProd" in
		"g2_lgu_kr" | "vu3_lgu_kr" | "z_lgu_kr" | "z_jp_kdi" | "g2_jp_kdi" | "b1_skt_kr" | "b1_lgu_kr" | "g3_kddi_jp" | "g3_lgu_kr" | "g3_skt_kr")
            mkdir /data/connectivity/
            chown system.system /data/connectivity/
            chmod 775 /data/connectivity/
            mkdir /data/connectivity/nsrm/
            chown system.system /data/connectivity/nsrm/
            chmod 775 /data/connectivity/nsrm/
            cp /system/etc/cne/NsrmConfiguration.xml /data/connectivity/nsrm/
            chown system.system /data/connectivity/nsrm/NsrmConfiguration.xml
            chmod 775 /data/connectivity/nsrm/NsrmConfiguration.xml
        ;;
esac

# 20120820 yoonki.hong@lge.com - heuristic power saving feature (IME) add
case "$target" in
    "msm8660" | "msm8960" | "msm8974")
        chown system /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias
     ;;
esac

#2013-05-13 Add clk and resume irq debug mask enable when userdebug mode image.
build_type=`getprop ro.build.type`
case "$build_type" in
    "userdebug" | "user" | "eng")
	if [ -e /sys/kernel/debug/clk/debug_suspend ]; then
        	echo 1 > /sys/kernel/debug/clk/debug_suspend
	fi;
        echo 1 > /sys/module/msm_show_resume_irq/parameters/debug_mask
    ;;
esac
#2013-05-13 Add clk and resume irq debug mask enable when userdebug mode image.


#2012-03-06 seongmook.yim(seongmook.yim@lge.com) [P6/MDMBSP] ADD LGODL [START]
lgodl_prop=`getprop persist.service.lge.odl_on`
if [ "$lgodl_prop" == "true" ]; then
    start lg_dm_dev_router
fi
#2012-03-06 seongmook.yim(seongmook.yim@lge.com) [P6/MDMBSP] ADD LGODL [END]

setprop ro.config.sphinx_rom_info "SphinX Base LGViet.com"

