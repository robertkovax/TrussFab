require 'src/tools/hinge_tool'
require 'src/export/export_hinge'
require 'src/export/export_hub'
require 'src/export/export_elongation'
require 'src/export/export_cap'
require 'src/algorithms/relaxation.rb'
require 'src/export/presets.rb'

class ScadExport
  def self.export_to_scad(path, nodes, edges)
    hinge_tool = HingeTool.new(nil)
    hinge_tool.activate

    export_hinges = []
    export_hubs = []
    export_caps = []

    l2 = PRESETS::SIMPLE_HINGE_RUBY['l2']

    #TODO: find out minimum l3 value
    l3_min = PRESETS::SIMPLE_HINGE_RUBY['l3_min']

    # stores the l1 value per node (since it needs to be constant across a node)
    node_l1 = Hash.new

    hinge_tool.hinges.each do |node, hinges|
      max_l1 = 0.0.mm

      hinges.each do |hinge|
        max_l1 = [max_l1, hinge.l1].max
      end

      node_l1[node] = max_l1
    end

    loop do
      relaxation = Relaxation.new
      is_finished = true

      hinge_tool.hinges.each do |node, hinges|
        l1 = node_l1[node]

        hinges.each do |hinge|
          [hinge.edge1, hinge.edge2].each do |edge|
            if edge.link_type == 'actuator'
              next
            end

            elongation = edge.first_node?(node) ? edge.first_elongation_length : edge.second_elongation_length
            target_elongation = l1 + l2 + l3_min

            if elongation < target_elongation
              total_elongation = edge.first_elongation_length + edge.second_elongation_length
              relaxation.stretch_to(edge, edge.length - total_elongation + 2*target_elongation + 10.mm)
              is_finished = false
            end
          end
        end
      end

      if is_finished
        break
      end

      relaxation.relax
      Sketchup.active_model.commit_operation
    end

    hinge_tool.hinges.each do |node, hinges|
      l1 = node_l1[node]
      
      hinges.each do |hinge|
        a_other_node = hinge.edge1.other_node(node)
        b_other_node = hinge.edge2.other_node(node)

        if hinge.is_a? ActuatorHinge
          a_with_connector = false
          b_with_connector = true
          a_gap = true
          b_gap = false

          if hinge.edge1.link_type == 'actuator'
            a_with_connector = true
            b_with_connector = false
            a_gap = false
            b_gap = true
          end

          intermediate_hinge = ExportHinge.new(node.id, "i" + a_other_node.id.to_s, "i" + b_other_node.id.to_s, l1.to_mm, l2.to_mm, l3_min.to_mm, l1.to_mm, l2.to_mm, l3_min.to_mm,
                                               PRESETS::ACTUATOR_HINGE_OPENSCAD['gap_angle'], true, true, false, false, PRESETS::ACTUATOR_HINGE_OPENSCAD)
          export_hinges.push(intermediate_hinge)

          actuator_hinge = ExportHinge.new(node.id, "a" + a_other_node.id.to_s, "a" + b_other_node.id.to_s, l1.to_mm, l2.to_mm, l3_min.to_mm, l1.to_mm, l2.to_mm, l3_min.to_mm,
                                           PRESETS::ACTUATOR_HINGE_OPENSCAD['gap_angle'], a_gap, b_gap, a_with_connector, b_with_connector, PRESETS::ACTUATOR_HINGE_OPENSCAD)
          export_hinges.push(actuator_hinge)

          next
        end

        other_a_hinges = hinges.select { |other| hinge.edge1 == other.edge2 }
        other_b_hinges = hinges.select { |other| hinge.edge2 == other.edge1 }

        if other_a_hinges.size > 1 or other_b_hinges.size > 1
          raise RuntimeError, 'More than one hinge connected to a hinge.'
        end

        elongation1 = hinge.edge1.first_node?(node) ? hinge.edge1.first_elongation_length : hinge.edge1.second_elongation_length
        elongation2 = hinge.edge2.first_node?(node) ? hinge.edge2.first_elongation_length : hinge.edge2.second_elongation_length

        a_l3 = elongation1 - l1 - l2
        b_l3 = elongation2 - l1 - l2

        # for every b hinge that has another hinge, we add a cap
        unless other_b_hinges.empty?
          export_caps.push(ExportCap.new(node.id, b_other_node.id, b_l3.to_mm))
        end

        if a_l3 < l3_min or b_l3 < l3_min
          raise RuntimeError, "Hinge l3 distance too small: #{a_l3.to_mm}, #{b_l3.to_mm}, #{l3_min.to_mm}."
        end

        a_with_connector = other_a_hinges.empty?
        b_with_connector = other_b_hinges.empty?
        a_gap = !other_a_hinges.empty?
        b_gap = !other_b_hinges.empty?

        export_hinge = ExportHinge.new(node.id, a_other_node.id, b_other_node.id, l1.to_mm, l2.to_mm, a_l3.to_mm, l1.to_mm, l2.to_mm, b_l3.to_mm,
                                       hinge.angle, a_gap, b_gap, a_with_connector, b_with_connector, PRESETS::SIMPLE_HINGE_OPENSCAD)
        export_hinges.push(export_hinge)
      end
    end

    hinge_tool.hubs.each do |node, hubs|
      hub_id = node.id

      #TODO: consider sub hubs, currently every hub is exported as a main hub
      i = 0
      hubs.each do |hub|
        is_main_hub = (i == 0)
        export_hub = ExportHub.new(is_main_hub, hub_id)

        if is_main_hub
          node.pods.each do |pod|
            export_hub.add_pod(pod)
          end
        end

        hub.each do |edge|
          hinges = hinge_tool.hinges[node].select { |hinge| hinge.edge1 == edge or hinge.edge2 == edge }
          if hinges.size > 2
            raise RuntimeError, 'More than two hinges around an edge.'
          end

          elongation = edge.first_node?(node) ? edge.first_elongation_length : edge.second_elongation_length
          other_node = edge.other_node(node)
          direction = node.position.vector_to(other_node.position).normalize

          elongation_length = elongation
          is_hinge_connected = hinges.size > 0

          if is_hinge_connected
            elongation_length = node_l1[node]
          end

          export_elongation = ExportElongation.new(hub_id, other_node.id, is_hinge_connected, elongation_length.to_mm, direction)
          export_hub.add_elongation(export_elongation)
        end

        export_hubs.push(export_hub)
        i += 1
      end
    end

    export_hinges.each do |hinge|
      hinge.write_to_file(path)
    end

    export_hubs.each do |hub|
      hub.write_to_file(path)
    end

    export_caps.each do |cap|
      cap.write_to_file(path)
    end

    #nodes.each { |node| node_to_scad(path, node) }
  end

  def self.node_to_scad(path, node)
    info = { vector_array: [], addon_array: [], type_array: [] }

    node.incidents.each do |incident|
      vector = incident.direction.normalize
      if incident.first_node == node
        info[:addon_array] << "[#{incident.first_elongation_length.to_mm}, \"#{incident.second_node.id}\"0] "
        info[:type_array] << '"SNAP"'
      else
        vector.reverse!
        info[:addon_array] << "[#{incident.second_elongation_length.to_mm}, \"#{incident.first_node.id}\"0] "
        info[:type_array] << '"SNAP"'
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
