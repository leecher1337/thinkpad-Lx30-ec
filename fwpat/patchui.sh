#!/bin/bash
chkfwver() {
	# $1 = file to check
	# $2 = offset to check

	local wanted_ver="G3HT40WW(1.14)"
	echo -n "Firmware version..."
	local ver=`dd if=$1 bs=1 count=14 skip=$2 2>/dev/null`
	if [ $ver != $wanted_ver ]; then
		echo Wrong firmware version $ver
		dialog --msgbox "Your firmware version $ver does not match the required version $wanted_ver. Please install firmware $wanted_ver and try again" 0 0
		return 1
	fi
	echo OK
	return 0
}

chkutil() {
	if ! command -v $1 &> /dev/null
	then
		dialog --msgbox "$1 utility is not installed but required. Please install $1 and try again." 0 0
		return 1
	fi
	return 0
}

applypat() {
	# $1 Patches
	# $2 Offset
	# $3 File to patch

	for i in $1
	do
		if [ ! -e patches/$i/patch.sh ]; then
			dialog --msgbox "patch directory patches/$i/patch.sh not found, is your patchset complete?" 0 0
			return 1
		fi
		pushd patches/$i
		bash patch.sh $2 $3
		if [ $? -ne 0 ]; then
			echo "Applying patch $i failed, maybe wrong firmware image? Aborting for your safety"
			echo "Press RETURN to continue"
			read
			popd
			return 1
		fi
		popd
	done
	return 0
}

hot() {
	# $1 = patches to apply
	clear

	echo Checking prereqisites...

	echo -n "x2100_ec_sys driver..."
	if [ -e /sys/module/x2100_ec_sys/parameters/write_support ]; then
		if [ `cat /sys/module/x2100_ec_sys/parameters/write_support` = N ]; then
			echo Write support in x2100_ec_sys not enabled, enabling...
			echo Y>/sys/module/x2100_ec_sys/parameters/write_support
		fi
	else
		modprobe x2100_ec_sys write_support=1
		if [ $? -ne 0 ]; then
			dialog --msgbox "Kernel module cannot be loaded. Check dmesg and ensure that it is installed. Aborting." 0 0
			return 1
		else
			echo Y>/sys/module/x2100_ec_sys/parameters/write_support
			echo "loaded kernel module"
		fi
	fi
	if [ ! -d /sys/kernel/debug/ec ]; then
		mount -t debugfs debugfs /sys/kernel/debug
		if [ ! -d /sys/kernel/debug/ec ]; then
			dialog --msgbox "Driver not found in debugfs, do you have a working debugfs?" 0 0
			return 1
		fi
	fi
	if [ -e /sys/kernel/debug/ec/ec0/ram ]; then
		echo OK
	else
		echo "ram file not found??"
		return 1
	fi

	chkfwver /sys/kernel/debug/ec/ec0/ram $((0x20060)) || return

	applypat "$1" 0 /sys/kernel/debug/ec/ec0/ram || return

	dialog --msgbox "Patch(es) applied." 0 0
	return 0
}

fw() {
	chkutil flashrom
	if [ ! -e layout ]; then
		dialog --msgbox "layout file missing, is your patchset complete?" 0 0
		return 1
	fi

	clear
	echo "Now Dumping your current firmware..."
	rm /tmp/current-bios.bin 2>/dev/null
	flashrom -p internal -l layout -r /tmp/current-bios.bin -i ec
	if [ $? -ne 0 ]; then
		echo "Flashrom failed dumping the image. Please take note of the output and "
		echo "press RETURN to exit"
		read
		return 1
	fi
	chkfwver /tmp/current-bios.bin $((0x400060)) || return

	applypat "$1" $((0x3e7f00)) /tmp/current-bios.bin || return

	dialog --yesno "EC ROM prepared. Are you sure that you want to flash it back to ROM now?" 0 0 || return

	clear
	flashrom -p internal -l layout -w /tmp/current-bios.bin -i ec
	local ret=$?
	echo "Please check output of flashrom and press RETURN to quit"
	read
	rm /tmp/current-bios.bin

	exit $ret
}

# Patch original BIOS FL1 files
fl1() {
	# $1 Patches
	# $2 FL1 File to patch
	chkfwver "$2" $((0x00400230)) || return

	applypat "$1" $((0x004001d0+0x8000-0x20100)) "$2" || return
}

