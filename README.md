AVRFuses
========

A simple, graphical AVR fuse editor front end for avrdude

More information available at http://vonnieda.org/AVRFuses

Pull requests welcome!

# Compiling

Just load AVRFuses.xcodeproj up in XCode and hit Go.

# BuildCache

AVRFuses uses a file called AVRFuses.parts for it's part data. The file is generated with the included BuildCache program by reading the devices data in AVR Studio.

BuildCache is written in C# and works under Mono.

To compile:

    > cd BuildCache/
    > mcs BuildCache.cs
    > mono BuildCache.exe
    BuildCache.exe <path to AVR Studio devices directory> <path to AVRFuses.parts output file>
    
    
