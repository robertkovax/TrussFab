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
    static_groups.sort! { |a,b| b.size <=> a.size }
    static_groups.reverse.each do |group|
      color_group(group)
    end

    group_rotations = Hash.new { |h,k| h[k] = Set.new }

    group_combinations = static_groups.combination(2)
    group_combinations.each do |pair|
      group1_edges = Set.new pair[0].flat_map { |tri| tri.edges }
      group2_edges = Set.new pair[1].flat_map { |tri| tri.edges }

      common_edges = group1_edges & group2_edges
      if common_edges.size > 1
        p "Logic error: More than one common edge."
      end

      if common_edges.size > 0 and common_edges.to_a[0].link_type != 'actuator'
        group_rotations[pair[1]].add(pair[0])
        group_rotations[pair[0]].add(pair[1])
      end
    end

    hinges = Set.new

    static_groups.each do |group|
      other_groups = group_rotations[group].select { |other_group| group.size >= other_group.size }

      group1_edges = Set.new group.flat_map { |tri| tri.edges }

      other_groups.each do |other_group|
        group2_edges = Set.new other_group.flat_map { |tri| tri.edges }
        axis = (group1_edges & group2_edges).to_a[0]

        group1_adjacent_tris = group.select { |tri| tri.edges.include? axis }
        group2_adjacent_tris = other_group.select { |tri| tri.edges.include? axis }

        # TODO: clear up if connection must be on same group
        next if group_hinges_around_axis?(hinges, group1_adjacent_tris, axis)
        next if group_hinges_around_axis?(hinges, group2_adjacent_tris, axis)

        hinging_tri = group2_adjacent_tris.sample
        (hinging_tri.edges - [axis]).each do |edge|
          hinges.add(Set.new [edge, axis])
        end
      end
    end

    hinges.each do |pair|
      axes = pair.to_a
      add_hinge(axes[0], axes[1])
    end
  end

  def group_hinges_around_axis?(hinges, group, axis)
    side1_edges = group.flat_map { |tri| tri.edges }.select { |edge| edge.nodes.include? axis.first_node }
    side1_hinges = side1_edges.any? { |edge| hinges.include? Set.new [edge, axis] }

    side2_edges = group.flat_map { |tri| tri.edges }.select { |edge| edge.nodes.include? axis.second_node }
    side2_hinges = side2_edges.any? { |edge| hinges.include? Set.new [edge, axis] }

    side1_hinges and side2_hinges
  end

  def hinges_around?(hinge_map, rotating_edge, rotation_axis)
    hinge_map[rotating_edge].include? rotation_axis
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

    if rotating_edge.first_node?(node)
      rotating_edge.thingy.first_joint = hinge
    else
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
