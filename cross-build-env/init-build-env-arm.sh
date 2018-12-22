#!/bin/sh

app_name="qemu-arm wget proot"
for app in "$app_name"; do
which $app > /dev/null || {
	if [ "$app" == "proot" ]; then
	echo "Please compile proot first, and copy it to the current directory"
	else
	echo "You need to install qemu-arm to run this script. On debian, run:\n\"sudo apt-get $app\""
	exit 1
	fi
}; done
PATH=`pwd`:$PATH
PKGS=`cat slackware-devel.txt | tr '\n' ',' | sed 's@,@*,@g' | sed 's/,[*]$//' | sed 's/,$//'`
echo PKGS "$PKGS"

# Get Slackware/ARM packages:
for DIR in a ap d e l n tcl; do
	wget -r -np -N --accept="$PKGS" http://ftp.arm.slackware.com/slackwarearm/slackwarearm-14.1/slackware/$DIR/ || exit 1
done

rm -rf slackwarearm-14.1
mkdir slackwarearm-14.1 || exit 1

# Extract only a minimal subset (ignore errors):
for DIR in a l; do
	ls ftp.arm.slackware.com/slackwarearm/slackwarearm-14.1/slackware/$DIR/*.t?z | xargs -n 1 tar -C slackwarearm-14.1 -x --exclude="dev/*" --exclude="lib/udev/devices/*" -f || exit 1
done

# Do a minimal post-installation setup:
mv slackwarearm-14.1/lib/incoming/* slackwarearm-14.1/lib/ || exit 1
mv slackwarearm-14.1/bin/bash4.new slackwarearm-14.1/bin/bash || exit 1
proot -q qemu-arm -S slackwarearm-14.1 /sbin/ldconfig || exit 1
proot -q qemu-arm -r slackwarearm-14.1 ln -s /bin/bash /bin/sh || exit 1

# Install all package correcty (ignore warnings):
ls ftp.arm.slackware.com/slackwarearm/slackwarearm-14.1/slackware/*/*.t?z | xargs -n 1 proot -q qemu-arm -S slackwarearm-14.1 -b ftp.arm.slackware.com /sbin/installpkg || exit 1
