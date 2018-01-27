# Require AMS Library
require 'ams_Lib'

# Load the C extension
dir = File.dirname(__FILE__)

ops = AMS::IS_PLATFORM_WINDOWS ? 'win' : 'osx'
bit = AMS::IS_SKETCHUP_64BIT ? '64' : '32'
rbv = RUBY_VERSION[0..2].to_s
c_ext = AMS::IS_PLATFORM_WINDOWS ? '.so' : '.bundle'
l_ext = AMS::IS_PLATFORM_WINDOWS ? '.dll' : '.dylib'

lib_path =  File.join(dir, 'ext', ops + bit)
lib_fpath = File.join(lib_path, 'newton' + l_ext)
ext_fpath = File.join(lib_path, rbv, 'msp_lib' + c_ext)

AMS::DLL.load_library lib_fpath
require ext_fpath

# Require the main files
require 'src/configuration/configuration'
require 'src/utility/project_helper'
require 'src/ui/user_interaction'
require 'src/ui/component_properties'
require 'reloader'

module TrussFab

  @reloader = Reloader.new
  @ui = UserInteraction.new

  class << self

    def start
      @ui.open_dialog
    end

    def stop
      @ui.close_dialog
    end

    def reload
      @reloader.reload
    end

  end
end

unless file_loaded?(__FILE__)

  ProjectHelper.setup_sketchup
  ComponentProperties.new

end
