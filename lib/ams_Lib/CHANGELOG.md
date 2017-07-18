## 3.5.1 - July 17, 2017
- Compatibility with SU versions prior to 2013.

## 3.5.0 - July 9, 2017
- Migrated <tt>AMS</tt>, <tt>AMS::Group</tt>, <tt>AMS::Geometry</tt>, and <tt>AMS::MultiLineText</tt> to C++ extension, which includes optimizations and various fixes.
- Removed <tt>AMS::System</tt> platform detection functions: <tt>is_windows?</tt>, <tt>is_mac?</tt>, and <tt>is_linux?</tt>; use constants instead.
- Removed <tt>AMS::Sketchup.is_32bit?</tt> and <tt>AMS::Sketchup.is_64bit?</tt>.
- Added <tt>AMS::IS_SKETCHUP_32BIT</tt> and <tt>AMS::IS_SKETCHUP_64BIT</tt>.
- Added <tt>AMS::IS_RUBY_VERSION_18</tt>, <tt>AMS::IS_RUBY_VERSION_20</tt>, and <tt>AMS::IS_RUBY_VERSION_22</tt>.
- Revised <tt>AMS::RayUtil</tt> functions and moved them to <tt>AMS::Geometry</tt>.
- Moved <tt>AMS.scale_vector</tt> to <tt>AMS::Geometry</tt>.
- Added <tt>AMS::Geometry.calc_cubic_bezier_point(ratio, p0, p1, p2, p3)</tt>.
- Added <tt>AMS::Geometry.calc_cubic_bezier_slope(ratio, p0, p1, p2, p3)</tt>.
- Added <tt>AMS::Geometry.scale_point(point, scale)</tt>.
- Removed <tt>AMS::Geometry.rotate_matrix1_to_matrix2</tt>.
- Added <tt>AMS::Geometry.rotate_matrix_xaxis_to_dir(transformation, dir)</tt>.
- Added <tt>AMS::Geometry.rotate_matrix_yaxis_to_dir(transformation, dir)</tt>.
- Added <tt>AMS::Geometry.rotate_matrix_zaxis_to_dir(transformation, dir)</tt>.
- Added <tt>AMS::Geometry.rotate_vector(vector, normal, angle)</tt>.
- Added <tt>AMS::Geometry.angle_between_vectors(v1, v2, normal)</tt>.
- Reworked <tt>AMS::Geometry.transition_transformation(t1, t2, ratio)</tt> to consider scaled matrices.
- Rearranged parameters for <tt>AMS::Geometry.blend_colors</tt> and <tt>AMS::Geometry.get_points_on_circle3d</tt>.
- <tt>AMS::Geometry.get_points_on_circle2d</tt> and <tt>AMS::Geometry.get_points_on_circle3d</tt> now accept rot_angle in radians.
- Revised most <tt>AMS::Group</tt> functions.
- Replaced <tt>AMS::MultiLineText.#entity</tt> with <tt>AMS::MultiLineText.#get_entity</tt>.
- Added <tt>AMS::MultiLineText.#set_entity(entity)</tt>.
- Added <tt>AMS::MultiLineText.#get_position</tt>.
- Added <tt>AMS::MultiLineText.#set_position(x,y)</tt>.
- Added <tt>AMS::Window.peek_message(handle, msg_filter_min, msg_filter_max, remove_flag)</tt>.
- Added <tt>AMS::Window.peek_message2(handle, msg_filter_min, msg_filter_max, remove_flag)</tt>.
- Added <tt>AMS::Keyboard.get_key_name(vk_code)</tt>.
- Added <tt>AMS::Group.get_bounding_box_from_edges(object, recursive = true, transformation = nil, &entity_validation)</tt>.
- Added <tt>AMS::Sketchup.show_trays(state)</tt>.
- Added <tt>AMS::Sketchup.close_trays</tt>.
- Added <tt>AMS::Sketchup.activate_scenes_bar_tab(tab_index)</tt>.
- Added <tt>AMS::Sketchup.threaded_messagebox(caption, text, type, owner_handle)</tt>.
- Added <tt>AMS::SketchupObserver.#swp_on_page_selected(page1, page2, tab_index1, tab_index2)</tt>.
- Added two additional parameters to <tt>AMS::SketchupObserver.#swo_on_page_selected</tt>.
- Removed <tt>AMS::Win32::API</tt> as it hasn't been used since version 2.
- Removed <tt>AMS::Lib.clean_up</tt>.
- Added <tt>AMS::ExtensionManager</tt> to prevent overwrite issues that occur when updating loaded extensions. Thanks to ThomThom for the original version.

