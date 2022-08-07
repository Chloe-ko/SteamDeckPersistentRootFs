# SteamDeckPersistentRootFs
A script made to enable use of a overlay as root filesystem on the Valve Steam Deck.
This allows you to make changes to the rootfs and not losing your changes on a Steam OS update

Heavily based on https://github.com/fitu996/overlayRoot.sh

# Important Note
While I will leave this repo here for anyone that wants to use it, I actually personally discourage people from using this.\
When creating this I wanted a way to keep changes on my deck persistent, but this is actually a very flawed solution.\
This is mostly due to the fact that overlayfs is meant to be used on top of a *non-changing* RO partition.\
After using this for multiple months, I've come across multiple issues with my Deck that mostly stem from the fact that if Valve updates something in SteamOS that we previously changed, overlayFS will cause the updated file to be "overwritten" using the old, changed one.
YMMV, but for me this led to some functions breaking after using this script over multiple Deck updates.

# Installation

**Prerequisites:**

- **A partition formatted as ext4 with the label `overlay`**\
\
This can be easily setup by booting into a GParted Live CD and shrinking your home partition to make space.
https://sourceforge.net/projects/gparted/files/gparted-live-stable/ \
Downloading the latest .iso here, you can put it onto a USB stick using Rufus or Balena Etcher, and then boot the Deck into it by holding the Volume Down button as you power it on and select the USB as bootable drive.\
There is enough info on how to partition drives online.\
\
The size of this partition is up to you, and can be increased later on. But do keep in mind that this partition needs to hold all the packages you manually install and any other changes you make to the rootfs.

- **A partition formatted as ext4 with the label `varoverlay`**\
\
/var is not part of the rootfs that gets overwritten on update, but it is part of the A/B partition scheme.\
Manual changes to /var need to be persistent with changes to the rootfs, hence why there's also an overlay for this that can be applied to var-a as well as var-b.\
\
This partition can be as big as you want it to be, aswell. I'd recommend ~250MB, as /var mostly holds keys and configurations, so no big files will be saved here.

**Installation:**

1. Download the overlayRoot.sh script into your /var directory.\
The reason we use /var is that the usual places to store executables in are all in the rootfs, and would be wiped on update.\
However, do consider that this script should be placed in var-a aswell as var-b.
You can just put it in var, and then run these commands to mount the currently not-active var partition and copy it over:
    ```
    sudo su -
    mkdir /root/othervar
    mount -t ext4 /dev/disk/by-partsets/other/var /root/othervar
    cp /var/overlayRoot.sh /root/othervar
    chmod +x /root/othervar/overlayRoot.sh
    umount /root/othervar
    rm /root/othervar -R
    exit
    ```

2. Make the script be executable by running `sudo chmod +x /var/overlayRoot.sh`

3. Edit the file `/etc/default/grub` with your preferred editor, and append `init=/var/overlayRoot.sh` to the `GRUB_CMDLINE_LINUX` variable.\
**Optional, but highly recommended:** Change `GRUB_TIMEOUT` and `GRUB_RECORDFAIL_TIMEOUT` from 0 to 10 or 5\
This is so that grub is always shown at boot up, which will be needed in case you want to uninstall this, or if you encounter issues and need to disable it.

4. Run `sudo steamos-readonly disable` to disable the write-protection of the root file system.

5. Run `sudo update-grub`. Optional: After this is done, run `sudo steamos-readonly enable` to restore the write protection of the rootfs.

6. Reboot

7. Confirm that it is working by running `df -h` and making sure the entry that is mounted on `/` is of filesystem type `overlayfs-root`

8. Optionally, in `/etc/pacman.conf`, uncomment and change your cache directory from `CacheDir = /var/cache/pacman/pkg/` to `CacheDir = /tmp/cache/pacman/pkg/`. This is to avoid some problems with installation of some larger packages.

# Restore
Sometimes, an update will disable overlayRoot.sh\
To restore it, run these 3 commands:

1. Disable write protection\
`sudo steamos-readonly disable`

2. Update the grub config\
`sudo update-grub`

3. Re-enable write protection if wanted\
`sudo steamos-readonly enable`

# Uninstall

**Important:** As of right now the most convenient way I can think of to uninstall this still requires connecting an external keyboard.

In order to uninstall this, you have to first boot into a one-time session with overlayfs disabled.\
Then change the grub default config again, and update grub to no longer use this as init script.

1. When booting up your Steam deck, while the GRUB boot menu is shown, press E on a connected keyboard while "Steam OS" is highlighted.

2. In the now opened editor, press your arrow down key until you arrive at the line that starts with "steamenv_boot"\
Now, press the right arrow key until you arrive at the part that says `init=/var/overlayRoot.sh`, and delete that part.\
Make sure not to accidentally delete anything else.

3. Press `CTRL + X` to boot.

4. Once booted up, edit `/etc/default/grub` and remove the `init=/var/overlayRoot.sh`. Optionally, also set the timeouts back to 0.

5. Run `sudo steamos-readonly disable` to disable the write protection of the rootfs.

6. Run `sudo update-grub`. Now the boot progress is changed back to not use this script, and you can if wanted delete it from /var.\
As the current boot was made without this script enabled in the first place, there's no need to reboot.

Optional:

7. Run `sudo steamos-readonly enable` to restore the write protection of the rootfs.

8. If you've changed the CacheDir in `/etc/pacman.conf` before, comment it back out or simply change it back to it's original value.

# Bugs

You tell me. Issues, ideas for improvement and pull requests are gladly welcome.
There is to consider that if a file you modified gets updated, your modified file might "overlay" the updated one, and could cause issues by being too old.
However without more long-term testing it's hard to tell if this is a realistic situation to happen or not.
