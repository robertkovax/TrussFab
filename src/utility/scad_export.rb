require 'src/tools/hinge_tool'
require 'src/export/export_hinge'
require 'src/export/export_hub'
require 'src/export/export_elongation'

class ScadExport
  def self.export_to_scad(path, nodes)
    hinge_tool = HingeTool.new
    hinge_tool.activate

    export_hinges = []
    export_hubs = []

    hinge_tool.hinges.each do |hinge|
      #TODO: make sure that l1-l3 work with elongation of the two edges
      angle = hinge.edge1.angle_between(hinge.edge2)
      export_hinge = ExportHinge.new(0, 0, 0, 0, 0, 0,
                                     angle, true, true, false, false)
      export_hinges.push(export_hinge)
    end
    p hinge_tool.hubs

    hinge_tool.hubs.each do |node, hubs|
      i = 0
      hubs.each do |hub|
        is_main_hub = (i == 0)
        export_hub = ExportHub.new(is_main_hub)

        hub.each do |edge|
          export_elongation = ExportElongation.new(false, 0, 0, 0)
          export_hub.add_elongation(export_elongation)
        end

        export_hubs.push(export_hub)
        i += 1
      end
    end

    #nodes.each { |node| node_to_scad(path, node) }
  end

  def self.node_to_scad(path, node)
    info = { vector_array: [], addon_array: [], type_array: [] }

    node.incidents.each do |incident|
      vector = incident.direction.normalize
      if incident.first_node == node
        info[:addon_array] << "[#{incident.first_elongation_length.to_mm}, \"#{incident.second_node.id}\"0] "
        info[:type_array] << '\"SNAP\"'
      else
        vector.reverse!
        info[:addon_array] << "[#{incident.second_elongation_length.to_mm}, \"#{incident.first_node.id}\"0] "
        info[:type_array] << '\"SNAP\"'
      end
      info[:vector_array] << "[#{vector.to_a.join(', ')}]"
    end

    node.pods.each do |pod|
      info[:addon_array] << '[(45 - 0 - 10), \"STAND\",0,24,10,60,0] '
      info[:type_array] << '\"STAND\"'
      info[:vector_array] << pod.direction.normalize.to_a.join(', ').to_s
    end

    filename = path + '/Connector_' + node.id.to_s.rjust(3, '0') + '.scad'
    write_node_to_file(filename, node.id, info, 'Tube')
  end

  def self.write_node_to_file(filename, id, info, mode)
    file = File.new(filename, 'w')
    export_string =
      "// adjust filepath to LibSTLExport if neccessary\n" \
      "include <#{ProjectHelper.library_directory}/openscad/LibSTLExport.scad>\n" \
      "\n" \
      "hubID = \"#{id}\";\n" \
      "mode = \"#{mode}\";\n" \
      "safetyFlag = false;\n" \
      "connectorDataDistance = 0;\n" \
      "tubeThinning = 1.0;\n" \
      "useFixedCenterSize = false;\n" \
      "hubCenterSize = 0;\n" \
      "printVectorInteger = 8;\n" \
      "dataFileVectorArray = [\n" \
      "#{info[:vector_array].join(",\n")}\n" \
      "];\n" \
      "dataFileAddonParameterArray = [\n" \
      "#{info[:addon_array].join(",\n")}\n" \
      "];\n" \
      "connectorTypeArray = [\n" \
      "#{info[:type_array].join(",\n")}\n" \
      "];\n" \
      "drawHub(dataFileVectorArray, dataFileAddonParameterArray, connectorTypeArray);\n"

    file.write(export_string)
    file.close
    export_string
  end
end
