@echo off
echo Building KatOS 64-bit...

REM Create build directory if it doesn't exist
if not exist build mkdir build
if not exist src\boot mkdir src\boot
if not exist src\kernel mkdir src\kernel

REM Compile first stage bootloader
echo Compiling first stage bootloader...
nasm -f bin src\boot\boot_stage1.asm -o build\boot_stage1.bin
if %ERRORLEVEL% NEQ 0 (
    echo Failed to compile first stage bootloader!
    exit /b 1
)

REM Compile second stage bootloader
echo Compiling second stage bootloader...
nasm -f bin src\boot\boot_stage2.asm -o build\boot_stage2.bin
if %ERRORLEVEL% NEQ 0 (
    echo Failed to compile second stage bootloader!
    exit /b 1
)

REM Compile C kernel
echo Compiling kernel...
gcc -c -m64 -ffreestanding -mno-red-zone -O2 -Wall -Wextra -fno-exceptions -fno-rtti -fno-pic -fno-pie -nostdlib -nostdinc src\kernel\kernel.c -o build\kernel.o
if %ERRORLEVEL% NEQ 0 (
    echo Failed to compile kernel!
    exit /b 1
)

REM Link kernel
echo Linking kernel...
ld -m i386pep -o build\kernel.elf -T src\kernel\kernel.ld build\kernel.o
if %ERRORLEVEL% NEQ 0 (
    echo Failed to link kernel!
    exit /b 1
)

REM Extract binary from ELF
echo Extracting kernel binary...
objcopy -O binary build\kernel.elf build\kernel.bin
if %ERRORLEVEL% NEQ 0 (
    echo Failed to extract kernel binary!
    exit /b 1
)

REM Create disk image
echo Creating disk image...
copy /b build\boot_stage1.bin + build\boot_stage2.bin + build\kernel.bin build\katos.img
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create disk image!
    exit /b 1
)

REM Pad the image to proper size
echo Padding disk image...
powershell -Command "$file = 'build\katos.img'; $size = 1474560; $currentSize = (Get-Item $file).Length; if ($currentSize -lt $size) { $padding = New-Object byte[] ($size - $currentSize); $stream = [System.IO.File]::OpenWrite($file); $stream.Seek($currentSize, [System.IO.SeekOrigin]::Begin) > $null; $stream.Write($padding, 0, $padding.Length); $stream.Close() }"

echo Build completed successfully!