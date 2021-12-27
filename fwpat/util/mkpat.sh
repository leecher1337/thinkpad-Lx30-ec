#!/bin/sh
# Creates a patch pattern for "previous" string
# $1 offset
# $2 size
dd if=/sys/kernel/debug/ec/ec0/ram bs=1 count=$2 skip=$1 2>/dev/null | hexdump -ve '"\\\x" 1/1 "%02x"'
echo
