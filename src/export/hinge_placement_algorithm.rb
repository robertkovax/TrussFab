require 'singleton'
require 'src/simulation/simulation.rb'
require 'src/algorithms/rigidity_tester.rb'

class Hinge
  attr_accessor :edge1, :edge2, :is_actuator_hinge

  def initialize(edge1, edge2)
    raise 'Edges have to be different.' if edge1 == edge2
    @edge1 = edge1
    @edge2 = edge2
    # For historical reasons this is still called 'actuator hinge'.
    # Actionally it is an 'double hinge' and gets used in other scenarios as well (e.g. subhubs).
    @is_actuator_hinge = false
  end

  def inspect
    "#{@edge1.inspect} #{@edge2.inspect} #{@is_actuator_hinge}"
  end

  def hash
    self.class.hash ^ @edge1.hash ^ @edge2.hash
  end

  def eql?(other)
    hash == other.hash
  end

  def common_edge(other)
    common_edges = [edge1, edge2] & [other.edge1, other.edge2]
    raise 'Too many or no common edges.' if common_edges.size != 1
    common_edges[0]
  end

  def connected_with?(other)
    common_edges = [edge1, edge2] & [other.edge1, other.edge2]
    common_edges.size > 0
  end

  def num_connected_hinges(hinges)
    hinges.select { |other| !eql?(other) && connected_with?(other) }.size
  end

  def edges
    [@edge1, @edge2]
  end

  def swap_edges
    @edge1, @edge2 = @edge2, @edge1
  end

  def angle
    val = @edge1.direction.angle_between(@edge2.direction)
    val = 180 / Math::PI * val
    val = 180 - val if val > 90

    raise 'Angle between edges not between 0° and 90°.' unless val > 0 && val <= 90

    val
  end

  def l1
    p1_x = 30
    p1_y = 60

    p2_x = 90
    p2_y = 20

    m = (p2_y - p1_y) / (p2_x - p1_x)
    b = p1_y - m * p1_x

    length = m * angle + b
    min_length = @is_actuator_hinge ? PRESETS::MINIMUM_ACTUATOR_L1 : PRESETS::MINIMUM_L1
    length = [min_length, length].max

    length.mm
  end
end

