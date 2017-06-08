# AMS is a top level namespace of AMS Library. AMS stands for Anton M Synytsia.
module AMS

  # @since 2.0.0
  IS_PLATFORM_WINDOWS = (RUBY_PLATFORM =~ /mswin|mingw/i ? true : false)

  # @since 2.0.0
  IS_PLATFORM_OSX = (RUBY_PLATFORM =~ /darwin/i ? true : false)

  # @since 2.0.0
  IS_PLATFORM_LINUX = (RUBY_PLATFORM =~ /linux/i ? true : false)

  # @since 3.5.0
  IS_RUBY_VERSION_18 = (RUBY_VERSION =~ /1.8/ ? true : false)

  # @since 3.5.0
  IS_RUBY_VERSION_20 = (RUBY_VERSION =~ /2.0/ ? true : false)

  # @since 3.5.0
  IS_RUBY_VERSION_22 = (RUBY_VERSION =~ /2.2/ ? true : false)

  # @since 3.5.0
  IS_SKETCHUP_64BIT = ((Sketchup.respond_to?('is_64bit?') && Sketchup.is_64bit?) ? true : false)

  # @since 3.5.0
  IS_SKETCHUP_32BIT = !IS_SKETCHUP_64BIT

  # Path to directory where temporary files can be created and destroyed.
  TEMP_DIR = IS_PLATFORM_WINDOWS ? ENV["TEMP"].gsub(/\\/, '/') : ENV["TMPDIR"].gsub(/\\/, '/')

  class << self

    # Convert a Ruby object to string that can be evaluated back into the same
    # object.
    # @param [nil, Boolean, Fixnum, Bignum, Float, String, Symbol, Array, Hash]
    #   item An object to convert. An Array and a Hash can only contain objects
    #   of +NilClass+, +TrueClass+, +FalseClass+, +Fixnum, +Float+, +Bignum+,
    #   +String+, +Symbol+, +Array+, and +Hash+ types. This, as well, applies to
    #   sub-arrays and sub-hashes.
    # @raise [TypeError] if given item or sub-item type is not supported.
    # @since 3.1.0
    def inspect_element(item)
    end

    # Validate object type.
    # @param [Object] object
    # @param [Class, Array<Class>] types A class or an array of classes to
    #   check against.
    # @return [void]
    # @raise [TypeError] if object class doesn't match with any of the specified
    #   types.
    # @since 2.0.0
    def validate_type(object, *types)
    end

    # Clamp value between min and max.
    # @param [Numeric] value
    # @param [Numeric, nil] min Pass +nil+ to have no min limit.
    # @param [Numeric, nil] max Pass +nil+ to have no max limit.
    # @return [Numeric]
    # @since 2.0.0
    def clamp(value, min, max)
    end

    # Get sign of a numeric value.
    # @param [Numeric] value
    # @return [Fixnum] -1, 0, or 1
    # @since 2.0.0
    def sign(value)
    end

    # Get the least of two values.
    # @param [Numeric] a
    # @param [Numeric] b
    # @return [Numeric]
    # @since 2.0.0
    def min(a, b)
    end

    # Get the greatest of two values.
    # @param [Numeric] a
    # @param [Numeric] b
    # @return [Numeric]
    # @since 2.0.0
    def max(a, b)
    end

    # Round a numeric value to a particular number of decimal places.
    # @param [Numeric] number
    # @param [Fixnum] precision
    # @return [Numeric]
    # @since 3.3.0
    def round(number, precision = 0)
    end

    # Determine whether an object is a +true+ or +false+.
    # @return [Boolean]
    # @since 2.0.0
    def is_boolean?(object)
    end

    alias is_bool? is_boolean?

    # Get entity by entity ID.
    # @param [Fixnum] id
    # @return [Sketchup::Entity, nil]
    # @since 2.0.0
    def get_entity_by_id(id)
    end

    # Get top level entity by entity ID.
    # @param [Fixnum] id
    # @return [Sketchup::Entity, nil]
    # @since 3.0.0
    def get_top_entity_by_id(id)
    end

  end # class << self

  # Lib contains functions for manipulating files within the library's folder.
  module Lib

    # Folder location
    PATH = AMS::IS_RUBY_VERSION_18 ? ::File.dirname(__FILE__).freeze : ::File.dirname(__FILE__).force_encoding("UTF-8").freeze

    # Name of the main file
    BASE = AMS::IS_RUBY_VERSION_18 ? ::File.basename(__FILE__).freeze : ::File.basename(__FILE__).force_encoding("UTF-8").freeze

    class << self

      # Require all files.
      # @note All already loaded files will be ignored.
      # @return [Fixnum] The number of files loaded.
      # @since 2.0.0
      def require_all
      end

      # Load all files.
      # @note All already loaded files will be reloaded.
      # @return [Fixnum] The number of files loaded.
      # @since 2.0.0
      def load_all
      end

      # Require a specific file.
      # @note The file will not be loaded if it was already loaded.
      # @param [String] file_name
      # @return [Boolean] success
      # @since 2.0.0
      def require(file_name)
      end

      # Load a specific file.
      # @note The file will be reloaded if it was already loaded.
      # @param [String] file_name
      # @return [Boolean] success
      # @since 2.0.0
      def load(file_name)
      end

      # Remove unregistered Ruby files from the library.
      # @return [Fixnum] Number of files deleted.
      # @since 2.1.0
      def clean_up
      end

    end # class << self
  end # module Lib
end # module AMS
