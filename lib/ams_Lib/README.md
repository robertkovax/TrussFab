# AMS Library

[Homepage](http://sketchucation.com/forums/viewtopic.php?f=323&t=55067#p499835)

[GitHub](https://github.com/AntonSynytsia/AMS-Library)

[Documentation](http://www.rubydoc.info/github/AntonSynytsia/AMS-Library/master/index)


## Description

AMS Library is a collection of tools and functions used to interact with
SketchUp window and its sub-windows using Microsoft Windows API. It's capable of
switching SketchUp full screen and changing visibility state of toolbar
containers, status bar, scenes bar, and other elements of the windows. It is
also capable of observing and making decisions to various events and messages of
SketchUp window procedure. That is, AMS Library is capable of blocking and
monitoring keyboard and mouse messages that reach Sketchup window procedure.
Such feature is essential for developers who seek more control over SketchUp
application, that is, for the purpose of creating games for example. As well,
this library comes with many Windows API utilities that allow developer to tweak
his/her webdialogs to a new level. In many ways, this library is written to
achieve things that cannot be done with a standard SketchUp API.


## Synopsis
    require 'ams_Lib/main'

    # Get handle to SketchUp window.
    AMS::Sketchup.get_main_window

    # Setting SketchUp full screen on the monitor SU window is associated to.
    AMS::Sketchup.switch_full_screen(true)

    # Setting SketchUp full screen on all monitors.
    AMS::Sketchup.switch_full_screen(true, 2, 2)

    # Monitoring and processing SketchUp window events.
    class MySketchupObserver

      def swo_on_switch_full_screen(state)
        if state
          puts 'Main window switched full screen!'
        else
          puts 'Main window switched to original placement.'
        end
      end

      def swp_on_mouse_wheel_rotate(x,y, dir)
        puts "mouse wheel rotated - pos : (#{x}, #{y}), dir : #{dir}"
        # Prevent mouse wheel from interacting with SU window. Returning 1 means
        # mouse wheel zoom in/out operation would be blocked, which might be
        # handy for those seeking more control over SketchUp window. Returning
        # any other value won't block the event.
        return 1
      end

    end # class MySketchupObserver

    AMS::Sketchup.add_observer(MySketchupObserver.new)


## Requirements

* Microsoft Windows XP, Vista, 7, 8, 10.
* Mac OS X 10.5+ (Limited)
* SketchUp 6 or later.


## Version

3.5.1


## Release Date

July 17, 2017


## Licence

[MIT](https://opensource.org/licenses/MIT)


## Credits

* Mr.K, Dan Rathbun, ThomThom, Chris Fullmer, Aerilius, and many other SketchUcation
  members for improving my scripting level.
* Aleksey Synytsia (My dad) for helping out with MSFT Windows API.


## Copyright

© 2013-2017 Anton Synytsia.
All Rights Reserved.


## Author

Anton Synytsia {mailto:anton.synytsia@gmail.com}
