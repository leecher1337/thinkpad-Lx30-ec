# Info about Ghidra project file

There are 2 "firmware images" in the BIOS image:
The first starts at 0 (containing String `G3HT40WW(1.14)`) and
the second one at 0x8000 (NB: Load address 0x20100 !).

The first image is mainly the loader code for the second image, which tries to
load it at address 20100. It also contains the same keyboard driver like
the main image, so this may be some kind of emergency backup mechanism in
case loading of the second image fails so that the machine doesn't completely brick.

In Ghidra project, there are various parts.
The Project is derived from https://github.com/jwise/x2100-ec/blob/master/notes/x2100-ec.gar by @jwise
and I added the 2 firmware images from the dump:

| File                 | Description                                                        |
| -------------------- | ------------------------------------------------------------------ |
| ec.bin               | This is the second Firmware from L530. This should be worked on.   |
| fw-top.bin           | This is the first Firmware from L530. Mainly the loader.           |
| fw.bin               | Combined firmware, frist+second, may be useful for studying loader |
| x2100-ec.bin-patched | This is the x2100 firmware, useful for comparisons                 |
| x2100-ec.bin         | x2100 Working base, can be ignored                                 |
| newec-gpe-patch.bin  | New x2100 embedded controller FW? Not similar to L530 FW           |
