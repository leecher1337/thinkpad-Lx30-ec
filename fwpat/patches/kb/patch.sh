#!/bin/bash
. ../../util/util.sh

# Patterns to patch
patches() {
	# $1 = Function to execute (patcheck or patreplace)
	# $2 = Offset
	# $3 = Filename

	$1 $"\x00\x04\x01\x04" $"\x38\x01\x30\x01" $((0x35f9e+$2)) $3 || return
}

filepatches() {
	# $1 = Function to execute (patfilcheck or patfilreplace)
	# $2 = Offset
	# $3 = Filename

	$1 kbmap.orig kbmap.new $((0x366bd+$2)) $3 || return
}

# $1 = Offset within file to patch
# $2 = Filename of file to patch
checkparam $1 $2 || exit 1
patches patcheck $1 $2 || exit 1
filepatches patfilcheck $1 $2 || exit 1
patches patreplace $1 $2 || exit 1
filepatches patfilreplace $1 $2 || exit 1
