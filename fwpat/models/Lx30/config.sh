# Configuration for Lx30
cfg_offs_rom_ec=$((0x400000))     # Offset of EC firmware in BIOS image (Layout in SPI EEPROM)
cfg_offs_img_rom=$((0x1d0))       # Offset of ROM image in firmware file (File -> SPI EEPROM)
cfg_offs_mem_fwver=$((0x353ec))   # Offset of Firmware version string in RAM (absolute address)
cfg_stri_fwver="G3HT40WW(1.14)"   # EC Firmware version number this patch is for
