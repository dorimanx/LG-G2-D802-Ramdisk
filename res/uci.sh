#!/sbin/busybox sh
# universal configurator interface
# by Gokhan Moral

# You probably won't need to modify this file
# You'll need to modify the files in /res/customconfig directory

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;

UCI_PID=`pgrep "uci.sh"`;
renice -n -15 -p $UCI_PID;

/sbin/busybox mount -o remount,rw /
/sbin/busybox mount -o remount,rw /system

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
		apply_config;
		write_config;
	;;
	restore)
		apply_config;
	;;
	*)
		. ${ACTION_SCRIPTS}/${1} ${1} ${2} ${3} ${4} ${5} ${6};
		write_config;
	;;
esac;

