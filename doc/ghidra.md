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

# Description of IN header

| Offset | Ldr. Addr | Size     | Description                 | Comment                         |
| ------ | --------- | -------- | --------------------------- | ------------------------------- |
| 00     | 10330     | uint32_t | Signature                   | 49 4E 00 00                     |
| 04     | 10334     | uint32_t | Start address CRC in Flash  | addr \* 2 - 0x80000             |
| 08     | 10338     | uint16_t | ?                           |
| 0A     | 10324     | uint32_t | Size of code                | 0x3ad bytes of data follow code |
| 0E     | 10328     | uint32_t | Address Entry point         | addr \* 2                       |
| 12     | 1032C     | uint16_t | CRC                         | For algorithm see below         | 

Example:

```
Offset      0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
00408000   49 4E 00 00 05 40 24 00  00 00 0E 65 01 00 8A 00   IN...@$....e..Å .
00408010   01 00 9C 00 04 00 0A 00  7F 00 01 00 90 0E 70 00   ..Å........p.
00408020   01 00 E0 0E 14 00 C0 10  00 5A 14 00 90 00 14 00   ..Ã ...Ã..Z.....
00408030   80 20 B0 26 00 01 14 00  80 00 70 00 03 00 98 49   â¬ Â°&....â¬.p...ËI
00408040   14 00 A0 10 10 00 E0 00  46 00 43 6F 70 79 72 69   ..Â ...Ã .F.Copyri
00408050   67 68 74 20 31 39 39 36  2D 31 39 39 39 2C 20 61   ght 1996-1999, a
00408060   6C 6C 20 72 69 67 68 74  73 20 72 65 73 65 72 76   ll rights reserv
00408070   65 64 0A 0D 49 6E 73 79  64 65 20 53 6F 66 74 77   ed..Insyde Softw
00408080   61 72 65 20 43 6F 72 70  2E 00 97 01 71 05 00 00   are Corp..â.q...
```

| Offset | Value    | Result                             |
| ------ | -------- | ---------------------------------- |
| 00     | 0x4E49   | IN                                 |
| 04     | 0x244005 | 0x244005 \* 2 - 0x80000 = 0x40800A |
| 08     | 0x0      | 0x0                                |
| 0A     | 0x01650E | 0x01650E + 0x3AD = 0x168BB         |
| 0E     | 0x1008A  | 0x1008A \* 2 = 0x20114             |
| 12     | 0x9C     | 0x9C                               |
| 14     | 04 00 0A | DI, CINV[i], MOVD ...              |

# CRC calculation

Take address at offset 04 (Start address CRC in Flash) and start with uint8_t CRC value 0.
The start address is usually the start address of the IN header offset 0xA, so in the
example above the address is 0x40800A, whereas the image gets loaded to address 0x408000.
So we start at offset 0A.
Then loop "Size of code" bytes (offset 0A) and subtract the value of every byte from 
previous CRC result.

In the example above, this would loop 0x168BB iterations starting from offset 0A, so:
00 - 0E = F2
F2 - 65 = 8D
8D - 01 = 8C
....

You can find a simple implementation in src/npce885crc.c
