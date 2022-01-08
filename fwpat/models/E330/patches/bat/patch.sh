#!/bin/bash
. ../../../../util/util.sh

# Patterns to patch
patches() {
	# $1 = Function to execute (patcheck or patreplace)
	# $2 = Offset
	# $3 = Filename

	$1 $"\x62\x7b\x01\x00\x94\x10\xb0\x20\xfe\xff\xe2\x10" $"\x62\x73\x01\x00\x52\x73\x01\x00\x00\x2c\x00\x2c" $((0x28a7a+$2)) $3 || return
	$1 $"\x80\x18\xc4\x02" $"\x00\x2c\x00\x2c" $((0x28a62+$2)) $3 || return
	$1 $"\x30" "\xc0" $((0x288d8+$2)) $3 || return
	$1 $"\x00\x18\xba\x04" $"\xe0\x18\x54\x00" $((0x2886c+$2)) $3 || return
}

# $1 = Offset within file to patch
# $2 = Filename of file to patch
checkparam $1 $2 || exit 1
patches patcheck $1 $2 || exit 1
patches patreplace $1 $2 || exit 1
if [ $2 = /sys/kernel/debug/ec/ec0/ram ]; then
	# Kick state machine
	echo -ne "\x02" | dd of=$2 bs=1 seek=$((0x10082))
fi
