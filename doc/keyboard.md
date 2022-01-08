# Patching L430/530 for a classic 7-row Keyboard

So I had a look at the Keyboard handling routines and found out where they keyboard layout table lies and how to edit it. The results are plenty tables that might become handy for you to patch your own keyboard layout.

## Location of the keyboard table

In Firmware G3HT40WW(1.14) there are 4 layout tables located at offset `0x39916`. They each have the following format (I don't count the prefix length byte in offset so that you have a "clean" keyboard layout offset matrix for the following tables):

## Table format

| Offset | Length | Description                                                                                      |
| ------ | ------ | ------------------------------------------------------------------------------------------------ |
| Prefix | 0x01   | length of table at offset 0xa2 in bytes                                                          |
| 0x00   | 0x90   | Mapping table for the keys 0-144                                                                 |
| 0x90   | 0x12   | bitfield, specify whether to map a key via following Fn Mapping-table or not                     |
| 0xa2   |        | Fn-Modifiers enabled in mask at offset 0x90, Array of 2 bytes per entry: [Keypress, Fn-Keypress] |

Table 0 Unknown, maybe key table used on BIOS start screen..?
Table 1 is the default table and the one we are interested in. It starts at offset 366BC
Table 2 Unknown, can be selected with command 91h, C2h
Table 3 Unknown

Here is the default layout:

```
Prefix: 54
Offset      0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F

00000000   0E 05 0A 2E 36 55 16 4E  18 00 A2 A1 00 00 00 8C
00000010   16 1E 26 25 3D 3E 46 45  1A 1E 1C A0 A3 00 00 00
00000020   15 1D 24 2D 3C 43 44 28  6A 00 04 00 00 00 00 00
00000030   0D 58 0C 2C 35 5B 14 54  66 82 02 00 00 00 88 00
00000040   1C 24 23 2B 3B 26 4B 4C  5D 00 00 9D 00 00 00 00
00000050   76 61 0E 34 33 12 64 52  10 00 08 00 A7 8A 00 00
00000060   1A 22 21 2A 3A 41 49 5D  5A 00 06 A4 00 00 89 8D
00000070   67 8E 00 22 31 51 13 4A  20 A9 A8 A5 A6 8B 00 00
00000080   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
00000090   44 01 00 07 80 04 44 04  22 04 24 05 00 04 08 01
000000A0   00 00 C1 C1 10 B0 C3 C3  30 B1 C5 C5 30 B2 C7 C7
000000B0   10 B3 C9 C9 30 B4 06 CB  10 C2 04 CD 10 C3 0C CF
000000C0   10 C4 03 D1 10 C5 0B D3  10 C6 80 D5 10 C7 0A D7
000000D0   30 BB 01 D9 30 BC 09 DB  30 B9 78 DD 10 B8 07 DF
000000E0   30 BA 29 E1 10 B6 32 E3  10 D0 1B E5 10 D1 42 E7
000000F0   10 D2 4D E9 10 D3 00
```

Per default, a key in the table (assignment HW-scancode of 7-row Keyboard to keycode location in table will be shown in the following table) is roughly assigned to the specified scancode of Set 2. The EC contains the standard translation table
to Set 1 and the CPU-Translation table. For details on the tables, see [here](https://www.win.tue.nl/~aeb/linux/kbd/scancodes-10.html). Thsi is pretty much standard stuff, EC will take care of Make and Break codes accordingly.
For codes >=80, there is a mapping table at offset 35f7c which contains of 2 bytes per entry. First byte is scancode and second byte is index in function pointer table at 34e6c which specifies on how to translate the table entry into a keycode.
For you to create your keyboard layout, here is a list of some important "special" keycodes that are provided by this table:

| Int. Code | Set 2 Scancode          | Description      | Keycode |
| --------- | ----------------------- | ---------------- | ------- |
| 80        | 83                      | F7               | 80      |
| 81        | E0 5A                   | Keypad Enter     | 81      |
| 82        | E0 1F                   | Left GUI         | 82      |
| 83        | E0 27                   | Right GUI        | 83      |
| 84        | E0 2F                   | App              | 84      |
| 85        | E0 37                   | Keyboard Power   | 85      |
| 86        | E0 3F                   | System Sleep     | 86      |
| 87        | E0 5E                   | System Wake      | 87      |
| 91        | E1 14 77 E1 F0 14 F0 77 | Pause            | 9E      |
| 92        | E0 7E E0 F0 7E          | Ctrl+Pause       | 9E      |
| 93        | 84                      | Alt+SysRq        | 9D      |
| 94        | E0 7C                   | KP-\*            | 9C      |
| 95        |                         | KP-\*            | 9C      |
| 96        | E0 4A                   | KP-/             | 9F      |
| 97        |                         | KP-/             | 9F      |
| 98        | E0 70                   | Insert           | A0      |
| 99        |                         | Insert           | A0      |
| 9A        |                         | Insert           | A0      |
| 9B        | E0 71                   | Delete           | A1      |
| 9C        |                         | Delete           | A1      |
| 9D        |                         | Delete           | A1      |
| 9E        | E0 6C                   | Home             | A2      |
| 9F        |                         | Home             | A2      |
| A0        |                         | Home             | A2      |
| A1        | E0 69                   | End              | A3      |
| A2        |                         | End              | A3      |
| A3        |                         | End              | A3      |
| A4        | E0 7D                   | PgUp             | A4      |
| A5        |                         | PgUp             | A4      |
| A6        |                         | PgUp             | A4      |
| A7        | E0 7A                   | PgDn             | A5      |
| A8        |                         | PgDn             | A5      |
| A9        |                         | PgDn             | A5      |
| AA        | E0 6B                   | Left             | A6      |
| AB        |                         | Left             | A6      |
| AC        |                         | Left             | A6      |
| AD        | E0 75                   | Up               | A7      |
| AE        |                         | Up               | A7      |
| AF        |                         | Up               | A7      |
| B0        | E0 72                   | Down             | A8      |
| B1        |                         | Down             | A8      |
| B2        |                         | Down             | A8      |
| B3        | E0 74                   | Right            | A9      |
| B4        |                         | Right            | A9      |
| B5        |                         | Right            | A9      |
| B6        | E0 41                   | Reply            |         |
| B7        | E0 49                   | ?                |         |
| B8        | E0 3B                   | Stop             |         |
| B9        | E0 34                   | Play/Pause       |         |
| BA        | E0 23                   | Mute             |         |
| BB        | E0 32                   | Volume up        |         |
| BC        | E0 21                   | Volume down      |         |
| BD        | E0 48                   | Mail             |         |
| BE        | E0 10                   | Scan prev. Track |         |
| BF        | E0 3A                   | WWW Home         |         |
| C0        | E0 38                   | WWW Back         |         |
| C1        | E0 30                   | WWW Forward      |         |
| C2        | E0 28                   | WWW Stop         |         |
| C3        | E0 20                   | WWW Refresh      |         |
| C4        | E0 18                   | WWW Favorites    |         |
| C5        | E0 2B                   | Calculator       |         |
| C6        | E0 40                   | My Computer      |         |
| C7        | E0 50                   | Media select     |         |

Please note that the Int. Code is used only internally. Codes >9B are sent through another mapping table at offset 34e88. So as a user, the Keycode column is significant, because it incorporates said mapping table.
The codes are only valid up to A9, because at AA, there starts another table for the NumLock assignments which can be found at offset 35f4a:

| Keycode | No-NL-Key | No-NL Scancode | NL-Key       | NL Scancode |
| ------- | --------- | -------------- | ------------ | ----------- |
| AA      | 7         | 3D             | KP-7 / Home  | 6C          |
| AB      | 8         | 3E             | KP-8 / Up    | 75          |
| AC      | 9         | 46             | KP-9 / PgUp  | 7D          |
| AD      | U         | 3C             | KP-4 / Left  | 6B          |
| AE      | I         | 43             | KP-5         | 73          |
| AF      | O         | 44             | KP-6 / Right | 74          |
| B0      | J         | 3B             | KP-1 / End   | 69          |
| B1      | K         | 42             | KP-2 / Down  | 72          |
| B2      | L         | 4B             | KP-3 / PgDn  | 7A          |
| B3      | M         | 3A             | KP-0 / Ins   | 70          |
| B4      | .>        | 49             | KP-. / Del   | 71          |
| B5      | /?        | 4A             | KP-/         | 9F          |
| B6      | ;:        | 4C             | KP-+         | 79          |
| B7      | 0 )       | 45             | KP-\*        | 7C          |
| B8      | P         | 4D             | KP--         | 7B          |
| B9      | ENTER     | 5A             | KP Enter     | 81          |
| BA      | - \_      | 4E             | KP--         | 7B          |
| BB      | [{        | 54             | KP Enter     | 81          |
| BC      | /?        | 4A             | KP-+         | 79          |
| BD      | ;:        | 4C             | KP--         | 7B          |
| BE      | 0 )       | 45             | KP-/         | 9F          |
| BF      | P         | 4D             | KP-\*        | 7C          |

Now in case that there is a "special" command needed that cannot be covered by a scancode above or if there is a FN-Key combination, the key cannot be identified by 1 byte in the first table. In this case, a bit is set in the long bitfield at offset 0x90 in the key table. Each bit corresponds to a key, so bit 1 is the first key from the table, bit 2 the second, etc.
So the bit is determined by: `scancode_table[0x90+(offset>>3)]`, i.e. to set a bit in this table:
`scancode_table[0x90+(offset>>3)]|=(1<<(offset&7))`
If this bit is set, the number in the first table isn't the scancode but an index into the table at offset A2.
As written, a table entry in the table at A2 consists of 2 bytes:

1. Scancode for normal keypress
2. Scancode for FN + key combination

Now there is a special handling in this table for keycodes >C0. If a code is >C0, the specified entry minus C0 is an index into the same table at A2 which then specifies a "command" code, as I call it.
Command codes are identified by the first entry & 0x1F being 0x10 and the second being the command.
The "commands" are the following (table not complete, if you feel like it, please complete empty/unknown entries):

Break Command codes:

| Command | Description      | Set 2 Scancode |
| ------- | ---------------- | -------------- |
| B0      | Mute             | E0 F0 23       |
| B1      | Vol Down         | E0 F0 21       |
| B2      | Vol Up           | E0 F0 32       |
| B3      | Mic Shut         |                |
| B4      | ThinkVantage     |                |
| B7      | Stop             | E0 F0 3B       |
| B8      | Play/Pause       | E0 F0 34       |
| B9      | Scan prev. track | E0 F0 15       |
| BA      | Scan next track  | E0 F0 4D       |
| BD      | Num Lock         | F0 77          |
| D1      | SysReq           | F0 84 F0 11    |
| D2      | ScrLk            | F0 7E          |

Make Command codes:

| Command | Description       | Set 2 Scancode          |
| ------- | ----------------- | ----------------------- |
| B0      | Mute              | E0 23                   |
| B1      | Vol Down          | E0 21                   |
| B2      | Vol Up            | E0 32                   |
| B3      | Mic Shut          |                         |
| B4      | Thinkvantage      |                         |
| B5      | ?                 |                         |
| B7      | Stop              | E0 3B                   |
| B8      | Play/Pause        | E0 34                   |
| B9      | Scan prev. track  | E0 15                   |
| BA      | Scan next track   | E0 4D                   |
| BB      | Brightness down   |                         |
| BC      | Brightness up     |                         |
| BD      | Num Lock          | 77                      |
| C2      | ?                 |                         |
| C3      | Screen Lock       |                         |
| C4      | Sleep             |                         |
| C5      | WiFi on/off       |                         |
| C6      | Lenovo Settings   |                         |
| C7      | Switch video mode |                         |
| C8      | ?                 |                         |
| CC      | ?                 |                         |
| D0      | CtrlBrk           | 14 E0 7E E0 F0 7E F0 14 |
| D1      | SysReq            | 11 84                   |
| D2      | ScrLk             | 7E                      |
| D3      | Pause             | E1 14 77 E1 F0 14 F0 77 |

## Current layout

So analyzing the current layout and checking a 7-row keyboard gives us the following layout:

| Key              | Offset | Keycode | Hw-Code | Scancode Set2 Make      | Fn Mapping |
| ---------------- | ------ | ------- | ------- | ----------------------- | ---------- |
| ` ~              | 0      | 0E      | 00 10   | 0e                      |            |
| 1 !              | 10     | 16      | 00 11   | 16                      |            |
| 2 @              | 11     | 1E      | 01 11   | 1e                      |            |
| 3 #              | 12     | 26      | 02 11   | 26                      |            |
| 4 $              | 13     | 25      | 03 11   | 25                      |            |
| 5 %              | 3      | 2E      | 03 10   | 2e                      |            |
| 6 ^              | 4      | 36      | 04 10   | 36                      |            |
| 7 &              | 14     | 3D      | 04 11   | 3d                      |            |
| `8 *`            | 15     | 3E      | 05 11   | 3e                      |            |
| 9 (              | 16     | 46      | 06 11   | 46                      |            |
| 0 )              | 17     | 45      | 07 11   | 45                      |            |
| `- _`            | 7      | 4E      | 07 10   | 4e                      |            |
| = +              | 5      | 55      | 05 10   | 55                      |            |
| Backspace        | 38     | 66      | 08 13   | 66                      |            |
| Tab              | 30     | 0D      | 00 13   | 0d                      |            |
| Q                | 20     | 15      | 00 12   | 15                      |            |
| W                | 21     | 1D      | 01 12   | 1d                      |            |
| E                | 22     | 24      | 02 12   | 24                      |            |
| R                | 23     | 2D      | 03 12   | 2d                      |            |
| T                | 33     | 2C      | 03 13   | 2c                      |            |
| Y                | 34     | 35      | 04 13   | 35                      |            |
| U                | 24     | 3C      | 04 12   | 3c                      |            |
| I                | 25     | 43      | 05 12   | 43                      |            |
| O                | 26     | 44      | 06 12   | 44                      |            |
| P                | 27     | 28      | 07 12   | 4d                      | Y          |
| [ {              | 37     | 54      | 07 13   | 54                      |            |
| ] }              | 35     | 5B      | 05 13   | 5b                      |            |
| \ \|             | 51     | 61      | 01 15   | 5d                      |            |
| CapsLock         | 31     | 58      | 01 13   | 58                      |            |
| A                | 40     | 1C      | 00 14   | 1c                      |            |
| S                | 41     | 24      | 01 14   | 1b                      | Y          |
| D                | 42     | 23      | 02 14   | 23                      |            |
| F                | 43     | 2B      | 03 14   | 2b                      |            |
| G                | 53     | 34      | 03 15   | 34                      |            |
| H                | 54     | 33      | 04 15   | 33                      |            |
| J                | 44     | 3B      | 04 14   | 3b                      |            |
| K                | 45     | 26      | 05 14   | 42                      | Y          |
| L                | 46     | 4B      | 06 14   | 4b                      |            |
| ; :              | 47     | 4C      | 07 14   | 4c                      |            |
| ' "              | 57     | 52      | 07 15   | 52                      |            |
| non-US-1         | 67     | 5D      | 07 16   | 0                       |            |
| Enter            | 68     | 5A      | 08 16   | 5a                      |            |
| LShift           | 3E     | 88      | 0E 13   | 12                      |            |
| Z                | 60     | 1A      | 00 16   | 1a                      |            |
| X                | 61     | 22      | 01 16   | 22                      |            |
| C                | 62     | 21      | 02 16   | 21                      |            |
| V                | 63     | 2A      | 03 16   | 2a                      |            |
| B                | 73     | 22      | 03 17   | 32                      | Y          |
| N                | 74     | 31      | 04 17   | 31                      |            |
| M                | 64     | 3A      | 04 16   | 3a                      |            |
| , <              | 65     | 41      | 05 16   | 41                      |            |
| . >              | 66     | 49      | 06 16   | 49                      |            |
| / ?              | 77     | 4A      | 07 17   | 4a                      |            |
| RShift           | 6E     | 89      | 0E 16   | 59                      |            |
| LCtrl            | 0F     | 8C      | 0F 10   | 14                      |            |
| LAlt             | 5D     | 8A      | 0D 15   | 11                      |            |
| space            | 78     | 20      | 08 17   | 29                      | Y          |
| RAlt             | 7D     | 8B      | 0D 17   | e0-11                   |            |
| RCtrl            | 6F     | 8D      | 0F 16   | e0-14                   |            |
| Insert           | 09     | A0      | 09 10   | E0 70                   |            |
| Delete           | 0A     | A1      | 0A 10   | E0 71                   |            |
| Home             | 0C     | A2      | 0C 10   | E0 6C                   |            |
| End              | 1C     | A3      | 0C 11   | E9 69                   |            |
| PgUp             | 0B     | A4      | 0B 10   | E0 7D                   |            |
| PgDn             | 1B     | A5      | 0B 11   | E0 7A                   |            |
| Left             | 7C     | A6      | 0C 17   | e0-6b                   |            |
| Up               | 5C     | A7      | 0C 15   | e0-75                   |            |
| Down             | 7A     | A8      | 0A 17   | e0-72                   |            |
| Right            | 79     | A9      | 09 17   | e0-74                   |            |
| Esc              | 50     | 76      | 00 15   | 76                      |            |
| F1               | 01     | 05      | 01 10   | 05                      |            |
| F2               | 02     | 0A      | 02 10   | 06                      | Y          |
| F3               | 32     | 0C      | 02 13   | 04                      | Y          |
| F4               | 52     | 0E      | 02 15   | 0c                      | Y          |
| F5               | 58     | 10      | 08 15   | 03                      | Y          |
| F6               | 55     | 12      | 05 15   | 0b                      | Y          |
| F7               | 36     | 14      | 06 13   | 83                      | Y          |
| F8               | 06     | 16      | 06 10   | 0a                      | Y          |
| F9               | 08     | 18      | 08 10   | 01                      | Y          |
| F10              | 18     | 1A      | 08 11   | 09                      | Y          |
| F11              | 1A     | 1C      | 0A 11   | 78                      | Y          |
| F12              | 19     | 1E      | 09 11   | 07                      | Y          |
| WWW-Back         | 6B     |         | 0B 16   | E0 38                   |            |
| WWw-Fwd          | 7B     |         | 0B 17   | E0 30                   |            |
| PrtScr           | 1D     |         | 0D 11   | E0 7C                   |            |
| ScrLock          | 2D     |         | 0D 12   | 7E                      |            |
| Pause            | 6C     |         | 0C 16   | E1 14 77 E1 F0 14 F0 77 |            |
| Vol Up           | 2A     | 04      | 0A 12   | E0 32                   | Y          |
| Vol Down         | 3A     | 02      | 0A 13   | E0 21                   | Y          |
| Mute             | 4A     | 00      | 0A 14   | E0 23                   | Y          |
| ThinkVantage     | 5A     | 08      | 0A 15   |                         | Y          |
| Mic Shut         | 6A     | 06      | 0A 16   |                         | Y          |
| Left GUI(WIN)    | 39     | 82      | 09 13   | E0 1F                   |            |
| Right GUI (Menu) | 4B     |         | 0B 14   | E0 27                   |            |

You may have noticed that offset is just Hw-Code `byte2 << 4 | byte1`
If you want to watch for HW key codes i.e. to implement another keyboard, use watch -n 2 with: `dd if=/sys/kernel/debug/ec/ec0/ram bs=1 count=8 skip=68382 2>/dev/null | hexdump -C`

Looking at the FN-Table that gets referenced by the keys in the table above when "Fn Mapping" is Y:

| Mapping | Normal | Descr            | FN  | Descr                      |
| ------- | ------ | ---------------- | --- | -------------------------- |
| 0       | C1     | -> Mapping 1     | C1  | -> Mapping 01              |
| 1       | 10     | Command          | B0  | Mute                       |
| 2       | C3     | -> Mapping 3     | C3  | -> Mapping 03              |
| 3       | 30     | Command          | B1  | Volume Down                |
| 4       | C5     | -> Mapping 5     | C5  | -> Mapping 05              |
| 5       | 30     | Command          | B2  | Volume Up                  |
| 6       | C7     | -> Mapping 7     | C7  | -> Mapping 07              |
| 7       | 10     | Command          | B3  | Mic Shut                   |
| 8       | C9     | -> Mapping 9     | C9  | -> Mapping 09              |
| 9       | 30     | Command          | B4  | ThinkVantage               |
| 0A      | 06     | F2               | CB  | -> Mapping 0B              |
| 0B      | 10     | Command          | C2  |                            |
| 0C      | 04     | F3               | CD  | -> Mapping 0D              |
| 0D      | 10     | Command          | C3  | Screen Lock                |
| 0E      | 0C     | F4               | CF  | -> Mapping 0F              |
| 0F      | 10     | Command          | C4  | Sleep                      |
| 10      | 03     | F5               | D1  | -> Mapping 11              |
| 11      | 10     | Command          | C5  | WIFI on/off                |
| 12      | 0B     | F6               | D3  | -> Mapping 13              |
| 13      | 10     | Command          | C6  | Lenovo settings            |
| 14      | 80     | F7 via transtbl. | D5  | -> Mapping 15              |
| 15      | 10     | Command          | C7  | Switch video mode          |
| 16      | 0A     | F8               | D7  | -> Mapping 17              |
| 17      | 30     | Command          | BB  | Brightness down            |
| 18      | 01     | F9               | D9  | -> Mapping 19              |
| 19      | 30     | Command          | BC  | Brightness up              |
| 1A      | 09     | F10              | DB  | -> Mapping 1B              |
| 1B      | 30     | Command          | B9  | Scan prev. Track           |
| 1C      | 78     | F11              | DD  | -> Mapping 1D              |
| 1D      | 10     | Command          | B8  | Play/Pause                 |
| 1E      | 07     | F12              | DF  | -> Mapping 1F              |
| 1F      | 30     | Command          | BA  | Scan next track            |
| 20      | 29     | Space            | E1  | -> Mapping 21              |
| 21      | 10     | Command          | B6  | Enable keyboard backlight? |
| 22      | 32     | B                | E3  | -> Mapping 23              |
| 23      | 10     | Command          | D0  | Ctrl+Break                 |
| 24      | 1B     | S                | E5  | -> Mapping 25              |
| 25      | 10     | Command          | D1  | SysReq                     |
| 26      | 42     | K                | E7  | -> Mapping 27              |
| 27      | 10     | Command          | D2  | ScrollLock                 |
| 28      | 4D     | P                | E9  | -> Mapping 29              |
| 29      | 10     | Command          | D3  | Pause                      |

## Patching the keyboard layout

Now that we know how the table is composed, we can re-assign the keys to the classic 7-row keyboard layout by moving some function keys around and fixing some wrong table entries (i.e. Pos1, Home, Del, PgUp, ...) also enabling NumLock.
However, there is a problem with the WW-Forward and WWW-Back keys, because their entry in the internal Mapping table cannot be reached due to the key ranges assigned mentioned above.
However, we see that Pause and Ctrl+Break are already mapped via the "Special" Tables for Fn, so the key codes 91 and 92 aren't really used.
Therefore, we update the table at offset 35f7c at the entry for 91 to use WWW-Fwd and WWW-Back instead:
These 2 entries are at offset 35f9e. Each entry consists of a Scancode and an Index to a function pointer. 01 is index for the function that just generates the E0 Make-code. So we change the table as follows:

| Int. Code | Old Scanc. | Old FuncID | New Scanc. | New FuncID |
| --------- | ---------- | ---------- | ---------- | ---------- |
| 91        | 00         | 04         | 38         | 01         |
| 92        | 01         | 04         | 30         | 01         |

After creating these 2 Keycodes, we can update the Keyboard layout table:

| Key              | Offset | Keycode | Fn Mapping | New Keycode | New Fn Mapping |
| ---------------- | ------ | ------- | ---------- | ----------- | -------------- |
| WWW-Back         | 6B     | 00      | N          | 91          |                |
| WWw-Fwd          | 7B     | 00      | N          | 92          |                |
| PrtScr           | 1D     | 00      | N          | 24          | Y              |
| ScrLock          | 2D     | 00      | N          | 0C          | Y              |
| Pause            | 6C     | 00      | N          | 22          | Y              |
| Right GUI (Menu) | 4B     | 9D      | N          | 84          |                |
| 7 &              | 14     | 3D      | N          | AA          |                |
| 8 \*             | 15     | 3E      | N          | AB          |                |
| 9 (              | 16     | 46      | N          | AC          |                |
| 0 )              | 17     | 45      | N          | BE          |                |
| U                | 24     | 3C      | N          | AD          |                |
| I                | 25     | 43      | N          | AE          |                |
| O                | 26     | 44      | N          | AF          |                |
| P                | 27     | 28      | Y          | BF          | N              |
| S                | 41     | 24      | Y          | 1B          | N              |
| J                | 44     | 3B      | N          | B0          |                |
| K                | 45     | 26      | Y          | B1          | N              |
| L                | 46     | 4B      | N          | B2          |                |
| ; :              | 47     | 4C      | N          | BD          |                |
| B                | 73     | 22      | Y          | 32          | N              |
| M                | 64     | 3A      | N          | B3          |                |
| . >              | 66     | 49      | N          | B4          |                |
| / ?              | 77     | 4A      | N          | BC          |                |
| space            | 78     | 20      | Y          | 29          | N              |
| Insert           | 09     | 00      | N          | A0          |                |
| Delete           | 0A     | A2      | N          | A1          |                |
| Home             | 0C     | 00      | N          | 18          | Y              |
| End              | 1C     | A3      | N          | 16          | Y              |
| PgUp             | 0B     | A1      | N          | 20          | Y              |
| PgDn             | 1B     | A0      | N          | A5          |                |
| Left             | 7C     | A6      | N          | 1A          | Y              |
| Up               | 5C     | A7      | N          | 26          | Y              |
| Down             | 7A     | A8      | N          | 1C          | Y              |
| Right            | 79     | A9      | N          | 1E          | Y              |
| F3               | 32     | 0C      | Y          | 04          | N              |
| F8               | 06     | 16      | Y          | 0A          | N              |
| F9               | 08     | 18      | Y          | 01          | N              |
| F10              | 18     | 1A      | Y          | 09          | N              |
| F11              | 1A     | 1C      | Y          | 78          | N              |
| F12              | 19     | 1E      | Y          | 07          | N              |

And the FN-Table:

| Mapping | Normal | FN  | New Key | New FN |
| ------- | ------ | --- | ------- | ------ |
| 0B      | 10     | C2  |         | C3     |
| 0C      | 04     | CD  | E7      |        |
| 0D      | 10     | C3  |         | BD     |
| 16      | 0A     | D7  | A3      |        |
| 18      | 01     | D9  | A2      |        |
| 1A      | 09     | DB  | A6      |        |
| 1C      | 78     | DD  | A8      |        |
| 1E      | 07     | DF  | A9      |        |
| 20      | 29     | E1  | A4      |        |
| 22      | 32     | E3  | E9      |        |
| 24      | 1B     | E5  | 9D      |        |
| 26      | 42     | E7  | A7      | E8     |
| 28      | 4D     | E9  | 10      | B7     |

This finally leads us to the
[new keyboard layout](../fwpat/models/Lx30/patches/kb/kbmap.new)

```
Offset      0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F

00000000   0E 05 0A 2E 36 55 0A 4E  01 A0 A1 20 18 00 00 8C
00000010   16 1E 26 25 AA AB AC BE  09 07 78 A5 16 24 00 00
00000020   15 1D 24 2D AD AE AF BF  6A 00 04 00 00 0C 00 00
00000030   0D 58 04 2C 35 5B 14 54  66 82 02 00 00 00 88 00
00000040   1C 1B 23 2B B0 B1 B2 BD  5D 00 00 84 00 00 00 00
00000050   76 61 0E 34 33 12 64 52  10 00 08 00 26 8A 00 00
00000060   1A 22 21 2A B3 41 B4 5D  5A 00 06 91 22 00 89 8D
00000070   67 8E 00 32 31 51 13 BC  29 1E 1C 92 1A 8B 00 00
00000080   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
00000090   04 18 00 30 00 24 40 04  00 04 24 15 00 14 00 16
000000A0   00 00 C1 C1 10 B0 C3 C3  30 B1 C5 C5 30 B2 C7 C7
000000B0   10 B3 C9 C9 30 B4 06 CB  10 C3 E7 CD 10 BD 0C CF
000000C0   10 C4 03 D1 10 C5 0B D3  10 C6 80 D5 10 C7 A3 D7
000000D0   30 BB A2 D9 30 BC A6 DB  30 B9 A8 DD 10 B8 A9 DF
000000E0   30 BA A4 E1 10 B6 E9 E3  10 D0 9D E5 10 D1 A7 E8
000000F0   10 D2 10 B7 10 D3 00
```

## Patching the keyboard layout

You MUST ensure that you have the correct EC firmware version in use!!
Firmware version must be: G3HT40WW(1.14)
If unsure, you can check i.e. in BIOS.

### Hotpatch keyboard layout at runtime

The easiest method is to just modify the layout at runtime. This also allows you
risk-free testing and is therefore recommended to check, if the layout works,
before permanently flashing it to the EC.

Advantage: 
Minimal invasive, just change EC memory

Disadvantage: 
It only lasts as long as there is enough power so the EC doesn't shut down

How to patch:
1) Compile [x2100-ec-sys](https://github.com/exander77/x2100-ec-sys) kernel module

2) Load module with write support

If module already loaded: `echo Y>/sys/module/x2100_ec_sys/parameters/write_support`
If module not loaded: `modprobe x2100_ec_sys write_support=1`

3) Verify that you have the correct firmware and the original table in place:
`dd if=/sys/kernel/debug/ec/ec0/ram bs=1 count=247 skip=$[0x366BD] 2>/dev/null | hexdump -C`

4) If it is the correct table from the top of this document, then you can patch the kbmap.new 
linked above in its place:

`dd if=kbmap.new of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$[0x366BD]`

and assign the WWW-Keys accordingly:

`echo -ne "\x38\x01\x30\x01" | dd of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$[0x35f9e]`

Keyboard map should be in place until you remove battery and power, to make it permanent, 
you need to reflash bios with patched EC firmware.


### Permanently patch firmware

Advantage:
Survives even power-off and battery removal, so loads again on EC-reinitialization

Disadvantage:
You have to re-flash your EC firmware. If something goes wrong, you may end up
with a bricked machine. Do this at your own risk. If something goes wrong, do not
complain!

How to patch:

1) Flash most recent stock firmware with EC Firmware version G3HT40WW(1.14)
so that you are at the current Firmware level and verify that stock FW works
and is OK.

2) Create file named `layout` with the following contents:
```
00000000:00000fff fd
00400000:007fffff bios
00400000:0041ffff ec
00001000:003fffff me 
```
Then read ec firmware with:

`flashrom -p internal -l layout -r current-bios.bin -i ec`


3) Verify that you have the correct firmware and the original table in place:

`dd if=/sys/kernel/debug/ec/ec0/ram bs=1 count=247 skip=$((0x3e7f00+0x366BD)) 2>/dev/null | hexdump -C`


3) Check BIOS image to verify that we are patching the correct region

`dd if=current-bios.bin bs=1 count=16 skip=$((0x3e7f00+0x28cea)) 2>/dev/null | hexdump -C`

4) If it is the correct table from the top of this document, then you can patch the kbmap.new 
linked above in its place:

`dd conv=notrunc if=kbmap.new of=current-bios.bin bs=1 seek=$((0x3e7f00+0x366BD))`

and assign the WWW-Keys accordingly:

`echo -ne "\x38\x01\x30\x01" | dd conv=notrunc of=current-bios.bin bs=1 seek=$((0x3e7f00+0x35f9e))`


5) Flash back BIOS to machine

   `flashrom -p internal -l layout -w new-bios.bin -i ec`

6) Power down machine, force reload of EC firmware by removing battery and AC power for 30 seconds

This has not been tested yet, but should work.

Good luck!
