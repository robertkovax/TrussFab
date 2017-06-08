# The Menu namespace contains functions associated with Windows menu.
# @since 2.0.0
# @note Windows only!
module AMS::Menu
  class << self

    # Determine whether handle is a reference to a valid menu.
    # @param [Fixnum] handle A menu handle to be tested.
    # @return [Boolean]
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647989(v=vs.85).aspx IsMenu
    def is_valid?(handle)
    end

    # Deactivate active context menu.
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647637(v=vs.85).aspx EndMenu
    def end
    end

    # Get menu item count.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @return [Fixnum] count
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647978(v=vs.85).aspx GetMenuItemCount
    def get_item_count(handle)
    end

    # Get menu item id by item position.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @param [Fixnum] index
    # @return [Fixnum] Menu item identifier if successful or +-1+ if not.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647979(v=vs.85).aspx GetMenuItemID
    def get_item_id(handle, index)
    end

    # Get menu sub-menu handle by sub-menu position.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @param [Fixnum] index
    # @return [Fixnum, nil] A handle to sub-menu if successful or +nil+ if not.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647984(v=vs.85).aspx GetSubMenu
    def get_sub_menu(handle, index)
    end

    # Get menu item string by item position.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @param [Fixnum] index
    # @return [String, nil] Menu item string if successful or +nil+ if not.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647980(v=vs.85).aspx GetMenuItemInfo
    # @since 3.0.0
    def get_item_string_by_pos(handle, index)
    end

    # Get menu item string by item identifier.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @param [Fixnum] id
    # @return [String, nil] Menu item string if successful or +nil+ if not.
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms647980(v=vs.85).aspx GetMenuItemInfo
    # @since 3.0.0
    def get_item_string_by_id(handle, id)
    end

    # Set menu item string by item position.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @param [Fixnum] index
    # @param [String] string
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms648001(v=vs.85).aspx SetMenuItemInfo
    # @since 3.0.0
    def set_item_string_by_pos(handle, index, string)
    end

    # Set menu item string by item identifier.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @param [Fixnum] id
    # @param [String] string
    # @return [Boolean] success
    # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms648001(v=vs.85).aspx SetMenuItemInfo
    # @since 3.0.0
    def set_item_string_by_id(handle, id, string)
    end

    # Get menu commands.
    # @param [Fixnum] handle A handle to a valid menu or sub-menu.
    # @param [String] cur_path Current menu path.
    # @return [Hash<String, Fixnum>] { path => id, ... }
    def get_commands(handle, cur_path = "")
    end

  end # class << self
end # module AMS::Menu
