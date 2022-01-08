# Thinkpad L430/L530/B590/E330 Embedded controller firmware patches

Intro
-----

The main purpose of this software is to patch the EC on Lx30/B590/E330 series thinkpads
to make the classic 7-row keyboards work.  There are also patches included 
to disable the authentic battery validation check.

There are already patches for other xx30 series Thinkpads to acoomplish
this [here](https://raw.githubusercontent.com/hamishcoleman/thinkpad-ec/), 
but they are for different embedded controllers, so this patchset had to
be created.

With the patches included here, you can install the classic keyboard
hardware on Lx30 series laptops and make almost every key work properly.
The only keys that are not working are Fn+F3 (Battery) and Fn+F12 (Hibernate)

* A full writeup of the hardware modifications needed can be found at:
    http://www.thinkwiki.org/wiki/Install_Classic_Keyboard_on_xx30_Series_ThinkPads

About the EC on Lx30/B590/E330 series Thinkpads
-----------------------------------------------

The EC is a Nuvoton [NPCE885G](http://j5d2v7d7.stackpathcdn.com/wp-content/uploads/2021/02/NPCE885LA0DX-datasheet.pdf) 
(also according to [the schematics](http://laptop-schematics.com/view/8924/) ).
This is a controller with CR16CPlus CPU (CompactRISC).

There seems to be a thread a Thinkpad forum about the X210 EC, which seems to 
be the same model:
https://forum.thinkpads.com/viewtopic.php?p=837219#p837219 

There are 2 repositories with tools for EC patching and Checksum calculation for X210:
https://github.com/harrykipper/x210
https://github.com/jwise/x2100-ec

There is a driver to interact directly with the EC memory allowing hot-patching:
https://github.com/exander77/x2100-ec-sys

Directory structure
-------------------

| Dir      | Description                                                         |
| -------- | ------------------------------------------------------------------- |
| doc      | Documentation of the patches, build process, etc.                   |
| ghidra   | Ghidra project file for exploring and reversing the EC firmware     |
| tinycore | Additional files needed for building the tinycore Linux ISO         |
| fwpat    | Dialog-based Bash script for convenient patching of the EC firmware |


Documentation of the patches:
-----------------------------

The EC firmware was reverse engineered using [Ghidra](https://ghidra-sre.org/)
In ghidra/ dir, you find the current project file containing some
annotations on various fields of the firmware.
The file is mainly used to explore firmware and contains various components.
These are explained in [doc/ghidra.md](doc/ghidra.md)

The battery patch is explained in [doc/battery.md](doc/battery.md)
The keyboard layout patch including all necessary tables to enroll your own 
layout, i.e. to also activate NumLock on existing keyboard etc. is explained in
[doc/keyboard.md](doc/keyboard.md)
BIOS battery check code is documented in [doc/bios.md](doc/bios.md)

The process of building the bootable ISO for easy hotpatching using 
[tinycorelinux](http://tinycorelinux.net/) is explained in 
[doc/ezremaster.md](doc/ezremaster.md)
(Normally not needed, just use ISO under "Releases")


Step-by-step instructions:
--------------------------

This software expects to be run under 64bit Linux (real Linux, not Microsoft
Windows Linux subsystem).  Ensure you have updated your
BIOS to a compatible version before starting.

It is not so much a question about upgrading to a recent BIOS version, but
more of ensuring you are using a compatible EC firmware version. 

These patches are only compatibles with EC version G3HT40WW(1.14)
If unsure, you can check i.e. in BIOS.

Now check out Releases-Link on the right side of this page. It contains ready
made ISOs that you just need to boot on the target machine and then
apply the patches.
Currently only hot-patching is available.

To write the ISO image, you can either use a CD with a CD-Burner, or
you simply put it on a USB stick. There are various tutorials and programs
out there to accomplish this, i.e. for Windows, you can use [Rufus](https://rufus.ie/),
or to be more flexible, you can also use [Ventoy](https://www.ventoy.net/) 
where you just have to copy the .iso file on the FAT32 partition and Ventoy
will boot it automatically.


Booting the stick and flashing the firmware:
--------------------------------------------

When you are booting the image, you are presented with a list of 
patches to apply. Just select the ones that you want to apply by
using the Space bar to select and deselect the appropriate patches.

On the next screen, you can decide on whether to Hot-patch the EC
firmware, or to make a permanent flash update (doesn't work yet).

### Hotpatch in memory only

Advantage:
No permanent changes to EC firmware, if it causes bad side effects,
you just need to remove battery and power to reset EC back to stock firmware.

Disadvantage:
It only lasts as long as there is enough power so the EC doesn't shut down,
so you have to redo it after every power outage

### Patch and reflash firmware

DO NOT USE! It fails for LENOVO stock BIOS, unfortunately. 
You would theoretically need to unlock flash chip first with  [1vyrain](https://github.com/n4ru/1vyrain), 
but I didn't want to incorporate it within the bootable ISO, as chipsec is 
pretty big and it has not been tested yet! Testing with DOSFLASH from Lenovo currently failed,
so permanent flashing has to be investigated further.


Advantage:
Survives even power-off and battery removal, so loads again on EC-reinitialization.
This is a permanent fix.

Disadvantage:
You have to re-flash your EC firmware. If something goes wrong, you may end up
with a bricked machine. Do this at your own risk. If something goes wrong, do not
complain!



After you select the appropriate option, patching should be carried out
and you either get a success-message or an error.

