# The Cursor namespace contains functions that are subjected to Windows cursor.
# @since 2.0.0
# @note Windows only!
module AMS::Cursor
  class << self

    # Show/Hide cursor.
    # @param [Boolean] state
    # @return [Boolean] Whether cursor visibility state was changed.
    def show(state)
    end

    # Determine whether cursor is visible.
    # @return [Boolean]
    def is_visible?
    end

    # Get cursor position.
    # @param [Fixnum] mode
    #   1. Retrieve coordinates relative to screen origin.
    #   2. Retrieve coordinates relative to the viewport origin.
    # @return [Array<Fixnum>] +[x,y]+
    def get_pos(mode = 1)
    end

    # Set cursor position.
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @param [Fixnum] mode
    #   1. Given coordinates are relative to screen origin.
    #   2. Given coordinates are relative to the viewport origin.
    # @return [Boolean] success
    def set_pos(x, y, mode = 1)
    end

    # Get upper-left and lower-right coordinates of the cursor clip rectangle.
    # @param [Fixnum] mode
    #   1. Retrieve coordinates relative to screen origin.
    #   2. Retrieve coordinates relative to the viewport origin.
    # @return [Array<Fixnum>] +[x1,y1, x2,y2]+
    def get_clip_rect(mode = 1)
    end

    # Set upper-left and lower-right coordinates of the cursor clip rectangle.
    # @param [Fixnum] x1 X coordinate of the upper-left corner of the rect.
    # @param [Fixnum] y1 Y coordinate of the upper-left corner of the rect.
    # @param [Fixnum] x2 X coordinate of the lower-right corner of the rect.
    # @param [Fixnum] y2 Y coordinate of the lower-right corner of the rect.
    # @param [Fixnum] mode
    #   1. Given coordinates are relative to screen origin.
    #   2. Given coordinates are relative to the viewport origin.
    # @return [Boolean] success
    def set_clip_rect(x1, y1, x2, y2, mode = 1)
    end

    # Clip cursor to main window.
    # @return [Boolean] success
    def clip_to_main_window
    end

    # Clip cursor to view window.
    # @return [Boolean] success
    def clip_to_viewport
    end

    # Unclip cursor.
    # @return [Boolean] success
    def clear_clip
    end

    # Determine whether cursor is pointing at the main window.
    # @return [Boolean]
    def is_main_window_target?
    end

    # Determine whether cursor is within the view client area.
    # @return [Boolean]
    def is_viewport_target?
    end

  end # class << self
end # module AMS::Cursor
