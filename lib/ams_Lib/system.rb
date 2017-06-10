# System namespace contains functions that are associated with operating system.
# @since 2.0.0
module AMS::System
  class << self

    # Determine whether operating system is Windows.
    # @return [Boolean]
    def is_windows?
      AMS::IS_PLATFORM_WINDOWS
    end

    # Determine whether operating system is Macintosh.
    # @return [Boolean]
    def is_mac?
      AMS::IS_PLATFORM_OSX
    end

    # Determine whether operating system is Linux.
    # @return [Boolean]
    def is_linux?
      AMS::IS_PLATFORM_LINUX
    end

  end # class << self
end # module AMS::System
