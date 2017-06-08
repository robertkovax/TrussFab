# The Screen namespace contains functions that are associated with Windows
# screen.
# @since 2.0.0
# @note Windows only!
module AMS::Screen
  class << self

    # Get screen resolution of the primary monitor.
    # @return [Array<Fixnum>] +[width, height]+ in pixels.
    def resolution
    end

    # Get screen resolution of all monitors combined.
    # @return [Array<Fixnum>] +[width, height]+ in pixels.
    def virtual_resolution
    end

  end # class << self
end # module AMS::Screen
