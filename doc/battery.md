# Patching Thinkpad L430/L530 battery check

## The Problem

The xx30 Series of Thinkpads unfortunately incorporate some kind of battery
check that makes it impossible to use an aftermarket and/or xx20 series
battery, even though i.e. T420 battery will perfectly fit into L530 and
also works.
The reason is some kind of challenge/response battery athentication mechanism
in the embedded controller. This was discovered by Dr. Matthew Chapman for his
X230T Thinkpad and very well documented in [his blog](https://zmatt.net/unlocking-my-lenovo-laptop-part-2/).
Unfortunately, the Thinkpad L430 and L530 series use a different embededd
controller (Nuvoton NPCE885G), so work had to be done to also patch this type
of controller.

## The authentication routine

The authentication routine for battery authentication as pretty similar to
the one that is described by ZMatt. Mainly just the order of steps is
different.
In Firmware G3HT40WW(1.14) the state machine routine is at `288ac`.
The state of the state machine including various flags is a 3 byte array at
`1004a`. The first 2 bytes can be seen as a little endian word, the 3rd
as a byte. However, to avoid confusion, I will address each byte seperately
in my description, so "byte 1" is at `1004a`, "byte 2" is at `1004b`, etc.
The lower 5 bits of the first word are indicating the state of the
autentication state machine which I partly will describe here, the other bits
are various flags.

| State | Description                                                                                                                                                        |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1     | Init                                                                                                                                                               |
| 2     | Wait for challenge to be constructed. The state machine for challenge construction and validation is at `3161a`. Start write command 0x27 (with 17-byte challenge) |
| 3     | check success, retry if necessary                                                                                                                                  |
| 4     | start read command 0x28                                                                                                                                            |
| 5     | check success, retry if necessary                                                                                                                                  |
| 6     | start write command 0x3c (with 4-byte challenge)                                                                                                                   |
| 7     | check success, retry if necessary                                                                                                                                  |
| 8     | start read command 0x3c                                                                                                                                            |
| 9     | check success, retry if necessary. Challenge is validated at state machine in `3161a`. If it succeeds, bit 0x40 in byte 2 of our 3 byte array at `1004a` is set.   |
| 12    | validate battery response                                                                                                                                          |

There are more states, but they are not interesting to us for our purpose.
The 4byte challenge, that gets written in Step 6, seems to be partly composed
of current system date in bytes 3 and 4.
The system date can be set by BIOS with the following 91h commands:

| Command | Description       |
| ------- | ----------------- |
| 5Dh xx  | Set current day   |
| 5Eh xx  | Set current month |
| 5Fh xx  | Set current year  |

If there is a failure in communicating with the Battery via SMbus,
there is a error recovery handler at `282c0` which resets the
state machine back to state 1 and saves the prvious state in
`1004a` byte 2.

If communication fails 5 times in a row, there is a failure handler
at `286d4` that clears some bits of `1004a` byte 2 (described later):

The state changes are:

| States   | Description              |
| -------- | ------------------------ |
| 2, 4     | Clear bit 6 in byte 2    |
| 6, 8     | Clear bit 5, 7 in byte 2 |
| 19,21,23 | Reset state machine to 0 |

In States 2-8, it sets bit 4 in `1004a` byte 3 to indicate failure.

`1004a` Byte 2 flags (Bit numbers are zero-based, little endian):

| Bit | Description                           |
| --- | ------------------------------------- |
| 7   | ?                                     |
| 6   | Battery authenticated                 |
| 5   | Allow charging of battery?            |
| 0-4 | Previous state machine state on retry |

`1004a` Byte 3 flags:

| Bit | Description                                                  |
| --- | ------------------------------------------------------------ |
| 5-7 | Ununsed                                                      |
| 4   | Battery auth comm. failed, handler at `286d4` got executed   |
| 3   | State 4 success, 17byte challenge read, check authentication |
| 2   | State 2 success                                              |
| 1   | Current date has been set by BIOS with call to 91h 5Fh       |
| 0   | State 12 check performed                                     |

Now let's have a look at the state transition in each 3 described
bytes when inserting a battery that doesn't support authentication.

| State            | Byte 1 | Byte 2 | Byte 3 |
| ---------------- | ------ | ------ | ------ |
| Battery in       | 00     | 22     | 13     |
| Battery removed  | 00     | 02     | 02     |
| Battery inserted | 01     | 06     | 02     |
|                  | 02     | 26     | 02     |
|                  | 01     | 22     | 02     |
|                  | 02     | 22     | 02     |
|                  | 01     | 22     | 02     |
|                  | 00     | 22     | 13     |

So battery gets plugged in, state machine starts at 1, progresses
to State 2, cryptographic challenge got prepared, 0x027 command
is sent and then fails.
It retries 5 times and then it finally sets error flag in byte 3
and resets state machine back to 0.

## Writing a patch for the authentication routine

Judging from the states above, we want to

- Go to state 12 in byte 1 (0x0C)
- Have bit 5 and 6 enabled in byte 2 (0x60).
- Ensure that state 12 runs, so bit 0 cleard in byte 3, but keep BIOS date/time set enabled (0x02)

So we can simply write these bytes to the state machine field and have
a temporary patch for an inserted battery.
But as swapping the battery etc. would reset back to the not-authenticated
state, having a permanent patch would be more desirable.
In order to do this, we have to skip from state 2 to state 12 and ensure that
Bits 5 and 6 in byte 2 get set. Byte 3 doesn't interest us, as we can just
skip over the check in state 12.
So the following patch should be enough:

| Address | Old instruction         | Old instr. bytes | New instr.              | New instr. bytes | State | Comment                                                                 |
| ------- | ----------------------- | ---------------- | ----------------------- | ---------------- | ----- | ----------------------------------------------------------------------- |
| 28a72   | BReq 0002915e           | 00 18 ec 06      | BR \*0x00028ac6         | e0 18 54 00      | 2     | Do net send battery auth challenge                                      |
| 28ade   | ORW 0x03, R0            | 30 26            | ORW 0x0C, R0            | c0 26            | 2     | Skip directly to state 12                                               |
| 28c68   | BRfs 0002915            | 80 18 f6 04      | BR 00028cc2             | e0 18 5a 00      | 12    | Always execute step (ignore byte 3 bit 0) and do not go back to state 6 |
| 28cea   | TBITB $0x06,\*0x1(R1R0) | 60 7b 01 00      | SBITB $0x06,\*0x1(R1R0) | 60 73 01 00      | 12    | Set battery authenticated bit                                           |
|         | BRfc 00028d26           | 9c 11            | SBITB $0x05,\*0x1(R1R0) | 50 73 01 00      | 12    | Set battery charging enable bit                                         |
|         |                         |                  | BR \*0x28d1e            | e0 18 2c 00      | 12    | Now go on to code where both bits were enabled                          |

The addresses are based on RAM offset of firmware. If you want to calculate the
address in firmware image, use the following calculation:

| Op  | Offset | Description                                              |
| --- | ------ | -------------------------------------------------------- |
|     | 400000 | Offset of EC firmware in BIOS image                      |
| +   | 8000   | Offset of code that gets loaded at memory location 20100 |
| -   | 20100  | Memory location of code                                  |

So the offset to add to the addresses above is `3e7f00` when patching firmware images.

## Patching the authentication routine

You MUST ensure that you have the correct EC firmware version in use!!
Firmware version must be: G3HT40WW(1.14)
If unsure, you can check i.e. in BIOS.

### Hotpatch memory at runtime

The easiest method is to just modify the state of the state machine at runtime.

Advantage:
Minimal invasive, just change EC memory

Disadvantage:
It only lasts as long as the battery is inserted in the machine
and there is enough power so the EC doesn't shut down

How to patch:

1. Compile [x2100-ec-sys](https://github.com/exander77/x2100-ec-sys) kernel module
2. If already installed, remove kernel module and reload it with write support:

```
rmmod x2100-ec-sys
modprobe x2100_ec_sys write_support=1
```

3. Ensure that battery is already inserted.
4. `echo -ne "\x0c\x60\x02" | dd of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$[0x1004a]`

Now battery should become ready and if not full start to charge.

### Hotpatch firmware code

Advantage:
No permanent changes to EC firmware, if it causes bad side effects,
you just need to remove battery and power to reset EC back to stock firmware.
Unlike memory hotpatch, also survives battery pack change.

Disadvantage:
It only lasts as long as there is enough power so the EC doesn't shut down

How to patch:

1. Compile [x2100-ec-sys](https://github.com/exander77/x2100-ec-sys) kernel module
2. If already installed, remove kernel module and reload it with write support:

```
rmmod x2100-ec-sys
modprobe x2100_ec_sys write_support=1
```

3. Patch the code from down to up so that it doesn't accidentally get jumped to
   while you are still patching, if it is still active during patching:

```
echo -ne "\x60\x73\x01\x00\x50\x73\x01\x00\xe0\x18\x2c\x00" | dd of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$((0x28cea))
echo -ne "\xe0\x18\x5a\x00" | dd of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$((0x28c68))
echo -ne "\xc0" | dd of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$((0x28ade))
echo -ne "\xe0\x18\x54\x00" | dd of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$((0x28a72))
```

4. If a battery is already inserted, kick off that state machine to rerun:

`echo -ne "\x02" | dd of=/sys/kernel/debug/ec/ec0/ram bs=1 seek=$((0x1004a))`

Now battery should become ready and if not full start to charge.
Swapping the battery also works.

### Permanently patch firmware

Advantage:
Survives even power-off and battery removal, so loads again on EC-reinitialization

Disadvantage:
You have to re-flash your EC firmware. If something goes wrong, you may end up
with a BRICKED MACHINE! Do this at your own risk. If something goes wrong, do not
complain!

DO NOT USE, PERMANENT FLASHING HASN'T BEEN TESTED YET!
This is just how it should work in theory. YOU HAVE BEEN WARNED!

1. Flash most recent stock firmware with EC Firmware version G3HT40WW(1.14)
   so that you are at the current Firmware level and verify that stock FW works
   and is OK.
   Also ensure that you have a backup of your current BIOS.

2. Create file named `layout` with the following contents:

```
00000000:00000fff fd
00400000:007fffff bios
00400000:0041ffff ec
00001000:003fffff me
```

Then read ec firmware with:

`flashrom -p internal -l layout -r current-bios.bin -i ec`

3. Check BIOS image to verify that we are patching the correct region

`dd if=current-bios.bin bs=1 count=16 skip=$((0x3e7f00+0x28cea)) 2>/dev/null | hexdump -C`

This should result in the following original code:

`60 7b 01 00 9c 11 72 5d 22 5f 20 55 20 4c 20 61 |`{....r]"\_ U L a|
`

4. Backup current-bios.bin somewhere safe, just in case you need it later.

5. Apply patches to image

```
echo -ne "\x60\x73\x01\x00\x50\x73\x01\x00\xe0\x18\x2c\x00" | dd conv=notrunc of=current-bios.bin bs=1 seek=$((0x3e7f00+0x28cea))
echo -ne "\xe0\x18\x5a\x00" | dd conv=notrunc of=current-bios.bin bs=1 seek=$((0x3e7f00+0x28c68))
echo -ne "\xc0" | dd conv=notrunc of=current-bios.bin bs=1 seek=$((0x3e7f00+0x28ade))
echo -ne "\xe0\x18\x54\x00" | dd conv=notrunc of=current-bios.bin bs=1 seek=$((0x3e7f00+0x28a72))
```

6. Unlock BIOS using ivyrain

   First, you would need to apply the [1vyrain](https://github.com/n4ru/1vyrain) patches to 
   enable the flash chip. Refer to start.sh script of 1vyrain.iso to see how this works.


7. Flash back BIOS to machine

   `flashrom -p internal -l layout -w new-bios.bin -i ec`

8. Power down machine, force reload of EC firmware by removing battery and AC power for 30 seconds

If it goes wrong, you need an external SPI flash programmer to recover.



Good luck!
