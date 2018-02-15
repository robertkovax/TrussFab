require 'src/tools/hinge_analysis_tool'
require 'src/export/export_hinge'
require 'src/export/export_hub'
require 'src/export/export_elongation'
require 'src/export/export_cap'
require 'src/algorithms/relaxation.rb'
require 'src/export/presets.rb'

class ScadExport
  # we choose the first node to get the big hole size for the actuator
  def self.get_appropriate_actuator_hole_size(edge, node)
    if edge.first_node?(node)
      PRESETS::ACTUATOR_HINGE_OPENSCAD_HOLE_SIZE_BIG
    else
      PRESETS::ACTUATOR_HINGE_OPENSCAD_HOLE_SIZE_SMALL
    end
  end

  def self.create_export_hinges(hinges, node, l1, l2, l3_min)
    export_hinges = []
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

      elongation1 = hinge.edge1.first_node?(node) ? hinge.edge1.first_elongation_length : hinge.edge1.second_elongation_length
      elongation2 = hinge.edge2.first_node?(node) ? hinge.edge2.first_elongation_length : hinge.edge2.second_elongation_length

      a_l3 = elongation1 - l1 - l2
      b_l3 = elongation2 - l1 - l2

      if (a_l3 < l3_min || b_l3 < l3_min) && hinge.edge1.link_type != 'actuator' && hinge.edge2.link_type != 'actuator'
        raise RuntimeError, "Hinge l3 distance too small: #{a_l3.to_mm}, #{b_l3.to_mm}, #{l3_min.to_mm}."
      end

      # a parts always have connectors, b parts only if no other hinge connects to it
      a_with_connector = true
      b_with_connector = other_b_hinges.empty?
      a_gap = !other_a_hinges.empty?
      b_gap = !other_b_hinges.empty?

      params_first = PRESETS::ACTUATOR_HINGE_OPENSCAD.dup
      params_second = PRESETS::ACTUATOR_HINGE_OPENSCAD.dup

      if hinge.is_actuator_hinge
        if hinge.edge1.link_type == "actuator"
          a_with_connector = false
          params_first['hole_size_a'] = get_appropriate_actuator_hole_size(hinge.edge1, node)
        end

        if hinge.edge2.link_type == "actuator"
          b_with_connector = false
          params_second['hole_size_b'] = get_appropriate_actuator_hole_size(hinge.edge2, node)
        end

        first_hinge = ExportHinge.new(node.id, "i" + a_other_node.id.to_s, "i" + b_other_node.id.to_s, l1.to_mm, l2.to_mm, a_l3.to_mm, l1.to_mm, l2.to_mm, b_l3.to_mm,
                                      PRESETS::ACTUATOR_HINGE_OPENSCAD_ANGLE, a_gap, true, a_with_connector, false, params_first)
        second_hinge = ExportHinge.new(node.id, "i" + b_other_node.id.to_s, "a" + b_other_node.id.to_s, l1.to_mm, l2.to_mm, a_l3.to_mm, l1.to_mm, l2.to_mm, b_l3.to_mm,
                                       PRESETS::ACTUATOR_HINGE_OPENSCAD_ANGLE, true, b_gap, false, b_with_connector, params_second)

        export_hinges.push(first_hinge)
        export_hinges.push(second_hinge)
      else
        export_hinge = ExportHinge.new(node.id, a_other_node.id, b_other_node.id, l1.to_mm, l2.to_mm, a_l3.to_mm, l1.to_mm, l2.to_mm, b_l3.to_mm,
                                       hinge.angle, a_gap, b_gap, a_with_connector, b_with_connector, PRESETS::SIMPLE_HINGE_OPENSCAD)
        export_hinges.push(export_hinge)
      end
    end
    export_hinges
  end

  def self.create_export_hubs(hubs, hinges, l1, l2, node, hub_id)
    export_hubs = []
    i = 0

    hubs.each do |hub|
      is_main_hub = (i == 0)
      i += 1

      export_hub = is_main_hub ? ExportMainHub.new(hub_id, l1.to_mm) : ExportSubHub.new(hub_id, l1.to_mm)

      if is_main_hub
        node.pods.each do |pod|
          export_hub.add_pod(pod)
        end
      end

      hub.each do |edge|
        a_hinges = hinges.select { |hinge| hinge.edge1 == edge }
        b_hinges = hinges.select { |hinge| hinge.edge2 == edge }

        if a_hinges.size > 1 || b_hinges.size > 1
          raise RuntimeError, 'More than one A or B hinge around an edge.'
        end

        elongation = edge.first_node?(node) ? edge.first_elongation_length : edge.second_elongation_length
        other_node = edge.other_node(node)
        direction = node.position.vector_to(other_node.position).normalize

        hinge_connection = NO_HINGE

        if a_hinges.size > 0
          hinge_connection = A_HINGE
        end

        if b_hinges.size > 0
          hinge_connection = B_HINGE
        end

        if a_hinges.size > 0 && b_hinges.size > 0
          hinge_connection = A_B_HINGE
        end

        if export_hub.is_a?(ExportSubHub) && hinge_connection == A_B_HINGE
          raise RuntimeError, 'Subhub can not be connected to both A and B hinge'
        end

        l3 = elongation - l1 - l2

        export_elongation = ExportElongation.new(hub_id, other_node.id, hinge_connection, l1.to_mm, l2.to_mm, l3.to_mm, direction)
        export_hub.add_elongation(export_elongation)
      end

      export_hubs.push(export_hub)
    end
    export_hubs
  end

  def self.export_to_scad(path)
    hinge_algorithm = HingePlacementAlgorithm.instance
    hinge_algorithm.run

    export_hinges = []
    export_hubs = []

    l2 = PRESETS::SIMPLE_HINGE_RUBY['l2']
    l3_min = PRESETS::SIMPLE_HINGE_RUBY['l3_min']

    hinge_algorithm.hinges.each do |node, hinges|
      l1 = hinge_algorithm.node_l1[node]
      export_hinges.concat(create_export_hinges(hinges, node, l1, l2, l3_min))
    end

    hinge_algorithm.hubs.each do |node, hubs|
      hub_id = node.id
      l1 = hinge_algorithm.node_l1[node]
      if l1.nil?
        l1 = 0.0.mm
      end
      hinges = hinge_algorithm.hinges[node]
      export_hubs.concat(create_export_hubs(hubs, hinges, l1, l2, node, hub_id))
    end

    export_hinges.each do |hinge|
      hinge.write_to_file(path)
    end

    export_hubs.each do |hub|
      hub.write_to_file(path)
    end
  end
end
