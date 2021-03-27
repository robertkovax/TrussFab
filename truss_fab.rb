# TrussFab is compatible with SU2014 or later

# Load the C extension

dir = File.dirname(__FILE__)
dir.force_encoding("UTF-8")

Dir.chdir dir

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
require 'src/ui/dialogs/animation_pane'
require 'src/ui/dialogs/spring_pane'
require 'src/ui/dialogs/sidebar'
require 'src/ui/dialogs/component_properties'
require 'src/models/spirix'

# reloader helper
require 'reloader'

module TrussFab

  @reloader = Reloader.new
  @sidebar_menu = Sidebar.new
  @animation_pane = AnimationPane.new
  @spring_pane = SpringPane.new
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
      @spring_pane.open_dialog

      @sidebar_menu.animation_pane = @animation_pane
      @animation_pane.sidebar_menu = @sidebar_menu

      @sidebar_menu.spring_pane = @spring_pane
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

    def get_spring_pane
      @spring_pane
    end

    # Just use this for debugging in the console
    def get_animation_pane
      @animation_pane
    end

    def simulate
      get_spring_pane.simulate
    end

    def display_warning(name="Example name", message="You can customize this with an argument")
      properties = {
        dialog_title: name,
        scrollable: false,
        resizable: false,
        left: 10,
        top: 100,
        height: 150,
        style: UI::HtmlDialog::STYLE_DIALOG
      }.freeze

      dialog = UI::HtmlDialog.new(properties)
      dialog.set_html(%Q(
      <html>
      <head>
      <meta charset="utf-8"></head>
      <link rel="stylesheet" href="../css/ui.css" type="text/css">
      <body>
      <h5>#{message}</h5>
      <br>
      <button type="button" style="float: right;" onclick="window.close()">Ok</button>
      </body>
      </html>
)
      )

      dialog.show_modal
    end
  end
end

unless file_loaded?(__FILE__)

  ProjectHelper.setup_sketchup
  ComponentProperties.new

end
