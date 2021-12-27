#!/bin/bash
patcheck() {
	# $1 = Old pattern
	# $2 = New pattern
	# $3 = Offset
	# $4 = Filename

	local old=`echo -ne $1 | hexdump -ve '1/1 "%.2x "'`
	local new=`echo -ne $2 | hexdump -ve '1/1 "%.2x "'`
	local len_old=`expr ${#1} / 4`
	local len_new=`expr ${#2} / 4`
	local cur_pat=`dd if=$4 bs=1 count=$len_old skip=$3 2>/dev/null | hexdump -ve '1/1 "%.2x "'`

	if [ "$old" != "$cur_pat" ]; then
		# Old pattern not there, maybe it equals new pattern
		if [ $len_old -ne $len_new ]; then
			cur_pat=`dd if=$4 bs=1 count=$len_new skip=$3 2>/dev/null | hexdump -ve '1/1 "%.2x "'`
		fi
		if [ "$new" = "$cur_pat" ]; then
			echo "Hunk at offset $3 already applied"
			return 0
		fi
		echo "Pattern at $3 does not match, aborted. Are you patching the correct file?"
		return 1
	fi
}

patfilcheck() {
	# $1 = File with old pattern
	# $2 = File with new pattern
	# $3 = Offset
	# $4 = Filename
	if [ ! -e $1 ]; then
		dialog --msgbox "Old pattern file $1 missing, is your patchset complete?" 0 0
		return 1
	fi
	if [ ! -e $2 ]; then
		dialog --msgbox "New pattern file $2 missing, is your patchset complete?" 0 0
		return 1
	fi

	local old=`hexdump -ve '1/1 "%.2x "' $1`
	local new=`hexdump -ve '1/1 "%.2x "' $2`
	local len_old=`wc -c < "$1"`
	local len_new=`wc -c < "$2"`
	local cur_pat=`dd if=$4 bs=1 count=$len_old skip=$3 2>/dev/null | hexdump -ve '1/1 "%.2x "'`

	if [ "$old" != "$cur_pat" ]; then
		# Old pattern not there, maybe it equals new pattern
		if [ $len_old -ne $len_new ]; then
			cur_pat=`dd if=$4 bs=1 count=$len_new skip=$3 2>/dev/null | hexdump -ve '1/1 "%.2x "'`
		fi
		if [ "$new" = "$cur_pat" ]; then
			echo "Hunk at offset $3 already applied"
			return 0
		fi
		echo "Pattern at $3 does not match, aborted. Are you patching the correct file?"
		return 1
	fi
}

patreplace() {
	# $1 = Old pattern
	# $2 = New pattern
	# $3 = Offset
	# $4 = Filename

	echo -ne $2 | dd conv=notrunc of=$4 bs=1 seek=$3
}

patfilreplace() {
	# $1 = File with old pattern
	# $2 = File with new pattern
	# $3 = Offset
	# $4 = Filename

	dd conv=notrunc if=$2 of=$4 bs=1 seek=$3
}


checkparam() {
	if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
		if [ ! -z $2 ] && [ -e $2 ]; then
			return 0
		else
			echo "Invalid filename $2 given, does not exist?"
			return 1
		fi
	else
		echo Invalid offset given: $1
		return 1
	fi
}