## 3.4.1 - December 17, 2016
- Added signature.

## 3.4.0 - October 31, 2016
- Made most keyboard and midi functions compatible with Mac OS X.
- Added <tt>AMS::MIDI.is_device_open?</tt>
- Added <tt>AMS::MIDI.out_message(*args)</tt>

## 3.3.0 - July 10, 2016
- Added more MIDI functions.
- Added <tt>Group</tt> and <tt>Geometry</tt> modules.
- Added <tt>AMS.round(value, precision)</tt>
- Started making compatible with Mac OS X.

## 3.2.5 - May 22, 2016
- Improved performance with observers.

## 3.2.4 - May 21, 2016
- More compatibility with different encodings.

## 3.2.3 - May 19, 2016
- Made compatible with different encodings.

## 3.2.2 - April 05, 2016
- Fixed crash when toggling menu bar on different localization. Thanks to herojack and perroloco2000 for report.

## 3.2.1 - March 30, 2016
- Fixed small bug in AMS::Window.set_pos.
- Recompiled with optimized settings.
- Fixed the frozen path load error on particular machines.

## 3.2.0 - February 28, 2016
- Added <tt>AMS::SketchupObserver.#swo_on_page_selected(page1, page2)</tt>

## 3.1.4 - February 06, 2016
- Made SU full screen function associate to the desired monitor(s). Thanks to DimaV83 for request.

## 3.1.3 - December 30, 2015
- Fixed a bug that caused a crash when remove AMS observer from within an observer method.

## 3.1.2 - December 04, 2015
- Made it compatible with Windows XP. Thanks for Junar Amaro for report.
- Fixed a bug that prevented menu bar from working properly on Windows XP.
- Fixed a bug where starting SU8, with dialogs open, the library failed to identify the main window.

## 3.1.1 - November 29, 2015
- Fixed a bug that caused increase in CPU usage and lead to a crash. Thanks to Pherim for report.

## 3.1.0 - November 26, 2015
- Added <tt>AMS::Sketchup.send_user_message(receiver_handle, id, data)</tt>
- Added <tt>AMS::SketchupObserver.#swo_on_user_message(sender_handle, id, data)</tt>
- Added <tt>AMS::Sketchup.get_other_main_windows</tt>
- Added <tt>AMS::Sketchup.get_executable_name</tt>
- Added <tt>AMS::Window.get_moudle_handle(handle)</tt>
- Added <tt>AMS::Window.get_executable_path(handle)</tt>
- Added <tt>AMS::Window.get_executable_name(handle)</tt>
- <tt>AMS::SketchupObserver.#swp_on_command(id)</tt> no longer triggers on 24214 command. The 24214 command occurs very often and is called when the view is invalidated, rather than when the tool is activated.
- Added <tt>AMS.inspect_element(item)</tt>

## 3.0.1 - September 20, 2015
- Fixed some security issues.

## 3.0.0 - September 16, 2015
- Fully rewritten library with optimizations, bug fixes, and improvements.
- All code that deals with Windows API is now a C++ extension.
- Unicode strings are now handled properly.
- Removed Ruby-FFI library as it's no longer necessary.
- Changed MIDI behaviour and renamed some of its functions:
    - <tt>AMS::MIDI.play_note</tt> no longer has the 'duration' parameter, and it returns a sound id rather than boolean.
    - <tt>AMS::MIDI.stop_note</tt> now asks for a sound id.
    - Replaced <tt>AMS::MIDI.channel_sustain_pedal</tt> with <tt>AMS::MIDI.sustain_channel_pedal</tt>.
    - Removed <tt>AMS::MIDI.play_3d_note</tt> and <tt>AMS::MIDI.set_3d_note_position</tt>.
    - Added <tt>AMS::MIDI.set_note_position(id, position, max_hearing_range)</tt>
    - Added <tt>AMS::MIDI.get_device_handle()</tt>
