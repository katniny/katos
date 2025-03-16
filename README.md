> [!CAUTION]
> KatOS is in a very early state, and some parts of the README and other "documentation" files may not be 100% accurate, whether outdated or not yet implemented. 

# 🐾 KatOS
**A work-in-progress 64-bit operating system focused on performance, privacy, and eventually running Linux and Windows apps natively.**

## About
KatOS is a personal project to build a graphical operating system that blends the best parts of Linux and Windows while staying lightweight and fast. It's still in very early stages, so don't expect a fully functional OS just yet. Right now, it's more of a proof of concept.

## Current State
- **Super Early Development**: not much works yet, but progress is being made!
- **64-bit**: focusing on modern hardware to keep things simple.
- **Linux App Support (Planned)**: aiming to run Linux applications natively.
- **Windows App Support (Long-Term Goal)**: this is the dream, but it's definitely a ways off.
- **Privacy-First**: no telemetry, no tracking. Your data stays yours.

## Long-Term Vision
Someday, KatOS will be able to run apps from Linux, Windows, macOS, and our own native format all under one kernel. For now, though, the focus is just getting a functional base and running Linux apps (as it's the simplest).

## Contributing
If you want to mess around with the code or give feedback, feel free to open issues or submit Pull Requests! Just keep in mind that things are still super experimental and early.

## Is this a Linux distro?
No! The KatOS kernel does not share source code or headers with Linux. The KatOS kernel supports Linux applications, but Linux is not our bootloader nor kernel. KatOS' bootloader and kernel is made from scratch by us!

KatOS isn't, and never will be, "just another Linux distro".

## Build Status
> [!NOTE]
> This is temporary, until KatOS is graphical!

- **Build**: Successful
- **Run** (tested with QEMU): Failed
    - **Real Mode (16-bit)**: Successful!
    - **Protected Mode (32-bit)**: Gets to this point, but fails.
    - **Long Mode (64-bit)**: Fails.
    - **KatOS Kernel**: Appears to correctly load, but due to 32-bit getting stuck, does not continue.

## License
KatOS, at least for now, is licensed under CC BY-NC-SA 4.0. More info in [LICENSE](/LICENSE).