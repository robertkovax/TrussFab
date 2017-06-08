# The Registry namespace contains functions associated with Windows registry.
# @since 2.0.0
# @note Windows only!
module AMS::Registry
  class << self

    # Get data associated with the registry path.
    # @param [String] full_path
    # @param [Boolean] rel_to_su_reg_path Whether to acquire path relative to
    #   the registry path of the current SketchUp application or from the
    #   beginning.
    # @return [String, Fixnum, Bignum, nil] Associated data or nil if the
    #   specified path is invalid.
    # @example Read registry relative to base root:
    #   read('HKEY_CURRENT_USER/Environment/TEMP', false)
    # @example Read registry relative to SketchUp registry path:
    #   read('Application/RunCounterSU', true)
    def read(full_path, rel_to_su_reg_path = true)
    end

    alias get read

    # Set data associated with the registry path.
    # @param [String] full_path
    # @param [Object] value
    # @param [Boolean] rel_to_su_reg_path Whether to acquire path relative to
    #   the registry path of the current SketchUp application or from the
    #   beginning.
    # @return [Boolean] success
    def write(full_path, value, rel_to_su_reg_path = true)
    end

    alias set write

    # Delete registry key or value.
    # @param [String] full_path
    # @param [Boolean] rel_to_su_reg_path Whether to acquire path relative to
    #   the registry path of the current SketchUp application or from the
    #   beginning.
    # @return [Boolean] success
    def delete(full_path, rel_to_su_reg_path = true)
    end

    alias remove delete

    # Get all keys or 'folders' found in the specified registry path.
    # @param [String] full_path
    # @param [Boolean] rel_to_su_reg_path Whether to acquire path relative to
    #   the registry path of the current SketchUp application or from the
    #   beginning.
    # @return [Array<String>]
    def get_keys(full_path, rel_to_su_reg_path = true)
    end

    # Get all values or 'files' and their data found in the specified registry
    # path.
    # @param [String] full_path
    # @param [Boolean] rel_to_su_reg_path Whether to acquire path relative to
    #   the registry path of the current SketchUp application or from the
    #   beginning.
    # @return [Hash{String => Fixnum, Bignum, String}] { value name => value_data, ... }
    def get_values(full_path, rel_to_su_reg_path = true)
    end

  end # class << self
end # module AMS::Registry
