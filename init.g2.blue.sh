#!/system/bin/sh

# LGE_CHANGE_S [blue.park@lge.com] <For Blue Error Handler V1.4>
chmod 666 /data/dontpanic/bluelog.*
#cat /proc/kmsg >> /data/dontpanic/bluelog.txt &
chown system.system /data/dontpanic/bluelog.*

#LGE_CHAGNE_E [blue.park@lge.com]
