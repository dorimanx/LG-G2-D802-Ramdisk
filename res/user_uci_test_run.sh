#!/sbin/busybox sh
# universal configurator interface for user/dev/ testing.
# by Gokhan Moral and Voku and Dorimanx and Alucard24

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
/sbin/busybox mount -o remount,rw /;
/sbin/busybox mount -o remount,rw /system;
chown -R root:system /res/customconfig/actions/;
chmod -R 6755 /res/customconfig/actions/;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
chmod 6755 /res/no-push-on-boot/*;
/sbin/busybox cp /res/misc_scripts/config_backup_restore /res/customconfig/actions/push-actions/;
chmod 6755 /res/customconfig/actions/push-actions/config_backup_restore;

UCI_PID=`pgrep "user_uci_test_run.sh"`;
renice -n -15 -p $UCI_PID;

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;
apply_config;
write_config;

# restore all the PUSH Button Actions back to there location
mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
pkill -f "com.gokhanmoral.stweaks.app";
/system/bin/am start -a android.intent.action.MAIN -n com.gokhanmoral.stweaks.app/.MainActivity;

