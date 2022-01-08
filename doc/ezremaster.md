Creating bootable ISO for patching
----------------------------------

1) Download [CorePure64 11.1](http://www.tinycorelinux.net/11.x/x86_64/release/CorePure64-11.1.iso)

2) Boot it up in a VM

3) (optional) If you want to have a SSH-Shell to the target VM so that 
   you don't need to enter commands on the console, do:

```
tce-load -wi openssh
sudo -s
cp /usr/local/etc/ssh/sshd_config.orig /usr/local/etc/ssh/sshd_config
/usr/local/etc/init.d/openssh start
passwd tc
ifconfig
exit
```

   Then connect to your freshly installed SSH-server

4) Download and unzip this repository in the home directory:

```
cd ~
wget https://github.com/leecher1337/thinkpad-Lx30-ec/archive/refs/heads/master.zip
unzip master.zip
rm master.zip
```

5) Now download Tinycore ISO required for building:
```
cd /tmp
wget http://www.tinycorelinux.net/11.x/x86_64/release/CorePure64-11.1.iso
mv CorePure64-11.1.iso Core-11.1.iso
```

6) Next, build Tinycore release ISO:
```
cd ~/tinycore
sh ./mkiso.sh
```

7) Your ISO can be found in /tmp/ezremaster/ezremaster-uefi.iso

Notes
-----
There are x86 and 64bit versions of the various utilities for the Tinycore ISO
available.
x86 build would use 
https://distro.ibiblio.org/tinycorelinux/11.x/x86/archive/11.1/Core-11.1.iso
instead, but unfortunately, the kernel driver for hotpatching only works in
x64 Linux properly, therefore, there are no x86 builds of the ISO.
Who needs it anyway, as all affected machines are capable of 64bit.

We also support UEFI booting of the ISO for your convenience.
