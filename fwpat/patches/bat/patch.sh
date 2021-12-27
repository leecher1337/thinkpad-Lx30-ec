#!/bin/bash
. ../../util/util.sh

# Patterns to patch
patches() {
	# $1 = Function to execute (patcheck or patreplace)
	# $2 = Offset
	# $3 = Filename

	$1 $"\x60\x7b\x01\x00\x9c\x11\x72\x5d\x22\x5f\x20\x55" $"\x60\x73\x01\x00\x50\x73\x01\x00\xe0\x18\x2c\x00" $((0x28cea+$2)) $3 || return
	$1 $"\x80\x18\xf6\x04" $"\xe0\x18\x5a\x00" $((0x28c68+$2)) $3 || return
	$1 $"\x30" "\xc0" $((0x28ade+$2)) $3 || return
	$1 $"\x00\x18\xec\x06" $"\xe0\x18\x54\x00" $((0x28a72+$2)) $3 || return
}

# $1 = Offset within file to patch
# $2 = Filename of file to patch
checkparam $1 $2 || exit 1
patches patcheck $1 $2 || exit 1
patches patreplace $1 $2 || exit 1
if [ $2 = /sys/kernel/debug/ec/ec0/ram ]; then
	# Kick state machine
	echo -ne "\x02" | dd of=$2 bs=1 seek=$((0x1004a))
fi
