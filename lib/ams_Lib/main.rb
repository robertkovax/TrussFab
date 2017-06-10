# require 'ams_Lib.rb'

# AMS is a top level namespace of AMS Library. AMS stands for Anton M Synytsia.
# @since 2.0.0
module AMS

  IS_PLATFORM_WINDOWS = (RUBY_PLATFORM =~ /mswin|mingw/i ? true : false)
  IS_PLATFORM_OSX = (RUBY_PLATFORM =~ /darwin/i ? true : false)
  IS_PLATFORM_LINUX = (RUBY_PLATFORM =~ /linux/i ? true : false)

  TEMP_DIR = IS_PLATFORM_WINDOWS ? ENV["TEMP"].gsub(/\\/, '/') : ENV["TMPDIR"].gsub(/\\/, '/')

  class << self

    # Validate object type.
    # @param [Object] object
    # @param [Object, Array<Object>] types An object or an array of objects to
    #   check against.
    # @return [void]
    # @raise [TypeError] if object class doesn't match with any of the specified
    #   types.
    def validate_type(object, *types)
      types = types.flatten
      return if types.empty?
      types.each { |type| return if object.is_a?(type) }
      string = case types.size
      when 1
        types[0].to_s
      when 2
        "#{types[0]} or #{types[1]}"
      else
        "#{types[0...-1].join(', ')}, or #{types[-1]}"
      end
      if RUBY_VERSION =~ /1.8/
        ::Kernel.raise(TypeError, "Expected #{string}, but got #{object.class.to_s}.", caller)
      else
        ::Kernel.raise(TypeError, "Expected #{string.force_encoding("UTF-8")}, but got #{object.class.to_s.force_encoding("UTF-8")}.", caller)
      end
    end

    # Clamp value between min and max.
    # @param [Numeric] value
    # @param [Numeric, nil] min Pass +nil+ to have no min limit.
    # @param [Numeric, nil] max Pass +nil+ to have no max limit.
    # @return [Numeric]
    def clamp(value, min, max)
      if min and value < min
        min
      elsif max and value > max
        max
      else
        value
      end
    end

    # Get numeric value sign.
    # @param [Numeric] value
    # @return [Fixnum] -1, 0, or 1
    def sign(value)
      value.zero? ? 0 : (value > 0 ? 1 : -1)
    end

    # Get least value of the two values.
    # @param [Numeric] a
    # @param [Numeric] b
    # @return [Numeric]
    def min(a, b)
      a < b ? a : b
    end

    # Get greatest value of the two values.
    # @param [Numeric] a
    # @param [Numeric] b
    # @return [Numeric]
    def max(a, b)
      a > b ? a : b
    end

    # Round number up to a particular decimal point.
    # @param [Numeric] number
    # @param [Fixnum] precision
    # @return [Numeric]
    # @since 3.3.0
    def round(number, precision = 0)
      if RUBY_VERSION =~ /1.8/
        if precision.to_i == 0
          number.round
        else
          mag = 10**precision.to_i
          (number * mag).round / mag
        end
      else
        number.round(precision.to_i)
      end
    end

    # Scale vector.
    # @param [Array<Numeric>, Geom::Vector3d] vector
    # @param [Numeric] scale
    # @return [Geom::Vector3d]
    def scale_vector(vector, scale)
      Geom::Vector3d.new(vector[0]*scale, vector[1]*scale, vector[2]*scale)
    end

    # Get entity by entity ID.
    # @param [Fixnum] id
    # @return [Sketchup::Entity, nil]
    def get_entity_by_id(id)
      model = ::Sketchup.active_model
      model.entities.each { |e| return e if e.entityID == id }
      model.definitions.each { |d|
        return d if d.entityID == id
        d.instances.each { |e| return e if e.entityID == id }
        d.entities.each { |e| return e if e.entityID == id }
      }
      model.materials.each { |e| return e if e.entityID == id }
      model.layers.each { |e| return e if e.entityID == id }
      model.styles.each { |e| return e if e.entityID == id }
      model.pages.each { |e| return e if e.entityID == id }
      nil
    end

    # Get top level entity by entity ID.
    # @param [Fixnum] id
    # @return [Sketchup::Entity, nil]
    # @since 3.0.0
    def get_top_entity_by_id(id)
      ::Sketchup.active_model.entities.each { |e|
        return e if e.entityID == id
      }
      nil
    end

    # Determine whether object is +true+ or +false+.
    # @return [Boolean]
    def is_boolean?(object)
      object.is_a?(TrueClass) || object.is_a?(FalseClass)
    end

    alias is_bool? is_boolean?

  end # class << self
