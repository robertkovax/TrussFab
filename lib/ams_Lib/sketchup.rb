# The Sketchup namespace contains functions that allow user to get various
# information on SketchUp window and its child windows.
# @since 2.0.0
# @note Windows only!
module AMS::Sketchup
  class << self

    # Get module handle to the current SketchUp application.
    # @return [Fixnum]
    def get_module_handle
    end

    # Get full path to SketchUp.exe.
    # @return [String]
    def get_executable_path
    end

    # Get executable name of this application. In most cases it would be
    # "SketchUp.exe".
    # @return [String]
    # @since 3.1.0
    def get_executalbe_name
    end

    # Get registry path of the current SketchUp application.
    # @return [String]
    def get_registry_path
    end

    # Get process id of the current SketchUp application.
    # @return [Fixnum]
    def get_process_id
    end

    # Get thread id of the current SketchUp application.
    # @return [Fixnum]
    def get_thread_id
    end

    # Get handle to the main window of the current SketchUp application.
    # @return [Fixnum]
    def get_main_window
    end

    # Get handle to the menu bar of the main window.
    # @return [Fixnum]
    def get_menu_bar
    end

    # Get handle to the view window of the main window.
    # @return [Fixnum]
    def get_viewport
    end

    # Get handle to the status bar of the main window.
    # @return [Fixnum]
    def get_status_bar
    end

    # Get handle to the scenes bar of the main window.
    # @return [Fixnum]
    def get_scenes_bar
    end

    # Get handles to the four toolbar containers of the main window.
    # @return [Array<Fixnum>] <tt>[top toolbar, bottom toolbar, left toolbar,
    #   right toolbar]</tt>
    def get_toolbar_containers
    end

    # Switch main window full screen.
    # @param [Boolean] state +true+ to set full screen; +false+ unset from full
    #   screen.
    # @param [Fixnum] reset_mode This parameter has effect only when main window
    #   is unset from full screen mode. Use one of the following reset modes:
    #   * 0 - Set to restored mode.
    #   * 1 - Set to maximized mode.
    #   * 2 - Set to original placement.
    # @param [Fixnum] set_mode This parameter was added in 3.1.4 and has an
    #   effect only when main window is set to full screen. Use one of the
    #   following set modes:
    #   * 0 - Set full screen on the primary/main monitor.
    #   * 1 - Set full screen on the monitor SU window is associated to.
    #   * 2 - Set full screen on all monitors.
    # @return [Boolean] success
    def switch_full_screen(state, reset_mode = 2, set_mode = 1)
    end

    # Determine whether main window is full screen.
    # @return [Boolean]
    def is_full_screen?
    end

    # Set main window maximized.
    # @return [Boolean] success
    def maximize
    end

    # Determine whether main window is maximized.
    # @return [Boolean]
    def is_maximized?
    end

    # Set main window minimized.
    # @return [Boolean] success
    def minimize
    end

    # Determine whether main window is minimized.
    # @return [Boolean]
    def is_minimized?
    end

    # Set main window to normal placement.
    # @return [Boolean] success
    def restore
    end

    # Determine whether main window is restored.
    # @return [Boolean]
    def is_restored?
    end

    # Set main window active.
    # @return [Boolean] success
    def activate
    end

    alias bring_to_top activate

    # Set/Remove menu bar.
    # @param [Boolean] state
    # @return [Boolean] success
    def set_menu_bar(state)
    end

    # Determine whether menu bar is set.
    # @return [Boolean]
    def is_menu_bar_set?
    end

    # Set/Remove viewport border, a thin edge surrounding the view.
    # @param [Boolean] state
    # @return [Boolean] success
    def set_viewport_border(state)
    end

    # Determine whether viewport border is set.
    # @return [Boolean]
    def is_viewport_border_set?
    end

    # Show/Hide status bar.
    # @param [Boolean] state
    # @param [Boolean] refresh Whether to update after changing state.
    # @return [Boolean] success
    def show_status_bar(state, refresh = true)
    end

    # Determine whether status bar is visible.
    # @return [Boolean]
    def is_status_bar_visible?
    end

    # Show/Hide scenes bar.
    # @param [Boolean] state
    # @param [Boolean] refresh Whether to update after changing state.
    # @return [Boolean] success
    def show_scenes_bar(state, refresh = true)
    end

    # Determine whether scenes bar is visible.
    # @return [Boolean]
    def is_scenes_bar_visible?
    end

    # Determine whether scenes bar is filled. Scenes bar is filled if there
    # is at least one page in the model.
    # @return [Boolean]
    def is_scenes_bar_filled?
    end

    # Determine whether scenes bar is empty. Scenes bar is empty if there are
    # no pages in the model.
    # @return [Boolean]
    def is_scenes_bar_empty?
    end

    # Show/Hide toolbar container(s).
    # @param [Fixnum] bar A number representing which bar(s) to show/hide. Use
    #   one of the following numbers:
    #   1. top bar
    #   2. bottom bar
    #   3. left bar
    #   4. right bar
    #   5. all filled bars
    #   6. all bars
    # @param [Boolean] state +true+ to show; +false+ to hide.
    # @param [Boolean] refresh Whether to update after changing state.
    # @return [Boolean] success
    def show_toolbar_container(bar, state, refresh = true)
    end

    # Determine whether toolbar container(s) is/are visible.
    # @param [Fixnum] bar A number representing which bar(s) to check. Use
    #   one of the following numbers:
    #   1. top bar
    #   2. bottom bar
    #   3. left bar
    #   4. right bar
    #   5. at least one bar
    #   6. all bars
    #   7. all filled bars
    # @return [Boolean]
    def is_toolbar_container_visible?(bar)
    end

    # Determine whether toolbar container(s) is/are filled.
    # @param [Fixnum] bar A number representing which bar(s) to check. Use
    #   one of the following numbers:
    #   1. top bar
    #   2. bottom bar
    #   3. left bar
    #   4. right bar
    #   5. at least one bar
    #   6. all bars
    # @return [Boolean]
    def is_toolbar_container_filled?(bar)
    end

    # Determine whether toolbar container(s) is/are empty.
    # @param [Fixnum] bar A number representing which bar(s) to check. Use
    #   one of the following numbers:
    #   1. top bar
    #   2. bottom bar
    #   3. left bar
    #   4. right bar
    #   5. at least one bar
    #   6. all bars
    # @return [Boolean]
    def is_toolbar_container_empty?(bar)
    end

    # Get upper-left and lower-right corners of the view window in screen
    # coordinates, relative to the upper-left corner of the screen.
    # @return [Array<Fixnum>] +[x1,y1, x2,y2]+
    def get_viewport_rect
    end

    # Get upper-left corner of the view window in screen coordinates.
    # @return [Array<Fixnum>] +[x,y]+
    def get_viewport_origin
    end

    # Get width and height of the view window in pixels.
    # @note This is same as <tt>view.vp_width</tt> and <tt>view.vp_height</tt>.
    # @return [Array<Fixnum>] +[width, height]+
    def get_viewport_size
    end

    # Get viewport center in screen coordinates.
    # @return [Array<Fixnum>] +[x,y]+
    def get_viewport_center
    end

    # Show/Hide all dialogs.
    # @note Ignored dialogs won't be included in this operation.
    # @param [Boolean] state
    # @return [Fixnum] Number of dialogs shown or hidden.
    def show_dialogs(state)
    end

    # Close all dialogs.
    # @note Ignored dialogs won't be included in this operation.
    # @return [Fixnum] Number of dialogs closed.
    def close_dialogs
    end

    # Include dialog in the {show_dialogs} and {close_dialogs} operations.
    # @note By default, all dialogs are included in the show/hide/close dialogs
    #   operation. This method is used to remove dialog from the ignore list.
    # @param [Fixnum] handle A handle to a dialog window.
    # @return [Boolean] success
    def include_dialog(handle)
    end

    # Elude dialog from the {show_dialogs} and {close_dialogs} operations.
    # @param [Fixnum] handle A handle to a valid dialog window.
    # @return [Boolean] success
    def ignore_dialog(handle)
    end

    # Show/Hide all floating toolbars.
    # @param [Boolean] state
    # @return [Fixnum] Number of floating toolbars shown or hidden.
    def show_toolbars(state)
    end

    # Close all floating toolbars.
    # @return [Fixnum] Number of floating toolbars closed.
    def close_toolbars
    end

    # Include toolbar in the {show_toolbars} and {close_toolbars} operations.
    # @note By default, all toolbars are included in the show/hide/close
    #   toolbars operation. This method is used to remove toolbar from the
    #   ignore list.
    # @param [Fixnum] handle A handle to a toolbar window.
    # @return [Boolean] success
    # @since 3.0.0
    def include_toolbar(handle)
    end

    # Elude toolbar from the {show_toolbars} and {close_toolbars} operations.
    # @param [Fixnum] handle A handle to a valid toolbar window.
    # @return [Boolean] success
    # @since 3.0.0
    def ignore_toolbar(handle)
    end

    # Determine whether SketchUp main window is active.
    # @return [Boolean]
    def is_main_window_active?
    end

    # Determine whether the current active window belongs to the current
    # SketchUp application.
    # @return [Boolean]
    def is_active?
    end

    # Find handle to a window with a specific caption.
    # @note This function will iterate through windows belonging to the current
    #   SketchUp process only. All windows belonging to a different process or a
    #   different SketchUp application will not be searched.
    # @param [String] caption Text to match.
    # @param [Boolean] full_match Whether to match full (+true+) or part
    #   (+false+) of the window text.
    # @param [Boolean] case_sensitive Whether to consider uppercased/lowercased
    #   letters.
    # @return [Fixnum, nil] Handle to the first found window if any.
    # @since 3.0.0
    def find_window_by_caption(caption, full_match = true, case_sensitive = true)
    end

    # Find handle to a child window with a specific caption.
    # @note This function will iterate through windows belonging to the current
    #   SketchUp process only. All windows belonging to a different process or a
    #   different SketchUp application will not be searched.
    # @param [Fixnum] parent_handle Handle to a valid parent window.
    # @param [String] caption Text to match.
    # @param [Boolean] include_sub_childs Whether to include windows descending
    #   from the child windows.
    # @param [Boolean] full_match Whether to match full (+true+) or part
    #   (+false+) of the window text.
    # @param [Boolean] case_sensitive Whether to consider uppercased/lowercased
    #   letters.
    # @return [Fixnum, nil] Handle to the first found window if any.
    # @since 3.0.0
    def find_child_window_by_caption(parent_handle, caption, include_sub_childs = false, full_match = true, case_sensitive = true)
    end

    # Find handle to a window with a specific class name.
    # @note This function will iterate through windows belonging to the current
    #   SketchUp process only. All windows belonging to a different process or a
    #   different SketchUp application will not be searched.
    # @param [String] class_name Text to match.
    # @param [Boolean] full_match Whether to match full (+true+) or part
    #   (+false+) of the window class name.
    # @param [Boolean] case_sensitive Whether to consider uppercased/lowercased
    #   letters.
    # @return [Fixnum, nil] Handle to the first found window if any.
    # @since 3.0.0
    def find_window_by_class_name(class_name, full_match = true, case_sensitive = true)
    end

    # Find handle to a child window with a specific class name.
    # @note This function will iterate through windows belonging to the current
    #   SketchUp process only. All windows belonging to a different process or a
    #   different SketchUp application will not be searched.
    # @param [Fixnum] parent_handle Handle to a valid parent window.
    # @param [String] class_name Text to match.
    # @param [Boolean] include_sub_childs Whether to include windows descending
    #   from the child windows.
    # @param [Boolean] full_match Whether to match full (+true+) or part
    #   (+false+) of the window class name.
    # @param [Boolean] case_sensitive Whether to consider uppercased/lowercased
    #   letters.
    # @return [Fixnum, nil] Handle to the first found window if any.
    # @since 3.0.0
    def find_child_window_by_class_name(parent_handle, class_name, include_sub_childs = false, full_match = true, case_sensitive = true)
    end

    # Get all pop-up windows of the current SketchUp application.
    # @note Ignored dialogs are not included in this list.
    # @return [Array<Fixnum>] An array of window handles.
    def get_dialogs
    end

    # Get all used pop-up windows of the current SketchUp application.
    # @note Ignored dialogs are not included in this list.
    # @return [Array<Fixnum>] An array of window handles.
    def get_active_dialogs
    end

    # Get all visible pop-up windows of the current SketchUp application.
    # @note Ignored dialogs are not included in this list.
    # @return [Array<Fixnum>] An array of window handles.
    def get_visible_dialogs
    end

    # Get all floating toolbars of the current SketchUp application.
    # @note Ignored toolbars are not included in this list.
    # @return [Array<Fixnum>] An array of window handles.
    def get_toolbars
    end

    # Get all used floating toolbars.
    # @note Ignored toolbars are not included in this list.
    # @return [Array<Fixnum>] An array of window handles.
    def get_active_toolbars
    end

    # Get all visible floating toolbars of the current SketchUp application.
    # @note Ignored toolbars are not included in this list.
    # @return [Array<Fixnum>] An array of window handles.
    def get_visible_toolbars
    end

    # Get main window title text.
    # @return [String]
    def get_caption
    end

    # Set main window title text.
    # @param [String] caption
    # @return [Boolean] success
    def set_caption(caption)
    end

    # Refresh the current SketchUp application.
    # @return [Boolean] success
    def refresh
    end

    # Close current SketchUp application.
    # @note This behaves the same way as clicking the 'X' button.
    # @return [Boolean] success
    def close
    end

    # Add object to the observers list.
    # @note An observer can be a class, module, or a class instance. Your
    #   observer will work as long as the callback methods are public.
    # @note Your observer is not supposed to contain every callback method from
    #   the observers list. You may include/elude those as you wish.
    # @note A unique extension +swp+ or +swo+ is added in front of each observer
    #   method. SWP stands for Sketchup Window Procedure, and SWO stands for
    #   Sketchup Window Observer. Both SWP and SWO events are capable to monitor
    #   window messages, but SWP events are also capable to make decisions to
    #   the message, whether or not the message should interact with SketchUp
    #   window. If the return value for the SWP callback method is 1, the
    #   message associated with the event will not interact with SketchUp
    #   window. For example, returning 1 in the swp_on_key_down event will
    #   prevent the key from interacting with SketchUp window, which means any
    #   shortcut associated with such key will not be triggered. SWP events may
    #   come in handy for extensions that want more control over SketchUp.
    # @param [Object] object
    # @return [Boolean] success
    # @example Adding observer from a class instance:
    #   class MySketchupObserver
    #     def swo_on_switch_full_screen(state)
    #       puts 'Main window was set full screen!' if state
    #     end
    #   end # module MySketchupObserver
    #   AMS::Sketchup.add_observer(MySketchupObserver.new)
    # @example Adding observer from a module:
    #   module MySketchupObserver
    #     def self.swo_on_switch_full_screen(state)
    #       puts 'Main window was set full screen!' if state
    #     end
    #   end # module MySketchupObserver
    #   AMS::Sketchup.add_observer(MySketchupObserver)
    # @example Another way to add observer from a module:
    #   module MySketchupObserver
    #     class << self
    #       def swo_on_switch_full_screen(state)
    #         puts 'Main window was set full screen!' if state
    #       end
    #     end # class << self
    #   end # module MySketchupObserver
    #   AMS::Sketchup.add_observer(MySketchupObserver)
    # @see AMS::SketchupObserver
    def add_observer(object)
    end

    # Remove object from the observers list.
    # @param [Object] object
    # @return [Boolean] success
    def remove_observer(object)
    end

    # Get handles to all SketchUp main windows, except for the current one.
    # @return [Array<Fixnum>]
    # @since 3.1.0
    def get_other_main_windows
    end

    # Send information to another window.
    # @note If a destination window that a message is sent to by this function
    #   has an active <tt>swo_on_user_message</tt> observer, in most cases, it
    #   will receive the message sent by this function; otherwise, it wont.
    # @note This function waits until the receiving window completes
    #   processing a message before returning.
    # @note 32-bit SU windows cannot communicate to 64-bit SU windows; However,
    #   64-bit SU windows can communicate to 32-bit SU windows. For example,
    #   assume you have two SU windows open, SU2014 (32-bit) and SU2016
    #   (64-bit). Calling <tt>send_user_message</tt> from the SU2014 window to
    #   the SU2016 window, will not succeed in the SU2016 window receiving the
    #   message. However, if you call <tt>send_user_message</tt> from the SU2016
    #   window to the SU2014 window, the message will succeed in being received
    #   by the SU2014 window.
    # @param [Fixnum, nil] receiver_handle A handle to a destination window.
    #   Pass +nil+ to send to all windows.
    # @param [Fixnum] id A unique message identifier to send along with a
    #   message, a value between 0 and 4095. The ID feature allows user to
    #   easily filter his/her messages from other messages.
    # @param [nil, Boolean, Fixnum, Bignum, Float, String, Symbol, Array, Hash]
    #   user_data Information to transfer along with a message. An Array and a
    #   Hash can only contain objects of +NilClass+, +TrueClass+, +FalseClass+,
    #   +Fixnum, +Float+, +Bignum+, +String+, +Symbol+, +Array+, and +Hash+
    #   types. This, as well, applies to sub-arrays and sub-hashes.
    # @return [Boolean] success
    # @raise [TypeError] if given handle to a window is not valid.
    # @raise [RangeError] if given ID is not within a range of 0 and 4095.
    # @raise [TypeError] if given user-data or sub-user-data type is not
    #   supported.
    # @example
    #   # Open two or more SketchUp windows and paste the following, except the last
    #   # line, into the Ruby consoles of each SketchUp window.
    #   class MyTool
    #
    #     # Our unique communication id
    #     PORT = 123
    #
    #     def communicate_to_others(text)
    #       others = AMS::Sketchup.get_other_main_windows
    #       others.each { |handle|
    #         AMS::Sketchup.send_user_message(handle, PORT, text.to_s)
    #       }
    #     end
    #
    #     def swo_on_user_message(sender, id, data)
    #       # Don't bother processing the message if ID is not ours.
    #       return if (id != PORT)
    #       # Process the message.
    #       p data
    #     end
    #
    #   end # class MyTool
    #
    #   my_tool = MyTool.new
    #   # Register our class with SketchUp window observers.
    #   AMS::Sketchup.add_observer(my_tool)
    #
    #   # Paste the following into one of the SU windows. Ensure that Ruby
    #   # consoles are still open in other SU windows.
    #   # As a result of calling the command below, all other SU windows should
    #   # end-up having a hello message displayed in their Ruby consoles.
    #   my_tool.communicate_to_others("Hello! I'm sent from a SketchUp window with a process id of #{Process.pid}")
    # @since 3.1.0
    def send_user_message(receiver_handle, id, user_data)
    end

  end # class << self
end # module AMS::Sketchup
