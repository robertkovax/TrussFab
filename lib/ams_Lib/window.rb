# The Window namespace contains functions that are associated with Windows
# window.
# @since 2.0.0
# @note Windows only!
module AMS::Window
  class << self

    # Determine whether handle is a reference to a valid window.
    # @param [Fixnum] handle A handle to be tested.
    # @return [Boolean]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633528(v=vs.85).aspx IsWindow
    def is_valid?(handle)
    end

    # Determine whether window is active.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    def is_active?(handle)
    end

    # Determine whether window is visible.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633530(v=vs.85).aspx IsWindowVisible
    def is_visible?(handle)
    end

    # Determine whether window is unicode.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms633529(v=vs.85).aspx IsWindowUnicode
    # @since 3.0.0
    def is_unicode?(handle)
    end

    # Determine whether window is maximized.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633531(v=vs.85).aspx IsZoomed
    def is_maximized?(handle)
    end

    # Determine whether window is minimized.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633527(v=vs.85).aspx IsIconic
    def is_minimized?(handle)
    end

    # Determine whether window is restored; not maximized nor minimized.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    def is_restored?(handle)
    end

    # Determine whether window is a child window of a specific parent window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] parent_handle Handle to a valid parent window.
    # @return [Boolean]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633524(v=vs.85).aspx IsChild
    # @since 3.0.0
    def is_child?(handle, parent_handle)
    end

    # Set show state of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] state
    # @return [Boolean] True if window was previously visible; false if window
    #   was previously hidden.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633548(v=vs.85).aspx ShowWindow
    def show(handle, state)
    end

    # Get active window.
    # @return [Fixnum] A handle to an active window.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms646292(v=vs.85).aspx GetActiveWindow
    def get_active
    end

    # Set active window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Fixnum] A handle to an original active window.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms646311(v=vs.85).aspx SetActiveWindow
    def set_active(handle)
    end

    # Get parent window of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Fixnum, nil] If the window is a child window, the return value is
    #   a handle to the parent window. If the window is a top-level window with
    #   the WS_POPUP style, the return value is a handle to the owner window.
    #   Otherwise, the return value is +nil+.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633510(v=vs.85).aspx GetParent
    def get_parent(handle)
    end

    # Set parent window of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] parent_handle Handle to a valid parent window.
    # @return [Fixnum, nil] If the functions succeeds, the return values is a
    #   handle to the previous parent window. Otherwise, the return value is
    #   +nil+.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633541(v=vs.85).aspx SetParent
    def set_parent(handle, parent_handle)
    end

    # Get window ancestor.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] flag An ancestor:
    #   1. parent window
    #   2. root window
    #   3. root owner window
    # @return [Fixnum, nil] A handle to the ancestor window if any.
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms633502(v=vs.85).aspx GetAncestor
    # @since 3.0.0
    def get_ancestor(handle, flag)
    end

    # Bring window to the top of Z order. If window is a top-level window, it is
    # activated. If window is a child window, the top-level parent window
    # associated with the child window is activated.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms632673(v=vs.85).aspx BringWindowToTop
    # @since 3.0.0
    def bring_to_top(handle)
    end

    # Get class name of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [String]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633582(v=vs.85).aspx GetClassName
    def get_class_name(handle)
    end

    # Get related window of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] command See link below for existing commands.
    # @return [Fixnum, nil] A handle to a related window if any.
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms633515(v=vs.85).aspx GetWindow
    # @since 3.0.0
    def get_related(handle, command)
    end

    # Get thread identifier of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Fixnum]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633522(v=vs.85).aspx GetWindowThreadProcessId
    def get_thread_id(handle)
    end

    # Get process identifier of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Fixnum]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633522(v=vs.85).aspx GetWindowThreadProcessId
    def get_process_id(handle)
    end

    # Get window long.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] index
    # @return [Fixnum] Window long.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633584(v=vs.85).aspx GetWindowLong
    def get_long(handle, index)
    end

    # Set window long.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] index
    # @param [Fixnum] long
    # @return [Fixnum] Previous window long.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633591(v=vs.85).aspx SetWindowLong
    def set_long(handle, index, long)
    end

    # Get window menu.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Fixnum, nil] A handle to the menu. If the specified window has no
    #   menu, the return value is +nil+.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647640(v=vs.85).aspx GetMenu
    def get_menu(handle)
    end

    # Set window menu.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum, nil] menu_handle A handle to the new menu. If this
    #   parameter is +nil+, the window's current menu is removed.
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647995(v=vs.85).aspx SetMenu
    def set_menu(handle, menu_handle)
    end

    # Get window text.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [String]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633520(v=vs.85).aspx GetWindowText
    # @since 3.0.0
    def get_caption(handle)
    end

    # Set window text.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [String] caption
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633546(v=vs.85).aspx SetWindowText
    # @since 3.0.0
    def set_caption(handle, caption)
    end

    # Get upper-left and lower-right coordinates of a window in screen
    # coordinates, relative to the upper-left corner of the screen.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Array<Fixnum>] An array of four numeric values, representing
    #   upper-left and lower-right coordinates: [x1,y1, x2,y2].
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633519(v=vs.85).aspx GetWindowRect
    def get_rect(handle)
    end

    # Set upper-left and lower-right coordinates of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] x1
    # @param [Fixnum] y1
    # @param [Fixnum] x2
    # @param [Fixnum] y2
    # @param [Boolean] b_activate Whether to activate the window.
    # @return [Boolean] success
    def set_rect(handle, x1, y1, x2, y2, b_activate = true)
    end

    # Get upper-left and lower-right coordinates of the window's client area in
    # client coordinates, relative to the upper-left corner of the window's
    # client area. Because coordinates are relative to the upper-left corner of
    # the client area, the coordinates of the upper-left corner are (0,0).
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Array<Fixnum>] An array of four numeric values, representing
    #   upper-left and lower-right coordinates: [x1,y1, x2,y2].
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633503(v=vs.85).aspx GetClientRect
    def get_client_rect(handle)
    end

    # Adjust window rect.
    # @param [Array<Fixnum>] rect
    # @param [Fixnum] style
    # @param [Fixnum] style_ex
    # @param [Boolean] b_menu Whether window contains a menu.
    # @return [Array<Fixnum>] New rect: [x1,y1, x2,y2].
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms632667(v=vs.85).aspx AdjustWindowRectEx
    def adjust_rect(rect, style, style_ex, b_menu)
    end

    # Get window placement.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Array<(Fixnum, Fixnum, Fixnum, Array<Fixnum>, Array<Fixnum>, Array<Fixnum>)>]
    #   An array of six objects representing window placement:
    #   +[length, flags, show_cmd, min_pt, max_pt, rect]+.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633518(v=vs.85).aspx GetWindowPlacement
    def get_placement(handle)
    end

    # Set Window Placement.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] flags
    # @param [Fixnum] show_cmd
    # @param [Array<Fixnum>] min_pt (x,y)
    # @param [Array<Fixnum>] max_pt (x,y)
    # @param [Array<Fixnum>] rect (x1,y1, x2,y2)
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633544(v=vs.85).aspx SetWindowPlacement
    def set_placement(handle, flags, show_cmd, min_pt, max_pt, rect)
    end

    # Lock window update.
    # @param [Fixnum, nil] handle Handle to a valid window to be locked.
    #   If this parameter is +nil+, current locked window is unlocked.
    # @return [Boolean] success
    # @note This method is usually called before and after setting window
    #   styles, followed by {set_pos} to update setting.
    # @example Removing caption from an active window.
    #   handle = AMS::Window.get_active
    #   long = AMS::Window.get_long(handle, -16)
    #   AMS::Window.lock_update(handle)
    #   AMS::Window.set_long(handle, -16, long & ~0x00C00000)
    #   AMS::Window.lock_update(nil)
    #   AMS::Window.set_pos(handle, 0, 0, 0, 0, 0, 0x0277)
    # @example Adding caption to an active window.
    #   handle = AMS::Window.get_active
    #   long = AMS::Window.get_long(handle, -16)
    #   AMS::Window.lock_update(handle)
    #   AMS::Window.set_long(handle, -16, long | 0x00C00000)
    #   AMS::Window.lock_update(nil)
    #   AMS::Window.set_pos(handle, 0, 0, 0, 0, 0, 0x0277)
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/dd145034(v=vs.85).aspx LockWindowUpdate
    def lock_update(handle)
    end

    # Set window position.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] handle_insert_after
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @param [Fixnum] cx
    # @param [Fixnum] cy
    # @param [Fixnum] flags
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633545(v=vs.85).aspx SetWindowPos
    def set_pos(handle, handle_insert_after, x, y, cx, cy, flags)
    end

    # Move window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @param [Fixnum] width
    # @param [Fixnum] height
    # @param [Boolean] b_repaint Whether to repaint the window.
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633534(v=vs.85).aspx MoveWindow
    def move(handle, x, y, width, height, b_repaint = true)
    end

    # Refresh window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean] success
    def refresh(handle)
    end

    # Close window.
    # @note This function behaves the same way as clicking the 'X' button.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean] success
    def close(handle)
    end

    # Get coordinates of the upper-left corner of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Array<Fixnum>] [x,y]
    def get_origin(handle)
    end

    # Set coordinates of the upper-left corner of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @param [Boolean] b_activate Whether to activate the window.
    # @return [Boolean] success
    def set_origin(handle, x, y, b_activate = true)
    end

    # Get size of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Array<Fixnum>] [width, height]
    def get_size(handle)
    end

    # Set size of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] w Window width in pixels.
    # @param [Fixnum] h Window height in pixels.
    # @param [Boolean] b_activate Whether to activate the window.
    # @return [Boolean] success
    def set_size(handle, w, h, b_activate = true)
    end

    # Determine whether window is resizeable.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    def is_resizeable?(handle)
    end

    # Set window resizeable.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Boolean] b_state
    # @param [Boolean] b_activate Whether to activate the window.
    # @return [Boolean] success
    def set_resizeable(handle, b_state, b_activate = true)
    end

    # Enable/Disable keyboard and mouse input to a specific window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Boolean] b_state
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms646291(v=vs.85).aspx EnableWindow
    def enable_input(handle, b_state)
    end

    # Determine whether keyboard and mouse input is enabled in a specific
    # window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms646303(v=vs.85).aspx IsWindowEnabled
    def is_input_enabled?(handle)
    end

    # Send message to a specific window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum, Bignum] message
    # @param [Fixnum, Bignum] wParam
    # @param [Fixnum, Bignum] lParam
    # @return [Fixnum] Message processing result.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms644950(v=vs.85).aspx SendMessage
    def send_message(handle, message, wParam, lParam)
    end

    # Post message to a specific window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum, Bignum] message
    # @param [Fixnum, Bignum] wParam
    # @param [Fixnum, Bignum] lParam
    # @return [Boolean] success
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms644944(v=vs.85).aspx PostMessage
    # @since 3.0.0
    def post_message(handle, message, wParam, lParam)
    end

    # Peek message of a specific window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum, Bignum] msg_filter_min
    # @param [Fixnum, Bignum] msg_filter_max
    # @param [Fixnum, Bignum] remove_flag
    # @return [Array, nil] An array containing peeked message data or +nil+ if
    #   no messages are available.
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms644943(v=vs.85).aspx PeekMessage
    # @since 3.5.0
    def peek_message(handle, msg_filter_min, msg_filter_max, remove_flag)
    end

    # Peek message of a specific window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum, Bignum] msg_filter_min
    # @param [Fixnum, Bignum] msg_filter_max
    # @param [Fixnum, Bignum] remove_flag
    # @return [Boolean] True if a message is available; false if not.
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/ms644943(v=vs.85).aspx PeekMessage
    # @since 3.5.0
    def peek_message2(handle, msg_filter_min, msg_filter_max, remove_flag)
    end

    # Modify window icon.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [String] full_path Icon location.
    # @return [Boolean] success
    def set_icon(handle, full_path)
    end

    # Update menu bar of a specific window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647633(v=vs.85).aspx DrawMenuBar
    def draw_menu_bar(handle)
    end

    # Get layered attributes of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Array<(Array<Fixnum>, Fixnum, Fixnum)>] An array of three values:
    #   +[rgb_color, opacity, flags]+
    # @since 3.0.0
    def get_layered_attributes(handle)
    end

    # Set layered attributes of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum, Bignum, Array<Fixnum>] color A number or an array
    #   representing color in RGB form. Note: An array is not acceptible in
    #   library versions prior to 3.0.0.
    # @param [Fixnum] opacity A value between 0 (transparent) and 255 (opaque).
    # @param [Fixnum] flags
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633540(v=vs.85).aspx SetLayeredWindowAttributes
    def set_layered_attributes(handle, color, opacity, flags)
    end

    # Get all windows.
    # @param [Boolean] include_hidden Whether to include hidden windows.
    # @return [Array<Fixnum>] An array of window handles.
    # @since 3.0.0
    def get_windows(include_hidden = true)
    end

    # Get all windows belonging to a process.
    # @param [Fixnum] process_id
    # @param [Boolean] include_hidden Whether to include hidden windows.
    # @return [Array<Fixnum>] An array of window handles.
    # @since 3.0.0
    def get_process_windows(process_id, include_hidden = true)
    end

    # Get all windows belonging to a thread.
    # @param [Fixnum] thread_id
    # @param [Boolean] include_hidden Whether to include hidden windows.
    # @return [Array<Fixnum>] An array of window handles.
    # @since 3.0.0
    def get_thread_windows(thread_id, include_hidden = true)
    end

    # Get all child windows belonging to a parent window.
    # @param [Fixnum] parent_handle Handle to a valid parent window.
    # @param [Boolean] include_sub_childs Whether to include child window
    #   descendants.
    # @param [Boolean] include_hidden Whether to include hidden windows.
    # @return [Array<Fixnum>] An array of window handles.
    # @since 3.0.0
    def get_child_windows(parent_handle, include_sub_childs = false, include_hidden = true)
    end

    # Find handle to a window with a specific caption.
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

    # Convert client coordinates to screen coordinates.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @return [Array<Fixnum>] Converted point: +[x,y]+
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/dd183434(v=vs.85).aspx ClientToScreen
    # @since 3.0.0
    def client_to_screen(handle, x, y)
    end

    # Convert screen coordinates to client coordinates.
    # @param [Fixnum] handle Handle to a valid window.
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @return [Array<Fixnum>] Converted point: +[x,y]+
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/dd162952(v=vs.85).aspx ScreenToClient
    # @since 3.0.0
    def screen_to_client(handle, x, y)
    end

    # Convert (map) a point from a coordinate space relative to one
    # window to a coordinate space relative to another window.
    # @param [Fixnum] handle_from Handle to a valid window from which point is
    #   converted.
    # @param [Fixnum] handle_to Handle to a valid window to which point is
    #   converted.
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @return [Array<Fixnum>] Converted point: +[x,y]+
    # @see https://msdn.microsoft.com/en-us/library/windows/desktop/dd145046(v=vs.85).aspx MapWindowPoints
    # @since 3.0.0
    def map_point(handle_from, handle_to, x, y)
    end

    # Get module instance handle of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [Fixnum, nil]
    # @since 3.1.0
    def get_module_hanlde(handle)
    end

    # Get full executable path of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [String, nil]
    # @since 3.1.0
    def get_executable_path(handle)
    end

    # Get executable name of a window.
    # @param [Fixnum] handle Handle to a valid window.
    # @return [String, nil]
    # @since 3.1.0
    def get_executable_name(handle)
    end

  end # class << self
end # AMS::Window
