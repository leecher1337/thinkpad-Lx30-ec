# Thinkpad L430/L530/B480/B580/V480/V480c/V580/V580c/B490/B590/E330/V480s Embedded controller firmware patches

Intro
-----

The main purpose of this software is to patch the EC on above mentioned series thinkpads
to make the classic 7-row keyboards work.  There are also patches included 
to disable the authentic battery validation check.

There are already patches for other xx30 series Thinkpads to accomplish
this [here](https://www.github.com/hamishcoleman/thinkpad-ec/), 
but they are for different embedded controllers, so this patchset had to
be created.

With the patches included here, you can install the classic keyboard
hardware on Lx30 series laptops and make almost every key work properly.
The only keys that are not working are Fn+F3 (Battery) and Fn+F12 (Hibernate)

* A full writeup of the hardware modifications needed can be found at:
    http://www.thinkwiki.org/wiki/Install_Classic_Keyboard_on_xx30_Series_ThinkPads

About the EC on Lx30/Bx89/Vx80/Bx90/E330 series Thinkpads
---------------------------------------------------------

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
These and the Header and CRC mechanism are explained in [doc/ghidra.md](doc/ghidra.md)

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

Firmware compatibility Matrix:

Laptop                          | EC version 
--------------------------------|---------------------------------
L430/L530                       | G3HT40WW(1.14)
B480/B580/V480/V480c/V580/V580c | H1EC33WW(1.13) / H5EC33WW(1.13)
B490/B590                       | H9EC09WW(1.02)
E330/V480s                      | H3EC35WW(1.18)
E130/X130e/X131e                | Not supported, but see [here](https://github.com/leecher1337/thinkpad-Lx30-ec/issues/5)

If unsure, you can check i.e. in BIOS.

Now check out Releases-Link on the right side of this page. It contains ready
made ISOs that you just need to boot on the target machine and then
apply the patches.
Currently only hot-patching is available.
For permanent patches (which got created by these scripts) refer to my pull
request to [thinkpad-ec](https://github.com/hamishcoleman/thinkpad-ec/).

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

You would theoretically need to unlock flash chip first with  [1vyrain](https://github.com/n4ru/1vyrain), 
but I didn't want to incorporate it within the bootable ISO, as chipsec is 
pretty big and it has not been tested yet! 
So better use [thinkpad-ec](https://github.com/hamishcoleman/thinkpad-ec/) for that.

Advantage:
Survives even power-off and battery removal, so loads again on EC-reinitialization.
This is a permanent fix.

Disadvantage:
You have to re-flash your EC firmware. If something goes wrong, you may end up
with a bricked machine. Do this at your own risk. If something goes wrong, do not
complain!



After you select the appropriate option, patching should be carried out
and you either get a success-message or an error.

External flashing with a programmer:
------------------------------------

If internal flashing failed for you for whatever reason, you can try to flash 
the chip with a Raspberry Pi and a Chip clip via ICP (In circuit programming).
In my tests, flashing a L530 with a CH341A device didn't work, maybe due to 
lacking power supply, but using a Raspberry Pi worked.
As a general warning regarding CH341A:
Be aware that the CH341A is an improperly engineered device that outputs
5V instead of 3.3V on the data lines without modification, so if you want to 
play around with CH341A, be sure to first modify the circuit.


### Chip location

You can cut out a part from the chassis in order to access the chip without 
having to disassemble the whole machine.
Image of the chip's location: [See here](https://github.com/hamishcoleman/thinkpad-ec/issues/203#issuecomment-1001250064) 
So this is behind the cover where you can i.e. also acess the hard drive. 
There is a rectangle cut out where you can see through the board and there 
you can cut out the lower part in order to get access to the chip. 
Be careful not to cut into the board!

### Wiring

Pin Chip | Name     | Pin RaspPi
---------|----------|------------
1        | CS       | 24
2        | MISO     | 21
3        | WP       | not used
4        | GND      | 25
5        | MOSI     | 19
6        | CLK      | 23
7        | HOLD     | not used
8        | VCC 3.3v | 17

WP and HOLD are not connected, because according to the board schematics, they
are already connected to VCC via pull-up resistor onboard.

#### Chip layout:
```
         _____
CS#  1--|o    |--8 VCC
MISO 2--|     |--7 HOLD#
WP#  3--|     |--6 CLK 
GND  4--|_____|--5 MOSI 

```

#### RaspPi PIN layout:

See [here](https://www.elektronik-kompendium.de/sites/raspberry-pi/1907101.htm)
Or just enter `pinout` on RaspPi shell to see it.


Before setting up the cables, ensure that
1) RaspPi is turned off
2) Thinkpad is NOT connected to AC
3) Thinkpad main battery is REMOVED

It is crucial that there is no VCC on PIN8 of the Flash chip from the board,
as circuit will be powered by the RaspPi!
It's not necessary to remove the CMOS battery.

When hooking up a chip clip from China, you usally have a ribbon cable and PIN 1
is the red wire. PIN 1 has to match the upper left corner of the chip which
is signified by a hole on the chip.


### Setting up Raspberry PI

[Enable SPI device](https://www.raspberrypi-spy.co.uk/2014/08/enabling-the-spi-interface-on-the-raspberry-pi/)
if not done yet, by using `sudo raspi-config` and Interfacing options -> SPI

Then install flashrom:

`apt install flashrom`

### Flashing

1) Take layout file depending on your notebook model. 
   Layout files are in [fwpat/models](fwpat/models) directory

2) As a precation, you can dump your BIOS with:

   `flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -r bios-ec.rom`
   
Sample output:
```  
flashrom v1.2 on Linux 5.10.63-v7l+ (armv7l)
flashrom is free software, get the source code at https://flashrom.org

Using region: "ec".
Using clock_gettime for delay loops (clk_id: 1, resolution: 1ns).
Found Winbond flash chip "W25Q64.V" (8192 kB, SPI) on linux_spi.
Reading flash... done.
```

3) Dump it a second time, just to be sure and compare using `diff` utility to 
   ensure proper dumping.

4) For modification of the dumped ROM, refer to the appropriate document in [doc](doc/).
   For the commands, instead of `-p internal`, use 
   `-p linux_spi:dev=/dev/spidev0.0,spispeed=1000`
   
Sample output:
```
pi@raspberrypi:~ $  flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -l layout -w bios-new.rom -i ec
flashrom v1.2 on Linux 5.10.63-v7l+ (armv7l)
flashrom is free software, get the source code at https://flashrom.org

Using region: "ec".
Using clock_gettime for delay loops (clk_id: 1, resolution: 1ns).
Found Winbond flash chip "W25Q64.V" (8192 kB, SPI) on linux_spi.
Reading old flash chip contents... done.
Erasing and writing flash chip... Erase/write done.
Verifying flash... VERIFIED.
```

