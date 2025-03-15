# Building KatOS
Compiling an operating system is not an easy task... The build environment we created for building KatOS is as simple as I can make it, where scripts are provided [here](/scripts) for only Windows (for now) to build.

> [!NOTE]
> KatOS is developed by [katniny](https://github.com/katniny) on Windows 10. Build instructions or scripts are not available on macOS, Linux, FreeBSD, or KatOS as of right now. 

> [!CAUTION]
> If any step fails, do NOT proceed. Start over (double check your dependencies) and if the issue persists, create an issue reporting it. Remember, KatOS is still in development!

# Requirements
- [*cross compiler*]: GCC 14.2.0, as the kernel and other code is written in C.
- [*assembly compiler*] nasm: The bootloader/kernel includes some small Assembly files ~~unfortunately~~.
- [*testing*]: QEMU: For testing KatOS without needing real hardware
    - **Note**: You may test using Virtualbox, VMWare, etc. but please note that is not supported, and if you create an issue related to this, we will tell you to use QEMU!

## Building
This is an operating system, meaning it has to be burnt into some sort of medium (disk, USB, floppy dirve, somewhere!)
> [!CAUTION]
> In case you want to try KatOS on real hardware, while nobody is liable for any damage is may cause, many features might not be available yet due to lack of drivers!

## Testing
In the base directory, run the following commands:
- `mkdir build` - as we .gitignore our build folder, as that'd basically be keeping the node_modules folder
- `.\build.bat` - to build KatOS
- `.\run.bat` - to run KatOS