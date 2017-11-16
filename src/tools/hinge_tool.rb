require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/ball_joint_simulation.rb'
require 'src/algorithms/rigidity_tester.rb'
require 'src/simulation/joints'
require 'src/simulation/thingy_rotation'

class HingeTool < Tool

  MIN_ANGLE_DEVIATION = 0.05

  def activate
    edges = Graph.instance.edges.values

    edges.each do |edge|
      edge.reset
    end

    actuators = edges.reject { |e| e.link_type != 'actuator' }

    # Maps from a rotation axis to all triangles rotating around it
    rotation_axis_to_tris = Hash.new { |h,k| h[k] = Set.new }
    # Maps from a triangle to all triangles rotating with it around a common axis
    rotation_partners = Hash.new { |h,k| h[k] = Set.new }
    # List with set of hinge choices
    hinge_choices = []

    actuators.each do |actuator|
      edges_without_actuator = actuator.connected_component.reject { |e| e == actuator }
      triangle_pairs = edges_without_actuator.flat_map { |e| valid_triangle_pairs(e, actuator) }

      original_angles = triangle_pair_angles(triangle_pairs)
      start_simulation(actuator)
      simulation_angles = triangle_pair_angles(triangle_pairs, true)

      process_triangle_pairs(triangle_pairs, original_angles, simulation_angles, rotation_axis_to_tris, rotation_partners)

      reset_simulation
    end

    static_groups = find_rigid_substructures(edges.reject { |e| e.link_type == 'actuator' }, rotation_partners)
    #static_groups = add_actuator_triangles(static_groups, actuators)
    static_groups.each do |group|
      color_group(group)
    end

    rotation_axis_to_group = Hash.new { |h,k| h[k] = Set.new }

    group_combinations = static_groups.combination(2)
    group_combinations.each do |pair|
      group1_edges = Set.new pair[0].flat_map { |tri| tri.edges }
      group2_edges = Set.new pair[1].flat_map { |tri| tri.edges }

      common_edges = group1_edges & group2_edges
      if common_edges.size > 1
        p "Logic error: More than one common edge."
      end

      if common_edges.size > 0 and common_edges.to_a[0].link_type != 'actuator'
        rotation_axis_to_group[common_edges.to_a[0]].add(pair[0])
        rotation_axis_to_group[common_edges.to_a[0]].add(pair[1])
      end
    end

    # color rotation axes differently
    rotation_axis_to_group.keys.each do |rotation_axis|
      color_rotation_axis(rotation_axis)
    end

    hinges = 0

    rotation_axis_to_group.each do |axis, groups|
      sorted_groups = groups.sort { |a,b| a.size <=> b.size }
      # Removes the biggest group rotating around the axis, this can be considered the static group around the axis
      sorted_groups.pop

      sorted_groups.each do |group|
        adjacent_tris = group.select { |tri| tri.edges.include?(axis) }

        # hinge_possible = false

        hinge_choices.push([axis, adjacent_tris])

        # adjacent_tris.each do |tri|
        #   #if can_add_hinge?(axis, tri)
        #     (tri.edges - [axis]).each do |edge|
        #       unless add_hinge(axis, edge)
        #         p "Logic error: hinge placed despite can_add_hinge? false"
        #       end
        #     end
        #     hinge_possible = true
        #     hinges += 1
        #     break
        #  #end
        # end

        # if not hinge_possible
        #   p "Logic Error: hinge could not be placed."
        # end
      end
    end

    hinge_choices.each do |hinge_choice|
      rotation_axis = hinge_choice[0]
      possible_tris = hinge_choice[1]

      possible_tris.each do |tri|
        (tri.edges - [rotation_axis]).each do |edge|
          unless add_hinge(rotation_axis, edge)
            p "Logic error: hinge placed despite can_add_hinge? false"
          end
        end
        hinges += 1
        break
      end

      possible_tris.each do |tri|
        (tri.edges - [rotation_axis]).each do |edge|
          node = edge.shared_node(rotation_axis)
          add_elongation(edge, node)
        end
      end
    end

    p "num_hinges: " + hinges.to_s
  end

  def find_rigid_substructures(edges, rotation_partners)
    visited_tris = Set.new
    groups = []

    tris = Set.new edges.flat_map { |e| e.adjacent_triangles }
    tris.reject! { |t| t.contains_actuator? }

    loop do
      unvisited_tris = tris - visited_tris

      if unvisited_tris.empty?
        break
      end

      tri = unvisited_tris.to_a.sample
      new_group = Set.new

      recursive_find_substructure(tri, new_group, visited_tris, rotation_partners)

      groups.push(new_group)
    end

    groups
  end

  def recursive_find_substructure(tri, group, visited_tris, rotation_partners)
    visited_tris.add(tri)
    group.add(tri)

    tri.adjacent_triangles.reject { |t| t.contains_actuator? }.each do |other_tri|
      is_visited = visited_tris.include?(other_tri)
      is_rotating = rotation_partners[tri].include?(other_tri)
      if not is_visited and not is_rotating
        recursive_find_substructure(other_tri, group, visited_tris, rotation_partners)
      end
    end
  end

  def add_actuator_triangles(groups, actuators)
    actuators.each do |actuator|
      actuator.adjacent_triangles.each do |triangle|
        group = Set.new
        group.add(triangle)
        groups.push(group)
      end
    end

    groups
  end

  def color_group(group)
    if group.length == 1
      return
    end

    group_color = "%06x" % (rand * 0xffffff)

    group.each do |triangle|
      triangle.edges.each do |edge|
        edge.thingy.change_color(group_color)
      end
    end
  end

  def color_rotation_axis(axis)
    axis.thingy.change_color("%06x" % 0x000000)
  end

  def can_add_hinge?(rotation_axis, triangle)
    (triangle.edges - [rotation_axis]).each do |edge|
      node = rotation_axis.shared_node(edge)

      # other_joint = rotation_axis.first_node?(node) ? rotation_axis.thingy.first_joint : rotation_axis.thingy.second_joint
      # if other_joint.is_a? ThingyHinge and other_joint.rotates_around?(edge)
      #   return true
      # end

      joint = edge.first_node?(node) ? edge.thingy.first_joint : edge.thingy.second_joint
      if joint.is_a? ThingyHinge
        return false
      end
    end

    true
  end

  def add_elongation(rotating_edge, node)
    if rotating_edge.first_node?(node)
      rotating_edge.thingy.shorten_elongation(true)
    else
      rotating_edge.thingy.shorten_elongation(false)
    end
  end

  def add_hinge(rotation_axis, rotating_edge)
    rotation = EdgeRotation.new(rotation_axis)
    node = rotating_edge.shared_node(rotation_axis)
    hinge = ThingyHinge.new(node, rotation)

    # other_joint = rotation_axis.first_node?(node) ? rotation_axis.thingy.first_joint : rotation_axis.thingy.second_joint
    # if other_joint.is_a? ThingyHinge and other_joint.rotates_around?(rotating_edge)
    #   return true
    # end

    if rotating_edge.first_node?(node)
      # if rotating_edge.thingy.first_joint.is_a? ThingyHinge
      #   return false
      # end
      rotating_edge.thingy.first_joint = hinge
    else
      # if rotating_edge.thingy.second_joint.is_a? ThingyHinge
      #   return false
      # end
      rotating_edge.thingy.second_joint = hinge
    end

    # Draw hinge visualization
    help_point = Geom::Point3d.linear_combination(0.7, node.position, 0.3, rotation_axis.mid_point)
    starting_point = Geom::Point3d.linear_combination(0.7, node.position, 0.3, rotating_edge.mid_point)
    mid_point = Geom::Point3d.linear_combination(0.3, starting_point, 0.7, help_point)
    end_point = Geom::Point3d.linear_combination(0.7, mid_point, 0.3, rotation_axis.mid_point)

    line1 = Line.new(starting_point, mid_point, HINGE_LINE)
    line2 = Line.new(mid_point, end_point, HINGE_LINE)

    rotating_edge.thingy.add(line1, line2)

    true
  end

  def start_simulation(edge)
    @simulation = BallJointSimulation.new
    @simulation.setup
    @simulation.disable_gravity
    piston = edge.thingy.piston
    piston.controller = 0.4
    @simulation.start
    @simulation.update_world_by(2)
  end

  def reset_simulation
    @simulation.stop
    @simulation = nil
  end

  def valid_triangle_pairs(edge, actuator)
    edge.sorted_adjacent_triangle_pairs.select do |pair|
      pair.all? { |t| t.complete? && !t.edges.any? { |e| e == actuator } }
    end
  end

  def simulation_triangle_normal(t)
    pos1 = t.first_node.thingy.body.get_position(1)
    pos2 = t.second_node.thingy.body.get_position(1)
    pos3 = t.third_node.thingy.body.get_position(1)
    vector1 = pos1.vector_to(pos2)
    vector2 = pos1.vector_to(pos3)
    vector1.cross(vector2)
  end

  def triangle_pair_angles(triangle_pairs, simulation = false)
    triangle_pairs.map do |t1, t2|
      if simulation
        n1 = simulation_triangle_normal(t1)
        n2 = simulation_triangle_normal(t2)
        n1.angle_between(n2)
      else
        t1.angle_between(t2)
      end
    end
  end

  def angle_changed?(angle, other_angle)
    (angle - other_angle).abs > MIN_ANGLE_DEVIATION
  end

  def process_triangle_pairs(triangle_pairs, original_angles, simulation_angles, hash, partners)
    triangle_pairs.zip(original_angles, simulation_angles).each do |pair, oa, sa|
      if angle_changed?(oa, sa)
        rotation_axis = pair[0].shared_edge(pair[1])
        hash[rotation_axis].add(pair[0])
        hash[rotation_axis].add(pair[1])
        partners[pair[0]].add(pair[1])
        partners[pair[1]].add(pair[0])
      end
    end
  end

end
