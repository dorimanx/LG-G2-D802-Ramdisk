#!/sbin/busybox sh

mkdir /mnt/asec;
chown root:system /mnt/asec;
chmod 0700 /mnt/asec;
/sbin/busybox mount -t tmpfs -o mode=0755,gid=1000 tmpfs /mnt/asec

