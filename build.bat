@echo off
echo Building katOS test version...

REM Create build directory if it doesn't exist
if not exist build mkdir build

REM Compile bootloader
echo Compiling bootloader...
nasm -f bin src\boot\boot.asm -o build\boot.bin
if %ERRORLEVEL% NEQ 0 (
    echo Failed to compile bootloader!
    exit /b 1
)

REM Compile assembly kernel (temporary test)
echo Compiling test kernel...
nasm -f bin src\kernel\test_kernel.asm -o build\kernel.bin
if %ERRORLEVEL% NEQ 0 (
    echo Failed to compile test kernel!
    exit /b 1
)

REM Create disk image
echo Creating disk image...
copy /b build\boot.bin + build\kernel.bin build\katos.img
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create disk image!
    exit /b 1
)

REM Pad the image to floppy size (1.44MB)
echo Padding disk image...
powershell -Command "$file = 'build\katos.img'; $size = 1474560; $currentSize = (Get-Item $file).Length; if ($currentSize -lt $size) { $padding = New-Object byte[] ($size - $currentSize); $stream = [System.IO.File]::OpenWrite($file); $stream.Seek($currentSize, [System.IO.SeekOrigin]::Begin) > $null; $stream.Write($padding, 0, $padding.Length); $stream.Close() }"

echo Build completed successfully!