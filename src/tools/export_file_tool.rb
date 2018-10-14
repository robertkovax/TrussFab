require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_export.rb'
require 'src/configuration/configuration.rb'

# Exports Object to JSON
class ExportFileTool < Tool
  def initialize(user_interface)
    super
    @mouse_input = MouseInput.new(snap_to_surfaces: true)
  end

  def activate
    export_with_file_dialog
    Sketchup.set_status_text('To export with a specific standard surface,'\
                             'click that surface')
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    snapped_object = @mouse_input.snapped_object
    if snapped_object.is_a?(Triangle)
      export_with_file_dialog(snapped_object)
      deactivate(view)
    end
    view.invalidate
  end

  def export_with_file_dialog(triangle = nil)
    @export_path = Configuration::JSON_PATH if @export_path.nil?
    @export_path = UI.savepanel('Export JSON', @export_path, 'export.json')
    animation = @ui.animation_pane.animation_values
    unless @export_path.nil?
      JsonExport.export(@export_path, triangle, animation)
    end
    @export_path = File.dirname(@export_path)
  end
end
