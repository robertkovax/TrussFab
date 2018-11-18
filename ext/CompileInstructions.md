# Windows
Refer to the following instructions for compiling <tt>tfn_lib.so</tt> with Visual Studio:

1. Set build configuration to <tt>Release (X.Y)</tt>.
2. Set build platform to <tt>x86</tt> or <tt>x64</tt>.
2. Build Solution.
3. Copy <tt>.../vs/[Win32/x64]/Release (X.Y)/tfn_lib/tfn_lib.so</tt>
   to the appropriate binary folder:
   <tt>/bin/[win32/win64]/[X.Y]/</tt>

# Mac OS X
Refer to the following instructions for compiling <tt>tfn_lib.bundle</tt> with xCode:

1. Set active scheme to <tt>Ruby (X.Y) - [32/64]</tt>.
2. Execute <tt>(Menu) Product > Archive</tt>
3. Export the built archive to your documents.
4. Locate <tt>tfn_lib.bundle</tt> within the exported archive.
5. Copy <tt>tfn_lib.bundle</tt> to the appropriate binary folder:
   <tt>/bin/[osx32/osx64]/[X.Y]/</tt>
