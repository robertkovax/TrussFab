class ScadExport
  def self.export_to_scad(path, nodes)
    nodes.each { |node| node_to_scad(path, node) }
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
