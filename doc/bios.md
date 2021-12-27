# Documentations of Battery check in BIOS

The BIOS Check for Battery is in `Section_PE32_image_CC71B046-CF07-4DAE-AEAD-7046845BCD8A_LenovoVideoInitDxe.efi_body.bin`
Maybe useful for reversing to know command?
```c
  if (EcIoDxe->Command(EcIoDxe, 0x88) & 1)
  {
    v3 = EcIoDxe->Command(EcIoDxe, 0xC2);
    if ( v3 < 0 && !(v3 & 0x20) )
    {
      ((void (__fastcall *)(EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *))EfiHandle->ConOut->ClearScreen)(EfiHandle->ConOut);
      sub_2850(15i64);
      sub_2864(0i64, 0i64);
      v5 = L"This system does not support batteries that are not genuine Lenovo-made or \n"
            "\rauthorized. The system will continue to boot, but may not charge unauthorized \n"
            "\rbatteries. \n"
            "\r\n"
            "ATTENTION: Lenovo has no responsibility for the performance or safety of \n"
            "\runauthorized batteries, and provides no warranties for failures or damage \n"
            "\rarising out of their use. \n"
            "\r\n"
            "Press the ESC key to continue.";
      if ( v3 & 0x50 )
        v5 = L"The battery installed is not supported by this system and will not charge.\n"
              "\rPlease replace the battery with the correct Lenovo battery for this system. \n"
              "\rPress the ESC key to continue.";
      sub_287C(v5);
```

For better understanding of Command sequence, here is what EcIoDxe  (`Section_PE32_image_114CA60C-D965-4C13-BEF7-C4062248E1FA_EcIoDxe.efi_body.bin`) does:

```c
#define EC_OEM_DATA	0x68
#define EC_OEM_SC	0x6c

/* EC_SC input */
#define   EC_SMI_EVT	(1 << 6) // 1: SMI event pending
#define   EC_SCI_EVT	(1 << 5) // 1: SCI event pending
#define   EC_BURST	(1 << 4) // controller is in burst mode
#define   EC_CMD	(1 << 3) // 1: byte in data register is command
				 // 0: byte in data register is data
#define   EC_IBF	(1 << 1) // 1: input buffer full (data ready for ec)
#define   EC_OBF	(1 << 0) // 1: output buffer full (data ready for host)
/* EC_SC output */
#define   RD_EC		0x80 // Read Embedded Controller
#define   WR_EC		0x81 // Write Embedded Controller
#define   BE_EC		0x82 // Burst Enable Embedded Controller
#define   BD_EC 	0x83 // Burst Disable Embedded Controller
#define   QR_EC 	0x84 // Query Embedded Controller

EFI_STATUS __fastcall FlushInput(BYTE ecsc, BYTE ecdata)
{
  BYTE buf;
  EFI_STATUS ret;

  while (1)
  {
    ret = CpuIo->Io->Read(NULL, EfiCpuIoWidthUint8, ecsc, 1, &buf);
    if (!(buf & EC_OBF)) break;
    CpuIo->Io->Read(NULL, EfiCpuIoWidthUint8, ecdata, 1, &buf);
  }
  return ret;
}

EFI_STATUS __fastcall WaitReady(BYTE ecsc)
{
  int i;
  BYTE buf;
  EFI_STATUS ret;

  for(i = 33; i; i--)
  {
    ret = CpuIo->Io->Read(NULL, EfiCpuIoWidthUint8, ecsc, 1, &buf);
    if (!(buf & EC_OBF)) break;
    gBootSvc->Stall(30);
  }
  return ret;
}

EFI_STATUS __fastcall WaitForAnswer(BYTE ecsc)
{
  int i;
  BYTE buf;
  EFI_STATUS ret;

  for(i = 33; i; i--)
  {
    ret = CpuIo->Io->Read(NULL, EfiCpuIoWidthUint8, ecsc, 1, &buf);
    if (!(buf & EC_IBF)) break;
    gBootSvc->Stall(30);
  }
  return ret;
}

BYTE __fastcall EcOemRead(BYTE ecsc, BYTE ecdata, BYTE cmd)
{
  BYTE buf;

  FlushInput(ecsc, ecdata);
  WaitReady(ecsc);
  buf = RD_EC;
  CpuIo->Io->Write(NULL, EfiCpuIoWidthUint8, ecsc, 1, &buf);
  WaitForAnswer(ecsc);
  CpuIo->Io->Write(NULL, EfiCpuIoWidthUint8, ecdata, 1, &cmd);
  WaitForAnswer(ecsc);
  CpuIo->Io->Read(NULL, EfiCpuIoWidthUint8, ecdata, 1, &buf);
  return buf;
}

BYTE __fastcall Command(void *this, BYTE cmd)
{
    return EcOemRead(EC_OEM_SC, EC_OEM_DATA, cmd);
}
```
