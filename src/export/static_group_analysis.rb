# Find all substructures in the whole structure, that
# are static, i.e. there is no rotation happening inside
# them, when actuators are moving.
# This is done by running a physics simulation once per
# actuator and measuring which triangles rotated in regards
# to each other. Afterwards, a recursive walk through the
# structure determines all static groups.
module StaticGroupAnalysis

  public
  def StaticGroupAnalysis.find_static_groups
    edges = Graph.instance.edges.values
    actuators = edges.select { |e| e.link_type == 'actuator' }

    # Maps from a triangle to all triangles rotating with it around a common
    # axis
    rotation_partners = Hash.new { |h, k| h[k] = Set.new }

    actuators.each do |actuator|
      edges_without_actuator = actuator.connected_component.reject do |e|
        e == actuator
      end
      triangle_pairs = edges_without_actuator.flat_map do |e|
        valid_triangle_pairs(e, actuator)
      end

      original_angles = triangle_pair_angles(triangle_pairs)
      start_simulation(actuator)
      simulation_angles = triangle_pair_angles(triangle_pairs, true)

      process_triangle_pairs(triangle_pairs, original_angles,
                             simulation_angles,
                             rotation_partners)

      reset_simulation
    end

    start_static_group_search(edges.reject(&:dynamic?), rotation_partners)
  end

  private
  MIN_ANGLE_DEVIATION = 0.001

  # return a an array of groups of triangles that do not change their angle in
  # regards to each other
  # we call these groups rigid substructures
  def StaticGroupAnalysis.start_static_group_search(edges, rotation_partners)
    visited_triangles = Set.new
    groups = []

    triangles = Set.new(edges.flat_map(&:adjacent_triangles))
    triangles.reject!(&:dynamic?)

    loop do
      unvisited_tris = triangles - visited_triangles

      break if unvisited_tris.empty?

      triangle = unvisited_tris.to_a.sample
      new_group = Set.new

      recursive_static_group_search(triangle,
                                  new_group,
                                  visited_triangles,
                                  rotation_partners)

      groups.push(new_group)
    end

    groups
  end

  def StaticGroupAnalysis.recursive_static_group_search(triangle,
                                  group,
                                  visited_triangles,
                                  rotation_partners)
    visited_triangles.add(triangle)
    group.add(triangle)

    triangle.adjacent_triangles.reject(&:dynamic?).each do |other_triangle|
      is_visited = visited_triangles.include?(other_triangle)
      is_rotating = rotation_partners[triangle].include?(other_triangle)
      next if is_visited || is_rotating
      recursive_static_group_search(other_triangle,
                                  group,
                                  visited_triangles,
                                  rotation_partners)
    end
  end

  def StaticGroupAnalysis.valid_triangle_pairs(edge, actuator)
    edge.sorted_adjacent_triangle_pairs.select do |pair|
      pair.all? { |t| t.complete? && t.edges.none? { |e| e == actuator } }
    end
  end

  def StaticGroupAnalysis.simulation_triangle_normal(triangle)
    pos1 = triangle.first_node.thingy.body.get_position(1)
    pos2 = triangle.second_node.thingy.body.get_position(1)
    pos3 = triangle.third_node.thingy.body.get_position(1)
    vector1 = pos1.vector_to(pos2)
    vector2 = pos1.vector_to(pos3)
    vector1.cross(vector2)
  end

  def StaticGroupAnalysis.triangle_pair_angles(triangle_pairs, simulation = false)
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

  def StaticGroupAnalysis.angle_changed?(angle, other_angle)
    (angle - other_angle).abs > MIN_ANGLE_DEVIATION
  end

  def StaticGroupAnalysis.process_triangle_pairs(triangle_pairs,
                             original_angles,
                             simulation_angles,
                             partners)
    triangle_pairs.zip(original_angles, simulation_angles).each do |pair, oa, sa|
      if angle_changed?(oa, sa)
        partners[pair[0]].add(pair[1])
        partners[pair[1]].add(pair[0])
      end
    end
  end

  def StaticGroupAnalysis.start_simulation(edge)
    @simulation = Simulation.new
    @simulation.setup
    @simulation.disable_gravity
    piston = edge.thingy.joint
    # don't extend all the way in order not to break structure
    # TODO: find a better way to extend actuator without breaking structure
    piston.controller = edge.thingy.max / 4.0 if piston
    @simulation.start
    @simulation.update_world_headless_by(2)
  end

  def StaticGroupAnalysis.reset_simulation
    @simulation.reset
    @simulation = nil
  end
end
