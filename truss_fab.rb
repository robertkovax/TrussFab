# TrussFab is compatible with SU2014 or later

# Load the C extension

dir = File.dirname(__FILE__)
dir.force_encoding("UTF-8")

bwin = (RUBY_PLATFORM =~ /mswin|mingw/i ? true : false)
b64 = ((Sketchup.respond_to?('is_64bit?') && Sketchup.is_64bit?) ? true : false)

ops = bwin ? 'win' : 'osx'
bit = b64 ? '64' : '32'
rbv = RUBY_VERSION[0..2].to_s
c_ext = bwin ? '.so' : '.bundle'
l_ext = bwin ? '.dll' : '.dylib'

lib_path =  File.join(dir, 'ext', ops + bit)
lib_fpath = File.join(lib_path, 'newton' + l_ext)
ext_fpath = File.join(lib_path, rbv, 'tfn_lib' + c_ext)

if bwin
  require 'fiddle'
  Fiddle.dlopen(lib_fpath)
end

require ext_fpath

# Require the main files
require 'src/configuration/configuration'
require 'src/utility/project_helper'

# ui files
require 'src/ui/dialogs/actuator_menu'
require 'src/ui/dialogs/sidebar'
require 'src/ui/component_properties'

# reloader helper
require 'reloader'

module TrussFab

  @reloader = Reloader.new
  @sidebar = Sidebar.new
  @actuator_menu = ActuatorMenu.new

  class << self

    def start
      @sidebar.open_dialog
      @actuator_menu.open_dialog
    end

    def stop
      @sidebar.close_dialog
      @actuator_menu.close_dialog
    end

    def refresh_ui
      @sidebar.refresh
      @actuator_menu.refresh
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
