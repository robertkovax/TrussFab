# SketchUpObserver allows you to monitor and make decisions to SketchUp window
# events.
# @abstract
# @note SWO events are capable of monitoring window events. SWP events are
#   capable of monitoring a making decisions to window events. Returning 1 for
#   a SWP event will prevent the event from interacting with SketchUp window
#   procedure; any other return value won't block the event. If more than one
#   observers install SWP events and one of them returns 1, the event will
#   be blocked, regardless of whether other observers wanted the event to be
#   processed by SketchUp window procedure.
# @note An observer can be a class, module, or a class instance. Your
#   observer will work as long as the callback methods are public.
# @note Your observer is not supposed to contain every callback method from
#   the observers list. You may include/elude those as you wish.
# @example Processing keyboard events:
#   class MySketchupObserver
#
#     def swp_on_key_down(vk_name, vk_value, vk_char)
#       puts "on_key_down: #{vk_name}"
#       # ...
#       # Returning 1 will prevent current pressed key from interacting with SU
#       # window procedure.
#       # Here, we'll return 1 to W,S,A,D keys, so we could use them for our own
#       # purpose, rather than having shortcuts changing the tool.
#       return %(w s a d).include?(vk_name) ? 1 : 0
#     end
#
#     def swp_on_key_extended(vk_name, vk_value, vk_char)
#       puts "on_key_extended: #{vk_name}"
#       # ...
#       # If you return 1 for the on_key_down event, it's also preferred to
#       # return 1 for the on_key_extended event, so the key doesn't stand a
#       # chance to interact with SketchUp window procedure.
#       return %(w s a d).include?(vk_name) ? 1 : 0
#     end
#
#     def swp_on_key_up(vk_name, vk_value, vk_char)
#       puts "on_key_up: #{vk_name}"
#       # ...
#       # If you return 1 for the on_key_down event, it's also preferred to
#       # return 1 for the on_key_up event, so the key doesn't stand a chance to
#       # interact with SketchUp window procedure.
#       return %(w s a d).include?(vk_name) ? 1 : 0
#     end
#
#   end # class MySketchupObserver
#
#   AMS::Sketchup.add_observer(MySketchupObserver.new)
# @see AMS::Sketchup.add_observer
# @since 2.0.0
# @note Windows only!
class AMS::SketchupObserver

  # @!group Observer Events

  # Called whenever this observer is added.
  def swo_activate
  end

  # Called whenever this observer is removed.
  def swo_deactivate
  end

  # Triggered whenever there is an error in any observer events, except this
  # one.
  # @note An error will not force the observer to deactivate. If you want the
  #   observer to deactivate on error, then this is the event to be implemented.
  # @note If this event is not implemented, by default, the error will be
  #   outputted in console.
  # @note If there is an error in this event, the error message will be
  #   outputted in console.
  # @param [Exception] e
  # @example Deactivating an observer when an error occurs.
  #   class MyMouseWheelObserver
  #
  #     def swp_on_mouse_wheel_rotate(x, y, dir)
  #       puts "Mouse wheel rotated #{dir == 1 ? 'up' : 'down'}!"
  #       # 'yo' is undefined. Make this error on purpose.
  #       yo
  #     end
  #
  #     def swo_error(e)
  #       puts e.message
  #       # Deactivate our observer
  #       AMS::Sketchup.remove_observer(self)
  #     end
  #
  #   end # class MyMouseWheelObserver
  #
  #   AMS::Sketchup.add_observer(MyMouseWheelObserver.new)
  #   # In this example, after adding an observer and rotating a mouse wheel,
  #   # which would trigger the swp_on_mouse_wheel_rotate event, the undefined
  #   # 'yo', which is in the swp_on_mouse_wheel_rotate event, will throw an
  #   # exception, which would be caught by the swo_error event. The swo_error
  #   # event will output the error message into console and unregister the
  #   # current observer.
  def swo_error(e)
  end

  # @!endgroup
  # @!group Mouse Input Events

  # Called when left mouse button is clicked.
  # @param [Fixnum] x X cursor position relative to the upper-left corner of the
  #   viewport client area.
  # @param [Fixnum] y Y cursor position relative to the upper-left corner of the
  #   viewport client area.
  # @return [Fixnum] A return value of 1 will prevent this event from
  #   interacting with SketchUp window procedure. Any other return value will
  #   allow this event to interact with SketchUp window procedure.
  def swp_on_lbutton_down(x,y)
  end

  # Called when left mouse button is released.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_lbutton_up(x,y)
  end

  # Called when left mouse button is double clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_lbutton_double_click(x,y)
  end

  # Called when right mouse button is clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_rbutton_down(x,y)
  end

  # Called when right mouse button is released.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_rbutton_up(x,y)
  end

  # Called when right mouse button is double clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_mbutton_double_click(x,y)
  end

  # Called when middle mouse button is clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_mbutton_down(x,y)
  end

  # Called when middle mouse button is released.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_mbutton_up(x,y)
  end

  # Called when middle mouse button is double clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_mbutton_double_click(x,y)
  end

  # Called when X mouse button 1 is clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_xbutton1_down(x,y)
  end

  # Called when X mouse button 1 is released.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_xbutton1_up(x,y)
  end

  # Called when X mouse button 1 is double clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_xbutton1_double_click(x,y)
  end

  # Called when X mouse button 2 is clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_xbutton2_down(x,y)
  end

  # Called when X mouse button 2 is released.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_xbutton2_up(x,y)
  end

  # Called when X mouse button 2 is double clicked.
  # @param (see #swp_on_lbutton_down)
  # @return (see #swp_on_lbutton_down)
  def swp_on_xbutton2_double_click(x,y)
  end

  # Called when mouse wheel is rotated.
  # @param [Fixnum] x X cursor position relative to the upper-left corner of the
  #   viewport client area.
  # @param [Fixnum] y Y cursor position relative to the upper-left corner of the
  #   viewport client area.
  # @param [Fixnum] dir A positive value (1) indicates that the wheel was
  #   rotated forward, away from the user; a negative value (-1) indicates that
  #   the wheel was rotated backward, toward the user.
  # @return (see #swp_on_lbutton_down)
  def swp_on_mouse_wheel_rotate(x,y, dir)
  end

  # Called when mouse wheel is tilted.
  # @param [Fixnum] x X cursor position relative to the upper-left corner of the
  #   viewport client area.
  # @param [Fixnum] y Y cursor position relative to the upper-left corner of the
  #   viewport client area.
  # @param [Fixnum] dir A positive value (1) indicates that the wheel was tilted
  #   right; a negative value (-1) indicates that the wheel was tilted left.
  # @return (see #swp_on_lbutton_down)
  def swp_on_mouse_wheel_tilt(x,y, dir)
  end

  # Called when cursor enters the viewport client area.
  # @param (see #swp_on_lbutton_down)
  def swo_on_mouse_enter(x,y)
  end

  # Called when cursor leaves the viewport client area.
  # @param (see #swp_on_lbutton_down)
  def swo_on_mouse_leave(x,y)
  end

  # Called when cursor is moved within the viewport client area.
  # @param (see #swp_on_lbutton_down)
  def swo_on_mouse_move(x,y)
  end

  # @!endgroup
  # @!group Keybaord Input Events

  # Called when key is pressed.
  # @param [String] vk_name Virtual key name
  # @param [Fixnum] vk_value Virtual key constant value
  # @param [String] vk_char Actual key character
  # @return [Fixnum] A return value of 1 will prevent the key from interacting
  #   with SketchUp window procedure; any other return value will not block the
  #   key.
  def swp_on_key_down(vk_name, vk_value, vk_char)
  end

  # Called when key is held down.
  # @param [String] vk_name Virtual key name
  # @param [Fixnum] vk_value Virtual key constant value
  # @param [String] vk_char Actual key character
  # @return [Fixnum] A return value of 1 will prevent the key from interacting
  #   with SketchUp window procedure; any other return value will not block the
  #   key.
  def swp_on_key_extended(vk_name, vk_value, vk_char)
  end

  # Called when key is released.
  # @param [String] vk_name Virtual key name
  # @param [Fixnum] vk_value Virtual key constant value
  # @param [String] vk_char Actual key character
  # @return [Fixnum] A return value of 1 will prevent the key from interacting
  #   with SketchUp window procedure; any other return value will not block the
  #   key.
  def swp_on_key_up(vk_name, vk_value, vk_char)
  end

  # @!endgroup
  # @!group SketchUp Window Events

  # Called when SketchUp window procedure comes across the WM_COMMAND message.
  # This event responds to +Sketchup.send_action+, as it too, generates
  # WM_COMMAND messages. This event is usually called when a tool is activated.
  # @param [Fixnum] id Command identifier
  # @return [Fixnum] A return value of 1 will prevent the command from reaching
  #   SketchUp window procedure; any other return value won't block the command.
  # @note Since version 3.1.0, this event no longer triggers on 24214 command.
  def swp_on_command(id)
  end

  # Called right before SketchUp window is destroyed.
  def swo_on_quit
  end

  # Called when application enters the menu loop.
  def swo_on_enter_menu
  end

  # Called when application exits the menu loop.
  def swo_on_exit_menu
  end

  # Called when main window is switched to/from full screen mode.
  # @param [Boolean] state A true value indicates the window is set full
  #   screen; a false value indicated the window is unset from full screen mode.
  def swo_on_switch_full_screen(state)
  end

  # Called when main window is maximized.
  def swo_on_maximize
  end

  # Called when main window is minimized.
  def swo_on_minimize
  end

  # Called when main window is set to normal placement.
  def swo_on_restore
  end

  # Called when main window is activated.
  def swo_on_focus
  end

  # Called when main window is deactivated.
  def swo_on_blur
  end

  # Called when main window enters the state of being sized and/or moved.
  # @param [Fixnum] x X coordinate of window origin, relative to the upper-left
  #   corner of the screen.
  # @param [Fixnum] y Y coordinate of window origin, relative to the upper-left
  #   corner of the screen.
  # @param [Fixnum] w Window width in pixels.
  # @param [Fixnum] h Window height in pixels.
  def swo_on_enter_size_move(x,y, w,h)
  end

  # Called when main window is being sized and/or moved.
  # @param (see #swo_on_enter_size_move)
  def swo_on_size_move(x,y, w,h)
  end

  # Called when main window exits the state of being sized and/or moved.
  # @param (see #swo_on_enter_size_move)
  def swo_on_exit_size_move(x,y, w,h)
  end

  # Called when main window title text is changed.
  # @param [String] text New text
  def swo_on_caption_changed(text)
  end

  # Called when main window menu bar is set or removed.
  # @param [Boolean] state A true value indicates the menu bar is set; a false
  #   value indicates the menu bar is removed.
  def swo_on_menu_bar_changed(state)
  end

  # Called when the view window is redrawn.
  def swo_on_viewport_paint
  end

  # Called when the view window is sized.
  # @param [Fixnum] w View width in pixels.
  # @param [Fixnum] h View height in pixels.
  def swo_on_viewport_size(w,h)
  end

  # Called when view border, a thin edge surrounding the view, is set or
  # removed.
  # @param [Boolean] state A true value indicates the edge is set; a false value
  #   indicates the edge is removed.
  def swo_on_viewport_border_changed(state)
  end

  # Called when scenes bar is shown or hidden.
  # @param [Boolean] state A true value indicates scenes bar is set visible; a
  #   false value indicates scenes bar is set hidden.
  def swo_on_scenes_bar_visibility_changed(state)
  end

  # Called when scenes bar gets its first page.
  def swo_on_scenes_bar_filled
  end

  # Called when scenes bar loses its last page.
  def swo_on_scenes_bar_emptied
  end

  # Called when status bar is shown or hidden.
  # @param [Boolean] state A true value indicates status bar is set visible; a
  #   false value indicates status bar is set hidden.
  def swo_on_status_bar_visibility_changed(state)
  end

  # Called when toolbar container is shown or hidden.
  # @param [Fixnum] bar A container which visibility state was changed. It can
  #   be one following values:
  #   1. top bar
  #   2. bottom bar
  #   3. left bar
  #   4. right bar
  # @param [Boolean] state A true value indicates toolbar container is set
  #   visible; a false value indicates toolbar container is set hidden.
  def swo_on_toolbar_container_visibility_changed(bar, state)
  end

  # Called when toolbar container is filled.
  # @param [Fixnum] bar A container which was filled. It can be one of the
  #   following values:
  #   1. top bar
  #   2. bottom bar
  #   3. left bar
  #   4. right bar
  def swo_on_toolbar_container_filled(bar)
  end

  # Called when toolbar container is emptied.
  # @param [Fixnum] bar A container which was emptied. It can be one of the
  #   following values:
  #   1. top bar
  #   2. bottom bar
  #   3. left bar
  #   4. right bar
  def swo_on_toolbar_container_emptied(bar)
  end

  # Called when a user-sent message is received.
  # @param [Fixnum] sender_handle A handle to a SketchUp main window that sent a
  #   message.
  # @param [Fixnum] id A user-defined unique message identifier sent along with
  #   a message.
  # @param [nil, Boolean, Fixnum, Bignum, Float, String, Symbol, Hash] user_data
  #   User-defined information or data sent along with a message.
  # @since 3.1.0
  # @see AMS::Sketchup.send_user_message
  def swo_on_user_message(sender_handle, id, user_data)
  end

  # Called when a scenes page is selected.
  # @param [Sketchup::Page] page1 Originally selected page.
  # @param [Sketchup::Page] page2 New selected page.
  # @since 3.2.0
  def swo_on_page_selected(page1, page2)
  end

  # @!endgroup
  # @!group SketchUp Window Post Events

  # Called after application enters the menu loop.
  # @since 3.0.0
  def swo_on_post_enter_menu
  end

  # Called after application exits the menu loop.
  # @since 3.0.0
  def swo_on_post_exit_menu
  end

  # Called after main window is switched to/from full screen mode.
  # @param [Boolean] state A true value indicates the window is set full
  #   screen; a false value indicated the window is unset from full screen mode.
  # @since 3.0.0
  def swo_on_post_switch_full_screen(state)
  end

  # Called after main window is maximized.
  # @since 3.0.0
  def swo_on_post_maximize
  end

  # Called after main window is minimized.
  # @since 3.0.0
  def swo_on_post_minimize
  end

  # Called after main window is set to normal placement.
  # @since 3.0.0
  def swo_on_post_restore
  end

  # Called after main window is activated.
  # @since 3.0.0
  def swo_on_post_focus
  end

  # Called after main window is deactivated.
  # @since 3.0.0
  def swo_on_post_blur
  end

  # Called after main window enters the state of being sized and/or moved.
  # @param [Fixnum] x X coordinate of window origin, relative to the upper-left
  #   corner of the screen.
  # @param [Fixnum] y Y coordinate of window origin, relative to the upper-left
  #   corner of the screen.
  # @param [Fixnum] w Window width in pixels.
  # @param [Fixnum] h Window height in pixels.
  # @since 3.0.0
  def swo_on_post_enter_size_move(x,y, w,h)
  end

  # Called after main window is being sized and/or moved.
  # @param (see #swo_on_enter_size_move)
  # @since 3.0.0
  def swo_on_post_size_move(x,y, w,h)
  end

  # Called after main window exits the state of being sized and/or moved.
  # @param (see #swo_on_enter_size_move)
  # @since 3.0.0
  def swo_on_post_exit_size_move(x,y, w,h)
  end

  # Called after main window title text is changed.
  # @param [String] text New text
  # @since 3.0.0
  def swo_on_post_caption_changed(text)
  end

  # Called after main window menu bar is set or removed.
  # @param [Boolean] state A true value indicates the menu bar is set; a false
  #   value indicates the menu bar is removed.
  # @since 3.0.0
  def swo_on_post_menu_bar_changed(state)
  end

  # Called after the view window is redrawn.
  # @since 3.0.0
  def swo_on_post_viewport_paint
  end

  # Called after the view window is sized.
  # @param [Fixnum] w View width in pixels.
  # @param [Fixnum] h View height in pixels.
  # @since 3.0.0
  def swo_on_post_viewport_size(w,h)
  end

  # Called after view border, a thin edge surrounding the view, is set or
  # removed.
  # @param [Boolean] state A true value indicates the edge is set; a false value
  #   indicates the edge is removed.
  # @since 3.0.0
  def swo_on_post_viewport_border_changed(state)
  end

  # Called after scenes bar is shown or hidden.
  # @param [Boolean] state A true value indicates scenes bar is set visible; a
  #   false value indicates scenes bar is set hidden.
  # @since 3.0.0
  def swo_on_post_scenes_bar_visibility_changed(state)
  end

  # Called after scenes bar gets its first page.
  # @since 3.0.0
  def swo_on_post_scenes_bar_filled
  end

  # Called after scenes bar loses its last page.
  # @since 3.0.0
  def swo_on_post_scenes_bar_emptied
  end

  # Called after status bar is shown or hidden.
  # @param [Boolean] state A true value indicates status bar is set visible; a
  #   false value indicates status bar is set hidden.
  # @since 3.0.0
  def swo_on_post_status_bar_visibility_changed(state)
  end

  # Called after toolbar container is shown or hidden.
  # @param [Fixnum] bar A container which visibility state was changed. It can
  #   be one following values:
  #   1. top bar
  #   2. bottom bar
  #   3. left bar
  #   4. right bar
  # @param [Boolean] state A true value indicates toolbar container is set
  #   visible; a false value indicates toolbar container is set hidden.
  # @since 3.0.0
  def swo_on_post_toolbar_container_visibility_changed(bar, state)
  end

  # Called after toolbar container is filled.
  # @param [Fixnum] bar A container which was filled. It can be one of the
  #   following values:
  #   1. top bar
  #   2. bottom bar
  #   3. left bar
  #   4. right bar
  # @since 3.0.0
  def swo_on_post_toolbar_container_filled(bar)
  end

  # Called after toolbar container is emptied.
  # @param [Fixnum] bar A container which was emptied. It can be one of the
  #   following values:
  #   1. top bar
  #   2. bottom bar
  #   3. left bar
  #   4. right bar
  # @since 3.0.0
  def swo_on_post_toolbar_container_emptied(bar)
  end

  # @!endgroup

end # class AMS::SketchupObserver
