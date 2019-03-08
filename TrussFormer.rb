# TrussFab is compatible with SU2014 or later
$LOAD_PATH << File.join(File.dirname(__FILE__), "TrussFormer")
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

lib_path =  File.join(dir, 'TrussFormer/ext', ops + bit)
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
require 'src/ui/dialogs/animation_pane'
require 'src/ui/dialogs/sidebar'
require 'src/ui/dialogs/component_properties'


module TrussFab

  @sidebar_menu = Sidebar.new
  @animation_pane = AnimationPane.new
  @store_sensor_output = false

  class << self

    def start
      model = Sketchup.active_model
      model.start_operation('TrussFab Setup', true)
      ProjectHelper.setup_layers
      ProjectHelper.setup_surface_materials
      ModelStorage.instance.setup_models
      model.commit_operation
      # This removes all deleted nodes and edges from storage
      Graph.instance.cleanup

      @sidebar_menu.open_dialog

      @animation_pane.open_dialog(@sidebar_menu.width + @sidebar_menu.left, @sidebar_menu.height + @sidebar_menu.top)

      @sidebar_menu.animation_pane = @animation_pane
      @animation_pane.sidebar_menu = @sidebar_menu
    end

    def stop
      @sidebar_menu.close_dialog
      @animation_pane.close_dialog
    end

    def refresh_ui
      @sidebar_menu.refresh
      @animation_pane.refresh
    end

    # call 'TrussFab.dev' to toggle between 'dev' modes
    def dev
      @animation_pane.toggle_dev_mode
      @sidebar_menu.toggle_dev_mode
      # TODO: add here other UI parts / components that have a 'dev' mode
    end

    def reload
      @reloader.reload
    end

    def store_sensor_output
      @store_sensor_output = !@store_sensor_output
    end

    def store_sensor_output?
      @store_sensor_output
    end
  end

  TrussFab.start
end

unless file_loaded?(__FILE__)

  ProjectHelper.setup_sketchup
  ComponentProperties.new

end