end # module AMS


# The Lib namespace contains a set of utility functions that make it easy for
# the user to control particular files within the library.
# @since 2.0.0
module AMS::Lib

  # Folder location
  PATH = RUBY_VERSION =~ /1.8/ ? ::File.dirname(__FILE__).freeze : ::File.dirname(__FILE__).force_encoding("UTF-8").freeze
  # Name of the main file
  BASE = RUBY_VERSION =~ /1.8/ ? ::File.basename(__FILE__).freeze : ::File.basename(__FILE__).force_encoding("UTF-8").freeze

  # @!visibility private
  REGISTERED_FILES = [
    'main.rb',
    'multi_line_text.rb',
    'ray_util.rb',
    'system.rb',
    'translate.rb',
    'geometry.rb',
    'group.rb'
  ].freeze

  class << self

    # Require all library.
    # @note All already loaded files will be ignored.
    # @return [Fixnum] The number of files loaded.
    def require_all
      count = 0
      ::Dir.glob( ::File.join(PATH, '*.{rb, rbs}') ).each { |fpath|
        fpath.force_encoding("UTF-8") if RUBY_VERSION !~ /1.8/
        base_name = ::File.basename(fpath)
        next if base_name == BASE || !REGISTERED_FILES.include?(base_name)
        res = ::Kernel.require(fpath)
        count += 1 if res
      }
      count
    end

    # Load all library.
    # @note All already loaded files will be reloaded.
    # @return [Fixnum] The number of files loaded.
    def load_all
      count = 0
      ::Dir.glob( ::File.join(PATH, '*.{rb, rbs}') ).each { |fpath|
        fpath.force_encoding("UTF-8") if RUBY_VERSION !~ /1.8/
        base_name = ::File.basename(fpath)
        next if base_name == BASE || !REGISTERED_FILES.include?(base_name)
        ::Kernel.load(fpath)
        count += 1
      }
      count
    end

    # Require specific file within the library's path.
    # @note The file will not be loaded if it was already loaded.
    # @param [String] file_name
    # @return [Boolean] success
    def require(file_name)
      fpath = ::File.join(PATH, file_name)
      fpath.force_encoding("UTF-8") if RUBY_VERSION !~ /1.8/
      ::Kernel.require(fpath)
    end

    # Load specific file within the library's path.
    # @note The file will be reloaded if it was already loaded.
    # @param [String] file_name
    # @return [Boolean] success
    def load(file_name)
      fpath = ::File.join(PATH, file_name)
      fpath.force_encoding("UTF-8") if RUBY_VERSION !~ /1.8/
      ::Kernel.load(fpath)
    end

    # Remove unregistered Ruby files from the library.
    # @return [Fixnum] Number of files deleted.
    # @since 2.1.0
    def clean_up
      count = 0
      ::Dir.glob( ::File.join(PATH, '*.{rb, rbs}') ).each { |fpath|
        fpath.force_encoding("UTF-8") if RUBY_VERSION !~ /1.8/
        base_name = ::File.basename(fpath)
        next if base_name == BASE || REGISTERED_FILES.include?(base_name)
        ::File.delete(fpath)
        count += 1
      }
      count
    end

  end # class << self
end # module AMS::Lib

unless file_loaded?(__FILE__)
  file_loaded(__FILE__)

  ops = (RUBY_PLATFORM =~ /mswin|mingw/i) ? 'win' : 'osx'
  bit = (Sketchup.respond_to?('is_64bit?') && Sketchup.is_64bit?) ? '64' : '32'
  ver = RUBY_VERSION[0..2]
  ext = (RUBY_PLATFORM =~ /mswin|mingw/i) ? '.so' : '.bundle'

  require File.join(AMS::Lib::PATH, ops+bit, ver, 'ams_lib' + ext)

  if RUBY_PLATFORM =~ /mswin|mingw/i
    require File.join(AMS::Lib::PATH, ops+bit, ver, 'ams_win32_api' + ext)
  end

  #~ AMS::Lib.clean_up
  AMS::Lib.require_all
end
