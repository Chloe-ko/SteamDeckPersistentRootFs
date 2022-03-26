#!/bin/sh
# Persistent overlay rootfs for SteamOS
# Version: 0.1

loglevel="99"
write_log(){
    [ ! "$loglevel" = "99" ] || echo "[overlayRoot.sh]" "WARNING: loglevel not initialized."
    [ "$loglevel" -lt "$1" ] || echo "[overlayRoot.sh]" "$2"
}
fail(){
        write_log 2 "$1"
        write_log 2 "$1" 'there is something wrong with overlayRoot.sh. type "exit" and press enter to ignore and continue.'
        if ! /bin/sh ; then
            exit 1
        fi
}

# mount /proc
if ! mount | grep -x 'proc on /proc type proc.*' > /dev/null ; then
    mount -t proc proc /proc || \
        fail "ERROR: could not mount proc"
fi

# check if overlayRoot is needed
for x in $(cat /proc/cmdline); do
    if [ "x$x" = "xquiet" ] ; then
        loglevel=0
    elif printf "%s\n" "$x" | grep -q "^loglevel=" ; then
        loglevel="$(printf "%s\n" "$x" | cut -d = -f 2-)"
    elif [ "x$x" = "xnoOverlayRoot" ] ; then
        write_log 6 "overlayRoot is disabled. continue init process."
        exec /sbin/init "$@"
    fi
done
if [ "$loglevel" = 99 ] ; then
    loglevel=4
fi

write_log 6 "create a writable fs to then create our mountpoints"
mount -t tmpfs inittemp /opt || \
    fail "ERROR: could not create a temporary filesystem to mount the base filesystems for overlayfs"
mkdir /opt/lower
mkdir /opt/overlay

#mount -t tmpfs root-rw /opt/overlay || \
mount -t ext4 /dev/disk/by-label/overlay /opt/overlay || \
    fail "ERROR: could not mount overlay partition for upper filesystem"
mkdir -p /opt/overlay/upper
mkdir -p /opt/overlay/work
mkdir -p /opt/newroot

# move original root
if ! mount -o "bind,ro" / /opt/lower ; then
    write_log 4 "WARNING: bind mount original root partition failed. Treating it as not mounted."
    originaRoot=""
fi

mount -t overlay -o index=off -o lowerdir=/opt/lower,upperdir=/opt/overlay/upper,workdir=/opt/overlay/work overlayfs-root /opt/newroot || \
    fail "ERROR: could not mount overlayFS"

write_log 6 "create mountpoints inside the new root filesystem-overlay"
mkdir -p /opt/newroot/lower
mkdir -p /opt/newroot/overlay

cd /opt/newroot
pivot_root . opt
exec chroot . sh -c "$(cat <<END
write_log(){
    [ "$loglevel" -lt "\$1" ] || echo "[overlayRoot.sh]" "\$2"
}
fail(){
    write_log 2 "\$1"
    write_log 2 "there is something wrong with overlayRoot.sh. type exit and press enter to ignore and continue."
    if ! /bin/sh ; then
        exit 1
    fi
}

write_log 6 "move ro, rw and other necessary mounts to the new root"
mount --move /opt/var/ /var || \
    fail "ERROR: could not move var into newroot"
mount --move /opt/etc/ /etc || \
    fail "ERROR: could not move etc into newroot"
mount --move /opt/opt/lower/ /lower || \
    fail "ERROR: could not move ro-root into newroot"
mount --move /opt/opt/overlay /overlay || \
    fail "ERROR: could not move tempfs rw mount into newroot"
chmod 755 /overlay
mount --move /opt/proc /proc || \
    fail "ERROR: could not move proc mount into newroot"
mount --move /opt/dev /dev || true
write_log 6 "unmount unneeded mounts so we can unmout the old readonly root"
mount | sed -E -e 's/^.* on //g' -e 's/ type .*\$//g' | grep -x '^/opt.*\$' | sort -r | while read xx ; do echo -ne "\$xx\0" ; done | xargs -0 -n 1 umount || \
    fail "ERROR: could not umount old root"
write_log 6 "move var to alternate mount"
mkdir -p /varoverlay
mount -t ext4 /dev/disk/by-label/varoverlay /varoverlay
mkdir -p /varoverlay/lower
mount --move /var /varoverlay/lower || \
    fail "ERROR: could not move var to varlower"
mkdir -p /varoverlay/work
mkdir -p /varoverlay/upper
write log 6 "mount var overlay"
mount -t overlay overlay -o index=off -o lowerdir=/varoverlay/lower,upperdir=/varoverlay/upper,workdir=/varoverlay/work /var || \
    fail "ERROR: could not mount overlayFS"
write_log 6 "continue with regular init"
#exec /bin/sh
mount -a
exec /sbin/init "\$@"
END
)" sh "$@"
