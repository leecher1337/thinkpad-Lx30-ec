#!/bin/sh
if ! command -v remaster.sh &> /dev/null
then
  tce-load -wi ezremaster.tcz
fi

tools_dir=/home/tc/tinycore/`uname -m`
tpl_dir=/tmp/mydata
rm -rf $tpl_dir 2>/dev/null
mkdir -p $tpl_dir/home/tc/fwpat
mkdir -p $tpl_dir/sbin
mkdir -p $tpl_dir/lib/modules/$(uname -r)/kernel/drivers/acpi/
cp -r /home/tc/fwpat $tpl_dir/home/tc/
cp /home/tc/.profile $tpl_dir/home/tc/
echo "cd /home/tc/fwpat" >>$tpl_dir/home/tc/.profile
echo "sudo bash patchui.sh" >>$tpl_dir/home/tc/.profile
cp $tools_dir/flashrom $tpl_dir/sbin/
cp $tools_dir/npce885crc $tpl_dir/sbin/
cp $tools_dir/x2100-ec-sys.ko $tpl_dir/lib/modules/$(uname -r)/kernel/drivers/acpi/
curdir=$PWD
cd $tpl_dir
tar -czvf /tmp/mydata.tgz *
cd $curdir
rm -rf $tpl_dir 2>/dev/null

remaster.sh /home/tc/tinycore/ezremaster.cfg rebuild
sh ./rebuild_uefi.sh ezremaster.cfg
