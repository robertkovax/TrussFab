require 'src/tools/hinge_tool'
require 'src/export/export_hinge'
require 'src/export/export_hub'
require 'src/export/export_elongation'
require 'src/export/export_cap'
require 'src/algorithms/relaxation.rb'

class ScadExport
  def self.export_to_scad(path, nodes, edges)
    hinge_tool = HingeTool.new(nil)
    hinge_tool.activate
    relaxation = Relaxation.new

    export_hinges = []
    export_hubs = []
    export_caps = []

    gap_height = 10.mm.freeze
    gap_epsilon = 0.8.mm.freeze
    l2 = 4 * gap_height + gap_epsilon * 1.5 # see openscad gap height for more information

    #TODO: find out minimum l3 value
    l3_min = 10.mm.freeze

    # stores the l1 value per node (since it needs to be constant across a node)
    node_l1 = Hash.new

    hinge_tool.hinges.each do |node, hinges|
      max_l1 = 0.0.mm

      hinges.each do |hinge|
        max_l1 = [max_l1, hinge.l1].max
      end

      node_l1[node] = max_l1
    end

    hinge_tool.hinges.each do |node, hinges|
      l1 = node_l1[node]

      hinges.each do |hinge|
        if hinge.is_a? ActuatorHinge
          next
        end

        [hinge.edge1, hinge.edge2].each do |edge|
          elongation = edge.first_node?(node) ? edge.first_elongation_length : edge.second_elongation_length
          target_elongation = l1 + l2 + l3_min

          while elongation < target_elongation
            total_elongation = edge.first_elongation_length + edge.second_elongation_length
            relaxation.stretch_to(edge, edge.length - total_elongation + 2*target_elongation + 10.mm)
            relaxation.relax
            elongation = edge.first_node?(node) ? edge.first_elongation_length : edge.second_elongation_length
          end
        end
      end
    end
    Sketchup.active_model.commit_operation

    hinge_tool.hinges.each do |node, hinges|
      l1 = node_l1[node]
      node_actuators = edges.select { |edge| edge.link_type == 'actuator' and edge.nodes.include?(node) }
      has_actuator = node_actuators.size > 0

      i = 0
      hinges.each do |hinge|
        if hinge.is_a? ActuatorHinge
          #TODO: generate two actuator hinges
          # angle 35° for both
          # gap distance 1mm
          # l1 same as node
          # one open on both sides, one connecting to edge
          next
        end

        is_first = (i == 0)
        is_last = (i == hinges.size - 1)

        edge1 = hinge.edge1
        edge2 = hinge.edge2
        elongation1 = edge1.first_node?(node) ? edge1.first_elongation_length : edge1.second_elongation_length
        elongation2 = edge2.first_node?(node) ? edge2.first_elongation_length : edge2.second_elongation_length

        a_other_node = edge1.other_node(node)
        b_other_node = edge2.other_node(node)

        a_l3 = elongation1 - l1 - l2
        b_l3 = elongation2 - l1 - l2

        export_cap = ExportCap.new(node.id, a_other_node.id, a_l3.to_mm)
        export_caps.push(export_cap)

        if a_l3 < l3_min or b_l3 < l3_min
          raise RuntimeError, "Hinge l3 distance too small.: #{a_l3.to_mm}, #{b_l3.to_mm}, #{l3_min.to_mm}."
        end

        a_with_connector = is_first
        b_with_connector = is_last
        a_gap = !is_first
        b_gap = !is_last

        # if an actuator is present, one gap has to be created to allow the actuator to be connected
        if is_last and has_actuator
          b_gap = true
        end

        export_hinge = ExportHinge.new(node.id, a_other_node.id, b_other_node.id, l1.to_mm, l2.to_mm, a_l3.to_mm, l1.to_mm, l2.to_mm, b_l3.to_mm,
                                       hinge.angle, a_gap, b_gap, a_with_connector, b_with_connector)
        export_hinges.push(export_hinge)

        i += 1
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
