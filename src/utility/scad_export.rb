require 'src/tools/hinge_analysis_tool'
require 'src/export/export_hinge'
require 'src/export/export_hub'
require 'src/export/export_elongation'
require 'src/export/export_cap'
require 'src/algorithms/relaxation.rb'
require 'src/export/presets.rb'

class ScadExport
  def self.export_to_scad(path)
    hinge_algorithm = HingePlacementAlgorithm.instance
    hinge_algorithm.run

    export_hinges = []
    export_hubs = []
    export_caps = []

    l2 = PRESETS::SIMPLE_HINGE_RUBY['l2']
    l3_min = PRESETS::SIMPLE_HINGE_RUBY['l3_min']

    hinge_algorithm.hinges.each do |node, hinges|
      l1 = hinge_algorithm.node_l1[node]

      hinges.each do |hinge|
        a_other_node = hinge.edge1.other_node(node)
        b_other_node = hinge.edge2.other_node(node)

        a_with_connector = false
        b_with_connector = false

        other_a_hinges = hinges.select { |other| hinge.edge1 == other.edge2 }
        other_b_hinges = hinges.select { |other| hinge.edge2 == other.edge1 }

        if other_a_hinges.size > 1 or other_b_hinges.size > 1
          raise RuntimeError, 'More than one hinge connected to a hinge.'
        end

        if hinge.is_a? ActuatorHinge
          a_gap = true
          b_gap = false
          params = PRESETS::ACTUATOR_HINGE_OPENSCAD.dup

          intermediate_hinge = ExportHinge.new(node.id, "i" + a_other_node.id.to_s, "i" + b_other_node.id.to_s, l1.to_mm, l2.to_mm, l3_min.to_mm, l1.to_mm, l2.to_mm, l3_min.to_mm,
                                               PRESETS::ACTUATOR_HINGE_OPENSCAD_ANGLE, true, true, false, false, params)
          export_hinges.push(intermediate_hinge)

          if hinge.edge1.link_type == 'actuator'
            a_gap = false
            b_gap = true
            if other_a_hinges.size > 0
              a_gap = true
            end
            params['hole_size_a'] = PRESETS::ACTUATOR_HINGE_OPENSCAD_HOLE_SIZE
          else
            if other_b_hinges.size > 0
              b_gap = true
            end
            params['hole_size_b'] = PRESETS::ACTUATOR_HINGE_OPENSCAD_HOLE_SIZE
          end

          actuator_hinge = ExportHinge.new(node.id, "a" + a_other_node.id.to_s, "a" + b_other_node.id.to_s, l1.to_mm, l2.to_mm, l3_min.to_mm, l1.to_mm, l2.to_mm, l3_min.to_mm,
                                           PRESETS::ACTUATOR_HINGE_OPENSCAD_ANGLE, a_gap, b_gap, a_with_connector, b_with_connector, params)
          export_hinges.push(actuator_hinge)

          next
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

    hinge_algorithm.hubs.each do |node, hubs|
      hub_id = node.id

      i = 0
      hubs.each do |hub|
        is_main_hub = (i == 0)
        i += 1

        # TODO: consider sub hubs, currently they are ignored
        next unless is_main_hub

        export_hub = ExportHub.new(is_main_hub, hub_id)

        if is_main_hub
          node.pods.each do |pod|
            export_hub.add_pod(pod)
          end
        end

        hub.each do |edge|
          hinges = hinge_algorithm.hinges[node].select { |hinge| hinge.edge1 == edge or hinge.edge2 == edge }
          if hinges.size > 2
            raise RuntimeError, 'More than two hinges around an edge.'
          end

          elongation = edge.first_node?(node) ? edge.first_elongation_length : edge.second_elongation_length
          other_node = edge.other_node(node)
          direction = node.position.vector_to(other_node.position).normalize

          elongation_length = elongation
          is_hinge_connected = hinges.size > 0

          if is_hinge_connected
            elongation_length = hinge_algorithm.node_l1[node]
          end

          export_elongation = ExportElongation.new(hub_id, other_node.id, is_hinge_connected, elongation_length.to_mm, direction)
          export_hub.add_elongation(export_elongation)
        end

        export_hubs.push(export_hub)
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
  end
end