# Create Patchset for thinkpad-ec
hexpatchset()
{
	# $1 Patches
	# $2 FL1 File containing BIOS
	# $3 Target dir
	local bn=`basename $2`
	dd if=$2 of=/tmp/$bn.img bs=1 count=$((0x20000)) skip=$((0x004001d0))
	chkfwver /tmp/$bn.img $((0x60)) || return
	hexdump -C /tmp/$bn.img >/tmp/$bn.hex
	for i in $1
	do
		cp -f /tmp/$bn.img /tmp/$bn.$i
		applypat "$i" $((0x8000-0x20100)) /tmp/$bn.$i
		hexdump -C /tmp/$bn.$i >/tmp/$bn.$i.hex
		case $i in
			kb)
				fn=001_keysym.patch
				;;
			bat)
				fn=006_battery_validate.patch
				;;
			*)
				fn=$bn.$i.patch
				;;
		esac
		diff -Naur /tmp/$bn.hex /tmp/$bn.$i.hex >$3/$fn
		rm -f /tmp/$bn.$i.hex
		rm -f /tmp/$bn.$i
	done
	rm -f /tmp/$bn.hex
	rm -f /tmp/$bn.img
}

# Creates a patch directory for thinkpad_ec project
thinkpadec() {
	# $1 thinkpad_ec directory

	local img=g3uj25us
	pushd $1
	make $img.iso.orig
	make $img.iso.orig.extract
	popd
	mkdir $1/l430.G3HT40WW.img.d/ 2>/dev/null
	hexpatchset "kb bat" $1/$img.iso.orig.extract/FLASH/*/\$01D4000.FL1 $1/l430.G3HT40WW.img.d/
	for i in 002_dead_keys.patch 003_keysym_replacements.patch 004_fn_keys.patch 005_fn_key_swap.patch
	do
		touch $1/l430.G3HT40WW.img.d/$i
	done
	rm -rf $1/$img.iso.orig.extract
}


patchtype() {
	while : ; do
		method=`dialog --help-button --menu "How to patch?" 0 0 0 \
			hot "Hotpatch in memory only" \
			fw "Patch and reflash firmware" \
			3>&1 1>&2 2>&3`
		case $? in
		2)
			case $method in 
				"HELP hot")
					dialog --msgbox "Advantage:
No permanent changes to EC firmware, if it causes bad side effects,
you just need to remove battery and power to reset EC back to stock firmware.

Disadvantage:
It only lasts as long as there is enough power so the EC doesn't shut down,
so you have to redo it after every power outage" 0 0
				;;
				"HELP fw")
					dialog --msgbox "Advantage:
Survives even power-off and battery removal, so loads again on EC-reinitialization.
This is a permanent fix. At least in theory. 

Currently, flashrom does not work for stock firmware, so this usually fails.

Disadvantage:
You have to re-flash your EC firmware. If something goes wrong, you may end up
with a bricked machine. Do this at your own risk. If something goes wrong, do not
complain!" 0 0
					;;
			esac
			;;
		1)
			return 1
			;;
		0)
			$method "$1"
			return $?
			;;
		esac
	done
}

mainmenu() {
	while : ; do
		patches=`dialog --help-button --checklist "EC patches to apply" 0 0 2 \
			kb "Classic 7-row keyboard keymap" off\
			bat "Disable check for genuine battery" on \
			3>&1 1>&2 2>&3`
		case $? in
		2)
			local tok=($patches)
			dialog --textbox patches/${tok[1]}/help.txt 0 0
			;;
		1)
			break
			;;
		0)
			if [ -z "$patches" ]; then
				dialog --msgbox "Please select at least one patch to apply" 0 0
			else
				patchtype "$patches"
				if [ $? -eq 0 ]; then break; fi
			fi
			;;
		esac
	done
}

if ! command -v dialog &> /dev/null
then
	echo dialog utility is needed, install dialog and try again
	exit 1
fi
for i in dd hexdump
do
	chkutil $i || exit 1
done

if [ -z $1 ]; then
	mainmenu
	echo If you want to power off the system, enter
	echo
	echo exitcheck.sh
	echo
else
	if [ $1 = thinkpadec ] && [ ! -z $2 ]; then
		thinkpadec $2
	else
		echo $0 \[thinkpadec\ \<dir\>]
		echo
		echo Without arguments, calls interactive menu for live patching
		echo thinkpadec \<dir\>  - Create patchset for thinkpad_ec which is intalled in \<dir\>
		echo
		exit 1
	fi
fi

exit 0
