# Configuration for E330
cfg_offs_rom_ec=$((0x800000))     # Offset of EC firmware in BIOS image (Layout in SPI EEPROM)
cfg_offs_img_rom=$((0x0))         # Offset of ROM image in firmware file (File -> SPI EEPROM)
cfg_offs_mem_fwver=$((0x35e9c))   # Offset of Firmware version string in RAM (absolute address)
cfg_stri_fwver="H3EC35WW(1.18)"   # EC Firmware version number this patch is for
