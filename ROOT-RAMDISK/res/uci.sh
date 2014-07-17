#!/sbin/busybox sh
# universal configurator interface
# by Gokhan Moral

# You probably won't need to modify this file
# You'll need to modify the files in /res/customconfig directory

BB=/sbin/busybox

/sbin/busybox mount -o remount,rw /;
/sbin/busybox mount -o remount,rw /system;

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;

case "${1}" in
	rename)
    	rename_profile "${2}" "${3}";
    ;;
	delete)
    	delete_profile "${2}";
    ;;
	select)
    	select_profile "${2}";
    ;;
	config)
    	print_config;
    ;;
	list)
    	list_profile;
    ;;
	apply)
		# stop uci.sh from running all the PUSH Buttons in stweaks on boot
		chmod -R 06755 /res/customconfig/actions/;
		$BB mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
		chmod 06755 /res/no-push-on-boot/*;
		$BB cp /res/no-push-on-boot/config_backup_restore /res/customconfig/actions/push-actions/;
		chmod 06755 /res/customconfig/actions/push-actions/config_backup_restore;

		apply_config;
		write_config;

		# restore all the PUSH Button Actions back to there location
		$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
		chmod 06755 /res/customconfig/actions/push-actions/*
	;;
	restore)
		apply_config;
	;;
	*)
		. ${ACTION_SCRIPTS}/${1} ${1} ${2} ${3} ${4} ${5} ${6};
		write_config;
	;;
esac;

