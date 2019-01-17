require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/utility/json_export.rb'
require 'src/configuration/configuration.rb'

# Exports Object to JSON
class ExportFileTool < Tool
  def initialize(user_interface)
    super
  end

  def activate
    triangle = nil
    selection = Sketchup.active_model.selection
    unless selection.nil? or selection.empty?
      selection.each do |entity|
        type = entity.get_attribute('attributes', :type)
        id = entity.get_attribute('attributes', :id)
        if type.include? 'Surface'
          triangle = Graph.instance.triangles[id]
        end
      end
    end
    export_with_file_dialog(triangle)
    Sketchup.set_status_text('To export with a specific standard surface,'\
                             'select that surface')
  end

  def export_with_file_dialog(triangle = nil)
    @export_path = Configuration::JSON_PATH if @export_path.nil?
    @export_path = UI.savepanel('Export JSON', @export_path, 'export.json')
    animation = @ui.animation_pane.animation_values
    unless @export_path.nil?
      JsonExport.export(@export_path, triangle, animation)
      export_animation_to_txt(animation)
      @export_path = File.dirname(@export_path)
    end
  end

  def export_animation_to_txt(animation)
    dir_name = File.dirname(@export_path)
    base_name = File.basename(@export_path, File.extname(@export_path))
    animation_file = File.open("#{dir_name}/#{base_name}_animation.txt", "w")
    animation_file.puts(JSON.pretty_generate(JSON.parse(animation)).to_s)
    animation_file.close
  end
end