class HingePlacementAlgorithm
  include Singleton

  attr_accessor :hubs, :hinges, :node_l1

  def initialize
    # maps from a node to an array of all subhubs around this node, ordered by size of the subhub
    @hubs = nil
    # maps from a node to an array of all hinges around this node
    @hinges = nil
    # maps from a node to the l1 distance, that all hubs and hinges around this node must have
    @node_l1 = nil
  end

  MIN_ANGLE_DEVIATION = 0.001

  def run
    nodes = Graph.instance.nodes.values
    edges = Graph.instance.edges.values

    edges.each(&:reset)

    actuators = edges.select { |e| e.link_type == 'actuator' }

    # Maps from a triangle to all triangles rotating with it around a common axis
    rotation_partners = Hash.new { |h, k| h[k] = Set.new }

    actuators.each do |actuator|
      edges_without_actuator = actuator.connected_component.reject { |e| e == actuator }
      triangle_pairs = edges_without_actuator.flat_map { |e| valid_triangle_pairs(e, actuator) }

      original_angles = triangle_pair_angles(triangle_pairs)
      start_simulation(actuator)
      simulation_angles = triangle_pair_angles(triangle_pairs, true)

      process_triangle_pairs(triangle_pairs, original_angles, simulation_angles, rotation_partners)

      reset_simulation
    end

    static_groups = find_rigid_substructures(edges.reject { |e| e.link_type == 'actuator' }, rotation_partners)
    static_groups.select! { |group| group.size > 1 }
    static_groups.sort! { |a,b| b.size <=> a.size }
    static_groups = prioritise_pod_groups(static_groups)

    group_rotations = Hash.new { |h,k| h[k] = Set.new }

    group_combinations = static_groups.combination(2)
    group_combinations.each do |pair|
      group1_edges = Set.new pair[0].flat_map { |tri| tri.edges }
      group2_edges = Set.new pair[1].flat_map { |tri| tri.edges }

      common_edges = group1_edges & group2_edges

      raise 'More than one common edge.' if common_edges.size > 1

      if common_edges.size > 0 && common_edges.to_a[0].link_type != 'actuator'
        group_rotations[pair[1]].add(pair[0])
        group_rotations[pair[0]].add(pair[1])
      end
    end

    hinges = Set.new
    hubs = Hash.new { |h, k| h[k] = [] }
    group_edge_map = {}

    # generate hubs for all groups with size > 1
    processed_edges = Set.new
    static_groups.each do |group|
      group_nodes = Set.new group.flat_map { |tri| tri.nodes }
      group_edges = Set.new group.flat_map { |tri| tri.edges }
      group_edges = group_edges - processed_edges

      group_edge_map[group] = group_edges

      group_nodes.each do |node|
        hub_edges = group_edges.select { |edge| edge.nodes.include? node }
        if hub_edges.size == 2
          hinges.add(Hinge.new(hub_edges[0], hub_edges[1]))
        else
          hubs[node].push(hub_edges)
        end
      end

      processed_edges = processed_edges.merge(group_edges)
    end

    # put hinges everywhere possible
    triangles = Set.new edges.flat_map { |edge| edge.adjacent_triangles }

    triangles.each do |tri|
      tri.edges.combination(2).each do |e1, e2|
        same_group = static_groups.any? { |group| group_edge_map[group].include?(e1) && group_edge_map[group].include?(e2) }

        next if same_group

        new_hinge = Hinge.new(e1, e2)
        new_hinge.is_actuator_hinge = tri.contains_actuator?
        hinges.add(new_hinge)
      end
    end

    # TODO: make hinges a hub, if a pod exists at node and there is no other hub

    # place all hinges to the node which they rotate around
    hinge_map = Hash.new { |h, k| h[k] = [] }
    hinges.each do |hinge|
      node = hinge.edge1.shared_node(hinge.edge2)
      hinge_map[node].push(hinge)
    end

    Sketchup.active_model.start_operation('find hinges')
    # remove hinges that are superfluous, i.e. they connect to an edge that already has two other hinges
    hinge_map.each { |node, hinges|
      new_hinges = hinges.clone

      loop do
        # save how many hinges each hinge shares an edge with around the current node
        # if it is more than 2, one of them needs to be removed
        shared_hinges_count = {}
        new_hinges.each do |hinge|
          shared_hinges = new_hinges.select { |other_hinge| hinge != other_hinge && (hinge.edges & other_hinge.edges).size > 0 }
          shared_hinges_count[hinge] = shared_hinges.size
        end

        violating_hinges = shared_hinges_count.keys.select { |hinge| shared_hinges_count[hinge] >= 3 && hinge_connects_to_groups(group_edge_map, hinge, 2) }
        violating_hinges.concat(shared_hinges_count.keys.select { |hinge| shared_hinges_count[hinge] >= 3 && hinge_connects_to_groups(group_edge_map, hinge, 1) })
        violating_hinges.concat(shared_hinges_count.keys.select { |hinge| shared_hinges_count[hinge] >= 3 })
        violating_hinges.concat(shared_hinges_count.keys.select { |hinge| shared_hinges_count[hinge] == 2 && hinge.is_actuator_hinge && hinge.edge1.link_type != 'actuator' && hinge.edge2.link_type != 'actuator' })
        violating_hinges.concat(shared_hinges_count.keys.select { |hinge| shared_hinges_count[hinge] == 2 && hinge_connects_to_groups(group_edge_map, hinge, 2) })
        violating_hinges.concat(shared_hinges_count.keys.select { |hinge| shared_hinges_count[hinge] == 1 && hinge_connects_to_groups(group_edge_map, hinge, 2) })

        break if violating_hinges.empty?

        new_hinges.delete(violating_hinges.first)
      end

      hinge_map[node] = new_hinges
    }

    hinge_map = order_hinges(hinge_map)
    Sketchup.active_model.commit_operation

    @hubs = hubs
    @hinges = hinge_map

    # stores the l1 value per node (since it needs to be constant across a node)
    @node_l1 = {}

    @hinges.each do |node, hinges|
      max_l1 = 0.0.mm

      hinges.each do |hinge|
        max_l1 = [max_l1, hinge.l1].max
      end

      # also set l1 distance for node if it contains a subhub
      node_hubs = @hubs[node]
      minimum_subhub_l1 = PRESETS::MINIMUM_L1
      max_l1 = [max_l1, minimum_subhub_l1.mm].max if node_hubs.size > 1

      @node_l1[node] = max_l1
    end

    Sketchup.active_model.start_operation('elongate edges', true)
    elongate_edges unless @hinges.empty?
    Sketchup.active_model.commit_operation

    # add visualisations

    # shorten elongations for all edges that are not part of the main hub
    nodes.each do |node|
      main_hub = hubs[node][0]

      node_edges = edges.select { |edge| edge.nodes.include? node && edge.link_type != 'actuator' }
      node_edges.each do |edge|
        if main_hub.nil? || !main_hub.include?(edge)
          add_elongation(edge, node)
        end
      end
    end

    @hinges.each do |node, hinges|
      hinges.each do |hinge|
        visualize_hinge(hinge)
      end
    end

    static_groups.reverse.each do |group|
      color_group(group)
    end
  end

  def hinge_connects_to_groups(group_edge_map, hinge, num_groups = 1)
    include_edge1 = group_edge_map.select { |k, edges| edges.include? hinge.edge1 }.keys
    include_edge2 = group_edge_map.select { |k, edges| edges.include? hinge.edge2 }.keys

    if num_groups == 1
      return include_edge1.size > 0 || include_edge2.size > 0
    elsif num_groups == 2
      return include_edge1.size > 0 && include_edge2.size > 0 && !include_edge1[0].eql?(include_edge2[0])
    end

    raise 'Hinge can connect to maximally two groups.'
  end

  # make sure that edge1 is the unconnected one if there is one
  def align_first_hinge(hinges, cur_hinge)
    other_edges = (hinges - [cur_hinge]).flat_map { |hinge| [hinge.edge1, hinge.edge2] }
    cur_hinge.swap_edges unless other_edges.include? cur_hinge.edge2
  end

  # orders hinges so that they form a chain
  # also always puts the edge connected to the former hinge as edge1
  def order_hinges(hinge_map)
    result = Hash.new { |h,k| h[k] = [] }

    hinge_map.each do |node, hinges|
      sorted_hinges = hinges.sort { |h1, h2| h1.num_connected_hinges(hinges) <=> h2.num_connected_hinges(hinges) }
      cur_hinge = sorted_hinges[0]
      align_first_hinge(hinges, cur_hinge)

      new_hinges = []
      first = true

      while new_hinges.size < hinges.size
        new_hinges.push(cur_hinge)

        break if new_hinges.size == hinges.size

        next_hinge_possibilities = hinges.select { |hinge| hinge.connected_with?(cur_hinge) && !new_hinges.include?(hinge) }
        if next_hinge_possibilities.empty?
          remaining_hinges = sorted_hinges - new_hinges
          cur_hinge = remaining_hinges[0]
          align_first_hinge(hinges, cur_hinge)
          next
        end

        if !first && next_hinge_possibilities.size > 1
          raise 'More than one next hinge possible around hinge at node ' + node.id.to_s
        elsif first && next_hinge_possibilities.size > 2
          raise 'More than two next hinges possible around starting hinge at node ' + node.id.to_s
        end

        if cur_hinge.common_edge(next_hinge_possibilities[0]) != next_hinge_possibilities[0].edge1
          next_hinge_possibilities[0].swap_edges
        end
        cur_hinge = next_hinge_possibilities[0]

        first = false
      end

      result[node] = new_hinges
    end

    result
  end

  # return a an array of groups of triangles that do not change their angle in regards to each other
  # we call these groups rigid substructures
  def find_rigid_substructures(edges, rotation_partners)
    visited_triangles = Set.new
    groups = []

    triangles = Set.new edges.flat_map { |e| e.adjacent_triangles }
    triangles.reject! { |t| t.contains_actuator? }

    loop do
      unvisited_tris = triangles - visited_triangles

      break if unvisited_tris.empty?

      triangle = unvisited_tris.to_a.sample
      new_group = Set.new

      recursive_find_substructure(triangle, new_group, visited_triangles, rotation_partners)

      groups.push(new_group)
    end

    groups
  end

  def recursive_find_substructure(triangle, group, visited_triangles, rotation_partners)
    visited_triangles.add(triangle)
    group.add(triangle)

    triangle.adjacent_triangles.reject { |t| t.contains_actuator? }.each do |other_triangle|
      is_visited = visited_triangles.include?(other_triangle)
      is_rotating = rotation_partners[triangle].include?(other_triangle)
      if !is_visited && !is_rotating
        recursive_find_substructure(other_triangle, group, visited_triangles, rotation_partners)
      end
    end
  end

  def color_group(group)
    return if group.length == 1

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

  def visualize_hinge(hinge)
    rotation_axis = hinge.edge1
    rotating_edge = hinge.edge2
    node = rotating_edge.shared_node(rotation_axis)

    mid_point1 = Geom::Point3d.linear_combination(0.7, node.position, 0.3, rotation_axis.mid_point)
    mid_point2 = Geom::Point3d.linear_combination(0.7, node.position, 0.3, rotating_edge.mid_point)

    # Draw hinge visualization
    mid_point = Geom::Point3d.linear_combination(0.5, mid_point2, 0.5, mid_point1)

    if hinge.is_actuator_hinge
      mid_point = Geom::Point3d.linear_combination(0.75, mid_point, 0.25, node.position)
    end

    line1 = Line.new(mid_point, mid_point1, HINGE_LINE)
    line2 = Line.new(mid_point, mid_point2, HINGE_LINE)

    rotating_edge.thingy.add(line1, line2)
  end

  def start_simulation(edge)
    @simulation = Simulation.new
    @simulation.setup
    @simulation.disable_gravity
    piston = edge.thingy.joint
    piston.controller = edge.thingy.max if piston
    @simulation.start
    @simulation.update_world_headless_by(2)
  end

  def reset_simulation
    @simulation.reset
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

  def process_triangle_pairs(triangle_pairs, original_angles, simulation_angles, partners)
    triangle_pairs.zip(original_angles, simulation_angles).each do |pair, oa, sa|
      if angle_changed?(oa, sa)
        partners[pair[0]].add(pair[1])
        partners[pair[1]].add(pair[0])
      end
    end
  end

  def prioritise_pod_groups(groups)
    pod_groups = groups.select { |group| group.any? { |tri| tri.nodes.all? { |node| node.thingy.pods? } } }
    pod_groups + (groups - pod_groups)
  end

  # return all edges that need to be elongated and the node at which the elongation should occur
  def get_elongation_tuple
    result = []

    @hinges.each do |node, hinges|
      hinges.each do |hinge|
        result.push([node, hinge.edge1])
        result.push([node, hinge.edge2])
      end
    end

    @hubs.each do |node, hubs|
      hubs.drop(1).each do |hub_edges|
        hub_edges.each do |edge|
          result.push([node, edge])
        end
      end
    end

    result.reject! { |_, edge| edge.link_type == 'actuator' }

    result
  end

  def elongate_edges
    l2 = PRESETS::L2
    l3_min = PRESETS::SIMPLE_HINGE_RUBY['l3_min']

    elongation_tuple = get_elongation_tuple

    loop do
      relaxation = Relaxation.new

      is_finished = true

      elongation_tuple.each do |node, edge|
        l1 = @node_l1[node]

        if edge.nodes.any? { |node| node.pod_directions.size > 0 }
          raise 'Hinge is connected to edge that has a pod.'
        end

        elongation = edge.first_node?(node) ? edge.first_elongation_length : edge.second_elongation_length
        target_elongation = l1 + l2 + l3_min

        next unless elongation < target_elongation

        total_elongation = edge.first_elongation_length + edge.second_elongation_length
        relaxation.stretch_to(edge, edge.length - total_elongation + 2*target_elongation + 10.mm)
        is_finished = false
      end

      break if is_finished

      relaxation.relax
    end
  end

end
