#!/bin/bash

# Global variables defining the EC image:
cfg_offs_rom_code=$((0x8000))     # Offset of code that gets loaded at memory location 20100 in EC ROM image upon loading (as seen by the EC)
cfg_addr_mem_code=$((0x20000))    # Memory location of code including header
cfg_offs_mem_code=$((0x100))      # Offset of start of code in memory
cfg_size_mem_code=$((0x20000))    # Size of code segment in memory

realpath() { echo $(cd $(dirname $1); pwd)/$(basename $1); }

loadcfg() {
	# $1 Model
	. models/$1/config.sh

	# Start of code in RAM (as seen by the EC) -> 20100
	addr_mem_code=$((cfg_addr_mem_code+cfg_offs_mem_code))

	# Offset in firmware images to patch (Layout in SPI EEPROM relative to EC mem Layout, so: EC mem addr + offs_rom_mem_code = SPI EEPROM addr)
	offs_rom_mem_code=$((cfg_offs_rom_ec+cfg_offs_rom_code-addr_mem_code))
}

chkfwver() {
	# $1 = file to check
	# $2 = offset to check

	echo -n "Firmware version..."
	local ver=`dd if=$1 bs=1 count=14 skip=$2 2>/dev/null`
	if [ $ver != $cfg_stri_fwver ]; then
		echo Wrong firmware version $ver
		dialog --msgbox "Your firmware version $ver does not match the required version $cfg_stri_fwver. Please install firmware $cfg_stri_fwver and try again" 0 0
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
	# $1 Model
	# $2 Patches
	# $3 Offset
	# $4 File to patch

	for i in $2
	do
		if [ ! -e models/$1/patches/$i/patch.sh ]; then
			dialog --msgbox "patch directory models/$1/patches/$i/patch.sh not found, is your patchset complete?" 0 0
			return 1
		fi
		pushd models/$1/patches/$i >/dev/null
		bash patch.sh $3 $4
		if [ $? -ne 0 ]; then
			echo "Applying patch $i failed, maybe wrong firmware image? Aborting for your safety"
			echo "Press RETURN to continue"
			read
			popd
			return 1
		fi
		popd >/dev/null
	done
	return 0
}

hot() {
	# $1 Model
	# $2 Patches to apply
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

	chkfwver /sys/kernel/debug/ec/ec0/ram $cfg_offs_mem_fwver || return

	applypat $1 "$2" 0 /sys/kernel/debug/ec/ec0/ram || return

	dialog --msgbox "Patch(es) applied." 0 0
	return 0
}

fw() {
	# $1 Model
	# $2 Patches to apply
	chkutil flashrom
	if [ ! -e layout ]; then
		dialog --msgbox "layout file missing, is your patchset complete?" 0 0
		return 1
	fi

	clear
	echo "Now Dumping your current firmware..."
	rm /tmp/current-bios.bin 2>/dev/null
	flashrom -p internal -l models/$1/layout -r /tmp/current-bios.bin -i ec
	if [ $? -ne 0 ]; then
		echo "Flashrom failed dumping the image. Please take note of the output and "
		echo "press RETURN to exit"
		read
		return 1
	fi
	chkfwver /tmp/current-bios.bin $((offs_rom_mem_code+cfg_offs_mem_fwver)) || return

	applypat $1 "$2" $offs_rom_mem_code /tmp/current-bios.bin || return

	dialog --yesno "EC ROM prepared. Are you sure that you want to flash it back to ROM now?" 0 0 || return

	clear
	flashrom -p internal -l models/$1/layout -w /tmp/current-bios.bin -i ec
	local ret=$?
	echo "Please check output of flashrom and press RETURN to quit"
	read
	rm /tmp/current-bios.bin

	exit $ret
}

# Patch original BIOS FL1 files
fl1() {
	# $1 Model
	# $2 Patches
	# $3 FL1 File to patch
	loadcfg "$1"
	chkfwver "$3" $((offs_rom_mem_code+cfg_offs_img_rom+cfg_offs_mem_fwver)) || return

	applypat "$1" "$2" $((offs_rom_mem_code+cfg_offs_img_rom)) "$3" || return
}

# Create Patchset for thinkpad-ec
hexpatchset()
{
	# $1 Model
	# $2 Patches
	# $3 FL1 File containing BIOS
	# $4 Target dir
	loadcfg $1
	local bn=`basename $3`
	dd if=$3 of=/tmp/$bn.img bs=1 count=$cfg_size_mem_code skip=$((cfg_offs_rom_ec+cfg_offs_img_rom))
	chkfwver /tmp/$bn.img $((cfg_offs_rom_code-addr_mem_code+cfg_offs_mem_fwver)) || return
	hexdump -C /tmp/$bn.img >/tmp/$bn.hex
	for i in $2
	do
		cp -f /tmp/$bn.img /tmp/$bn.$i
		applypat $1 "$i" $((cfg_offs_rom_code-addr_mem_code)) /tmp/$bn.$i
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
	pushd $1 >/dev/null
	make $img.iso.orig
	make $img.iso.orig.extract
	popd >/dev/null
	mkdir $1/l430.G3HT40WW.img.d/ 2>/dev/null
	hexpatchset Lx30 "kb bat" $1/$img.iso.orig.extract/FLASH/*/\$01D4000.FL1 $1/l430.G3HT40WW.img.d/
	for i in 002_dead_keys.patch 003_keysym_replacements.patch 004_fn_keys.patch 005_fn_key_swap.patch
	do
		touch $1/l430.G3HT40WW.img.d/$i
	done
	rm -rf $1/$img.iso.orig.extract
}


patchtype() {
	# $1 model
	# $2 patches
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
			$method $1 "$2"
			return $?
			;;
		esac
	done
}

patchmenu() {
	# $1 Model
	declare -a args=()
	if [ -e models/$1/patches/kb ]; then args+=(kb "Classic 7-row keyboard keymap" off); fi
	if [ -e models/$1/patches/bat ]; then args+=(bat "Disable check for genuine battery" on); fi
	while : ; do
		patches=`dialog --help-button --checklist "EC patches to apply" 0 0 0 "${args[@]}" 3>&1 1>&2 2>&3`
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
				patchtype $1 "$patches"
				if [ $? -eq 0 ]; then break; fi
			fi
			;;
		esac
	done
}

mainmenu() {
	while : ; do
		model=`dialog --menu "Which Thinkpad model to patch?" 0 0 0 \
			Lx30 "Thinkpad L430/L530" \
			B590 "Thinkpad B590" \
			E330 "Thinkpad E330" \
			3>&1 1>&2 2>&3`
		case $? in
		1)
			break
			;;
		0)
			loadcfg $model
			patchmenu $model
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
	if [ $1 = fl1 ] && [ ! -z "$2" ] && [ ! -z "$3" ] && [ ! -z "$4" ]; then
		fl1 "$2" "$3" `realpath "$4"`
		exit $?
	fi
	if [ $1 = thinkpadec ] && [ ! -z "$2" ]; then
		thinkpadec "$2"
		exit 0
	fi
	echo $0 \[thinkpadec\ \<dir\>] \[fl1 \<model\> \<patches\> \<file\>\]
	echo
	echo Without arguments, calls interactive menu for live patching
	echo "thinkpadec - Create Lx30 patchset for thinkpad_ec which is installed in \<dir\>"
	echo "fl1        - Patches FL1 \<file\> with \<patches\> for \<model\>"
	echo "             i.e.: $0 Lx30 \"kb bat\" \$01D4000.FL1"
	echo 
	echo
	exit 1
fi

exit 0
