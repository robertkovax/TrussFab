require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_export.rb'
require 'src/configuration/configuration.rb'

class ExportFileTool < Tool
  def initialize(ui)
    super
    @mouse_input = MouseInput.new(snap_to_surfaces: true)
  end

  def activate
    UI.messagebox('Please select a surface to become the standard surface'\
                  ' that gets attached when added to other objects',
                  MB_OK)
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
    path = UI.savepanel('Export JSON', Configuration::JSON_PATH, '')
    JsonExport.export(path, triangle) unless path.nil?
  end
end
