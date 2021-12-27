#!/bin/sh -x

if [ -z $1 ]; then
  if [ -f ./ezremaster.cfg ]; then
    cfg=./ezremaster.cfg
  else
    echo Usage: $0 ezremaster.cfg
    echo
    echo Normal Bootimage must have been created with remaster.sh already
    exit 1
  fi
else
  cfg=$1
fi

if ! command -v mkfs.msdos &> /dev/null
then
  tce-load -wi dosfstools
fi

temp_dir=`grep "^temp_dir = " $cfg | awk '{print $3}'`
tools_dir=/home/tc/tinycore/`uname -m`
image_dir=$temp_dir/image
uefiimg_dir=$temp_dir/uefi-image
esp_dir=$temp_dir/mnt2
#grub_dir=/boot/grub
grub_dir=EFI/ubuntu/

mkdir -p $uefiimg_dir/efi
mkdir -p $uefiimg_dir/$grub_dir
sudo cp -r $image_dir/* $uefiimg_dir/
cp $tools_dir/grub.cfg $uefiimg_dir/$grub_dir

sudo chmod 666 $uefiimg_dir/boot/isolinux/isolinux.bin
dd if=/dev/zero of=$uefiimg_dir/efi/esp.img bs=$((`wc -c < "$tools_dir/../grubx64.efi"`+131072)) count=1
mkfs.msdos -F 12 -f 1 -r 112 -R 1 $uefiimg_dir/efi/esp.img
# mkfs.msdos of tce isn't very advanced, so change media descriptor manually
echo -ne "\xF0" | dd conv=notrunc of=$uefiimg_dir/efi/esp.img bs=1 seek=21
mkdir $esp_dir
sudo mount $uefiimg_dir/efi/esp.img $esp_dir
sudo mkdir -p $esp_dir/$grub_dir
sudo mkdir -p $esp_dir/efi/boot
sudo cp $tools_dir/../grubx64.efi $esp_dir/efi/boot/bootx64.efi
sudo cp $tools_dir/grub.cfg $esp_dir/$grub_dir
sudo umount $esp_dir
rmdir $esp_dir

output_file=$temp_dir/ezremaster-uefi.iso
$tools_dir/mkisofs -l -J -R \
  -V FWPATCH \
  -o $output_file \
  -b boot/isolinux/isolinux.bin \
  -c boot/isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -eltorito-platform efi \
  -eltorito-boot efi/esp.img \
  -no-emul-boot \
  -eltorito-catalog boot/isolinux/boot.cat \
  $uefiimg_dir/

isohybrid -u $output_file

echo
echo Output ISO in $output_file
echo
