# SteamDeckPersistentRootFs
A script made to enable use of a overlay as root filesystem on the Valve Steam Deck.
This allows you to make changes to the rootfs and not losing your changes on a Steam OS update

Heavily based on https://github.com/fitu996/overlayRoot.sh

# Installation

**Prerequisites:**

A partition formatted as ext4 with the label "overlay"\
This can be easily setup by booting into a GParted Live CD and shrinking your home partition to make space.

**Warning:** The first time I did this I had to re-format my home partition as Steam OS suddenly failed to install games.\
However, at the same time, I did a bunch of other things with my partitions so I am unsure whether it was caused by the shrinking, or something else.\
If someone would be willing to try this and see if just the shrinking the home partition causes this issue, it'd be greatly appreciated.

**Installation:**

1. Download the overlayRoot.sh script into your /var directory.\
The reason we use /var is that the usual places to store executables in are all in the rootfs, and would be wiped on update.\
/var is a separate partition and data on in persistently stays across updates.

2. Make the script be executable by running `sudo chmod +x /var/overlayRoot.sh`

3. Edit the file `/etc/default/grub` with your preferred editor, and append `init=/var/overlayRoot.sh` to the `GRUB_CMDLINE_LINUX` variable.\
**Optional, but highly recommended:** Change `GRUB_TIMEOUT` and `GRUB_RECORDFAIL_TIMEOUT` from 0 to 10 or 5\
This is so that grub is always shown at boot up, which will be needed in case you want to uninstall this, or if you encounter issues and need to disable it.

4. Run `sudo update-grub`. This might show an error about lacking write rights, but this can be safely ignored.

5. Reboot

6. Confirm that it is working by running `df -h` and making sure the entry that is mounted on `/` is of filesystem type `overlayfs-root`

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

5. Run `sudo update-grub`. Now the boot progress is changed back to not use this script, and you can if wanted delete it from /var.\
As the current boot was made without this script enabled in the first place, there's no need to reboot.

# Bugs

You tell me. Issues, ideas for improvement and pull requests are gladly welcome.
