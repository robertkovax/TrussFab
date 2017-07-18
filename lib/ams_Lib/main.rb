require 'sketchup.rb'
require 'extensions.rb'
require 'langhandler.rb'

# AMS is a top level namespace of AMS Library. AMS stands for Anton M Synytsia.
# @since 1.0.0
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
  if IS_PLATFORM_WINDOWS
    dir = ::File.join(::File.expand_path(ENV['LOCALAPPDATA']), 'Temp')
  else
    dir = ::File.expand_path(ENV["TMPDIR"])
  end
  dir.force_encoding("UTF-8") unless IS_RUBY_VERSION_18
  # @since 2.0.0
  TEMP_DIR = dir.freeze

  # Lib contains functions for manipulating files within the library's folder.
  # @since 1.0.0
  module Lib

    NAME = 'AMS Library'.freeze
    VERSION = '3.5.1'.freeze
    RELEASE_DATE = 'July 17, 2017'.freeze

    # Folder location
    path = ::File.dirname(__FILE__)
    path.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
    # @since 2.0.0
    PATH = path.freeze

    # Name of the main file
    base = ::File.basename(__FILE__)
    base.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
    # @since 2.0.0
    BASE = base.freeze

    class << self

      # Require all Ruby files within the extension's path.
      # @note All already loaded files will be ignored.
      # @return [Fixnum] The number of files loaded.
      # @since 2.0.0
      def require_all
        count = 0
        filters = ::Sketchup.version.to_i >= 16 ? '*.{rb, rbs, rbe}' : '*.{rb, rbs}'
        ::Dir.glob( ::File.join(PATH, filters) ).each { |fpath|
          fpath.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
          res = ::Kernel.require(fpath)
          count += 1 if res
        }
        count
      end

      # Load all Ruby files within the extension's path.
      # @note All already loaded files will be reloaded.
      # @return [Fixnum] The number of files loaded.
      # @since 2.0.0
      def load_all
        count = 0
        filters = ::Sketchup.version.to_i >= 16 ? '*.{rb, rbs, rbe}' : '*.{rb, rbs}'
        ::Dir.glob( ::File.join(PATH, filters) ).each { |fpath|
          fpath.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
          ::Kernel.load(fpath)
          count += 1
        }
        count
      end

      # Require a specific file.
      # @note The file will not be loaded if it was already loaded.
      # @param [String] filename
      # @return [Boolean] success
      # @since 2.0.0
      def require(filename)
        fpath = ::File.join(PATH, filename)
        fpath.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
        ::Kernel.require(fpath)
      end

      # Load a specific file.
      # @note The file will be reloaded if it was already loaded.
      # @param [String] filename
      # @return [Boolean] success
      # @since 2.0.0
      def load(filename)
        fpath = ::File.join(PATH, filename)
        fpath.force_encoding("UTF-8") unless AMS::IS_RUBY_VERSION_18
        ::Kernel.load(fpath)
      end

    end # class << self
  end # module Lib
end # module AMS

unless file_loaded?(__FILE__)
  file_loaded(__FILE__)

  AMS::Lib.require('extension_manager')

  ext_manager = AMS::ExtensionManager.new(AMS::Lib::PATH, AMS::Lib::VERSION)
  ext_manager.add_c_extension('ams_lib')
  ext_manager.add_ruby_no_require('main')
  ext_manager.add_ruby_no_require('extension_manager')
  ext_manager.add_ruby('translate')
  ext_manager.require_all
  ext_manager.clean_up(true)
end