- Replaced <tt>AMS::Keyboard.get_key_value</tt> with <tt>AMS::Keyboard.get_key_code</tt>.
- Added <tt>AMS::Keyboard.get_virtual_key_codes</tt>
- Added <tt>AMS::Keyboard.get_virtual_key_codes2</tt>
- Added <tt>AMS::Keyboard.get_virtual_key_names</tt>
- Added <tt>AMS::Sketchup.include_toolbar(handle)</tt>
- Added <tt>AMS::Sketchup.ignore_toolbar(handle)</tt>
- Added additional parameters to <tt>AMS::Sketchup.find_window_by_caption(caption, full_match = true, case_sensitive = true)</tt>
- Added <tt>AMS::Sketchup.find_child_window_by_caption(parent_handle, caption, include_sub_childs = false, full_match = true, case_sensitive = true)</tt>
- Added <tt>AMS::Sketchup.find_window_by_class_name(class_name, full_match = true, case_sensitive = true)</tt>
- Added <tt>AMS::Sketchup.find_child_window_by_class_name(parent_handle, class_name, include_sub_childs = false, full_match = true, case_sensitive = true)</tt>
- <tt>AMS::Sketchup.refresh</tt> and <tt>AMS::Sketchup.close</tt> now return boolean rather than void.
- Removed <tt>AMS::Menu.validate</tt>
- Replaced <tt>AMS::Menu.get_menu_item_string_by_pos</tt> with <tt>AMS::Menu.get_item_string_by_pos</tt>.
- Replaced <tt>AMS::Menu.get_menu_item_string_by_id</tt> with <tt>AMS::Menu.get_item_string_by_id</tt>.
- Replaced <tt>AMS::Menu.set_menu_item_string_by_pos</tt> with <tt>AMS::Menu.set_item_string_by_pos</tt>.
- Replaced <tt>AMS::Menu.set_menu_item_string_by_id</tt> with <tt>AMS::Menu.set_item_string_by_id</tt>.
- Fixed a bug where <tt>AMS::Menu.get_item_id failed</tt> to return -1 if given index represented a submenu.
- Removed <tt>AMS::Window.validate</tt>
- <tt>AMS::Window.show(handle, state)</tt> now returns boolean rather than integer.
- <tt>AMS::Window.is_child?(parent_handle, handle)</tt> was changed to <tt>AMS::Window.is_child?(handle, parent_handle)</tt>
- Replaced <tt>AMS::Window.bring_window_to_top</tt> with <tt>AMS::Window.bring_to_top</tt>
- Replaced <tt>AMS::Window.get_text</tt> with <tt>AMS::Window.get_caption</tt>
- Replaced <tt>AMS::Window.set_text</tt> with <tt>AMS::Window.set_caption</tt>
- <tt>AMS::Window.send_message</tt> now returns message processing result rather than nil.
- Added <tt>AMS::Window.post_message(handle, message, wParam, lParam)</tt>
- Added <tt>AMS::Window.get_layered_attributes(handle)</tt>
- <tt>AMS::Window.set_layered_attributes(handle, color, opacity, flags)</tt> now accepts an array of RGB values for the color parameter.
- Added <tt>AMS::Window.get_windows(include_hidden = true)</tt>
- Added <tt>AMS::Window.get_process_windows(process_id, include_hidden = true)</tt>
- Added <tt>AMS::Window.get_thread_windows(thread_id, include_hidden = true)</tt>
- Added <tt>AMS::Window.get_child_windows(parent_handle, include_sub_childs = false, include_hidden = true)</tt>
- Added <tt>AMS::Window.find_window_by_caption(caption, full_match = true, case_sensitive = true)</tt>
- Added <tt>AMS::Window.find_child_window_by_caption(parent_handle, caption, include_sub_childs = false, full_match = true, case_sensitive = true)</tt>
- Added <tt>AMS::Window.find_window_by_class_name(class_name, full_match = true, case_sensitive = true)</tt>
- Added <tt>AMS::Window.find_child_window_by_class_name(parent_handle, class_name, include_sub_childs = false, full_match = true, case_sensitive = true)</tt>
- Added <tt>AMS::Window.is_unicode?(handle)</tt>
- Added <tt>AMS::Window.get_related(handle, command)</tt>
- Added <tt>AMS::Window.get_ancestor(handle, flag)</tt>
- Added <tt>AMS::Window.client_to_screen(handle, x, y)</tt>
- Added <tt>AMS::Window.screen_to_client(handle, x, y)</tt>
- Added <tt>AMS::Window.map_point(handle_from, handle_to, x, y)</tt>
- Added <tt>AMS::DLL.load_libarary(path)</tt>
- Added <tt>AMS::DLL.free_libarary(handle)</tt>
- NULL window/menu handles now return nil rather than zero.
- Fixed a bug where activating/deactivating particular observer triggered <tt>swo_activate</tt>/<tt>swo_deactivate</tt> in all active observers rather than in particular observer being activated or deactivated.
- Fixed a bug where <tt>swo_on_toolbar_container_filled</tt>/<tt>swo_on_toolbar_container_emptied</tt> was unintentionally called when toolbar container visibility state was changed.
- Added post events for <tt>AMS::SketchupObserver</tt>: swo_on_post_enter_menu, swo_on_post_exit_menu, swo_on_post_switch_full_screen, swo_on_post_maximize, swo_on_post_minimize, swo_on_post_restore, swo_on_post_focus, swo_on_post_blur, swo_on_post_enter_size_move, swo_on_post_size_move, swo_on_post_exit_size_move, swo_on_post_caption_changed, swo_on_post_menu_bar_changed, swo_on_post_viewport_paint, swo_on_post_viewport_size, swo_on_post_viewport_border_changed, swo_on_post_scenes_bar_visibility_changed, swo_on_post_scenes_bar_filled, swo_on_post_scenes_bar_emptied, swo_on_post_status_bar_visibility_changed, swo_on_post_toolbar_container_visibility_changed, swo_on_post_toolbar_container_filled, swo_on_post_toolbar_container_emptied.

