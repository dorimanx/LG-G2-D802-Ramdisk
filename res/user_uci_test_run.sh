#!/sbin/busybox sh
# universal configurator interface for user/dev/ testing.
# by Gokhan Moral and Voku and Dorimanx and Alucard24

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
mount -o remount,rw /;
mount -o remount,rw /system;
chown -R root:system /res/customconfig/actions/;
chmod -R 6755 /res/customconfig/actions/;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
chmod 6755 /res/no-push-on-boot/*;
cp /res/misc_scripts/config_backup_restore /res/customconfig/actions/push-actions/;
chmod 6755 /res/customconfig/actions/push-actions/config_backup_restore;

UCI_PID=`pgrep "user_uci_test_run.sh"`;
renice -n -15 -p $UCI_PID;

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# Disable ROM CPU Controller
mv /system/bin/mpdecision /system/bin/mpdecision.disabled
pkill -f "/system/bin/mpdecision";

echo "1" > /sys/devices/system/cpu/cpu1/online;
echo "1" > /sys/devices/system/cpu/cpu2/online;
echo "1" > /sys/devices/system/cpu/cpu3/online;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;
apply_config;
write_config;

# Enable ROM CPU Controller
if [ "$(pgrep -f "mpdecision" | wc -l)" -eq "0" ]; then
	mv /system/bin/mpdecision.disabled /system/bin/mpdecision
	/system/bin/mpdecision --no_sleep --avg_comp &
fi;

# restore all the PUSH Button Actions back to there location
mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
pkill -f "com.gokhanmoral.stweaks.app";
am start -a android.intent.action.MAIN -n com.gokhanmoral.stweaks.app/.MainActivity;

