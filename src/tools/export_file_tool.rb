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
      export_partslist
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

  def increase_number_of(collection, key)
    if collection[key].nil?
      collection[key] = 1
    else
      collection[key] += 1
    end
  end

  def export_partslist
    number_hubs = Graph.instance.nodes.count
    number_bottles = {}
    number_actuators = {}
    lengths_for_link = []
    Graph.instance.edges.each_value do |edge|
      if edge.link.is_a?(PhysicsLink)
        # the actuator length is rounded to the closest 10 cm
        actuator_length = (edge.link.length/10.0).round * 10
        increase_number_of(number_actuators, actuator_length)
      else
        increase_number_of(number_bottles, edge.bottle_type)
      end
      lengths_for_link.push({:id => edge.inspect(), :length => edge.length().to_s})
    end

    dir_name = File.dirname(@export_path)
    base_name = File.basename(@export_path, File.extname(@export_path))
    partslist_file = File.open("#{dir_name}/#{base_name}_partslist.txt", "w")
    partslist_file.puts("Parts for #{base_name}:\n\n")
    partslist_file.puts("Number of hubs: #{number_hubs}\n")
    partslist_file.puts("Number of bottles:\n")
    number_bottles.each do |bottle_type, count|
      partslist_file.puts("\t#{bottle_type}: #{count}\n")
    end
    partslist_file.puts("Number of actuators:\n")
    number_actuators.each do |actuator_length, count|
      partslist_file.puts("\t#{actuator_length} cm: #{count}\n")
    end

    partslist_file.puts("Distances of each link:\n")
    lengths_for_link.each do |lenght_for_link|
      partslist_file.puts("\t#{lenght_for_link[:id]} #{lenght_for_link[:length]}")
    end
    partslist_file.close
  end
end