## 2.2.0 - January 22, 2015
- Migrated from a C extension to a C++ extension.
- Added an option to hide Vray dialogs. Thanks to shake1 for request.

## 2.1.0 - December 03, 2014
- Added <tt>AMS::Lib.clean_up</tt>, which removes all unregistered Ruby files from the library.
- Added <tt>AMS::System.get_metrics(index)</tt>
- Minor bug fixes.

## 2.0.0 - November 20, 2014
- Improved functionality.
- Added support for SU 64 bit.
- Reorganized various functions and rewrote documentation.
- Migrated from relying on win32-api gem to using a C extension.
- Implemented Windows MIDI.
- Made FFI Compatible with Ruby 1.8.6. It's not compatible with Ruby 1.8.0 though.

## 1.0.9 - April 26, 2014
- Added get_keys and get_values to the registry.
- Improved MultiLineText.

## 1.0.8 - February 12, 2014
- Stabilized registry readers and writers.
- Stabilized custom shortcuts on localized SU versions.

## 1.0.7 - February 04, 2014
- Added custom timers.
- Optimized show/hide dialogs function.
- Added <tt>swo_tbc_onFilled(bar)</tt> and <tt>swo_tbc_onEmptied(bar)</tt> observers, which are called when a certain toolbar container is emptied or filled with toolbars.
- Added <tt>swo_mw_onCommand(id)</tt>, which responds to <tt>Sketchup.send_action</tt> events.

## 1.0.6 - January 29, 2014
- Figured out a way to keep all menu shortcuts working when the menu bar is removed. Yes!!!
- Added registry accessors.
- Added <tt>swo_mw_onEnterMenu</tt> and <tt>swo_mw_onExitMenu</tt> observers.
- Added <tt>AMS::Windows::API</tt> - thanks to Daniel J. Berger.
- Fixed get screen resolution function. Originally it returned resolution of the current screen. Now, it returns resolution of all monitors combined.
- Improved observers.
- Increased callbacks limit of <tt>AMS::Win32::API</tt> to 20 callbacks.
- Simplified libraries.

## 1.0.5 - December 16, 2013
- Fixed the observers bug that made SketchUp freeze when pressing a key in the menu.

## 1.0.4 - December 15, 2013
- Improved the refresh function.

## 1.0.3 - December 15, 2013
- Some fixes and improvements.
- Added <tt>AMS::Window.invalid?</tt>
- Added <tt>AMS::Window.set_pos</tt>
- Added <tt>AMS::Window.set_size</tt>

## 1.0.2 - December 06, 2013
- Some fixes and improvements.
- Increased observers reaction speed.

## 1.0.1 - November 22, 2013
- Improved set full screen, maximize, minimize, and restore functions.

## 1.0.0 - November 17, 2013
- Initial release.
