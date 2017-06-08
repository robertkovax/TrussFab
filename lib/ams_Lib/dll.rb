# The DLL namespace contains functions that are associated with Windows DLL.
# @since 3.0.0
# @note Windows only!
module AMS::DLL
  class << self

    # Load DLL.
    # @param [String] full_path
    # @return [Fixnum, nil] A handle to the loaded library or nil if not
    #  successful.
    def load_library(full_path)
    end

    # Free loaded DLL.
    # @param [Fixnum] handle A handle to the loaded library.
    # @return [Boolean] success
    def free_library(handle)
    end

  end # class << self
end # module AMS::DLL
