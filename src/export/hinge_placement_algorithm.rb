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
    common_edges = edges & other.edges
    raise 'Too many or no common edges.' if common_edges.size != 1
    common_edges[0]
  end

  def connected_with?(other)
    common_edges = edges & other.edges
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
    @is_actuator_hinge ? PRESETS::MINIMUM_ACTUATOR_L1 : PRESETS::MINIMUM_L1
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

    static_groups = find_rigid_substructures(edges.reject { |e| e.is_dynamic? }, rotation_partners)
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

      if common_edges.size > 0 && common_edges.to_a[0].is_dynamic?
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
        new_hinge.is_actuator_hinge = tri.is_dynamic?
        hinges.add(new_hinge)
      end
    end

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
        # if it is more than one hinge at either connection, hinges need to be removed
        shared_a_hinge_count = {}
        shared_b_hinge_count = {}

        new_hinges.each do |hinge|
          shared_hinges_a = new_hinges.select { |other_hinge| hinge != other_hinge && other_hinge.edges.include?(hinge.edge1) }
          shared_a_hinge_count[hinge] = shared_hinges_a.size

          shared_hinges_b = new_hinges.select { |other_hinge| hinge != other_hinge && other_hinge.edges.include?(hinge.edge2) }
          shared_b_hinge_count[hinge] = shared_hinges_b.size
        end

        valid_result = new_hinges.all? { |hinge| shared_a_hinge_count[hinge] <= 1 && shared_b_hinge_count[hinge] <= 1 }
        break if valid_result

        # assign values to hinges that states how likely it is to be removed
        # the higher number the number, the more problematic is a hinge
        hinge_values = []
        new_hinges.each do |hinge|
          connects_actuator = hinge.edge1.is_dynamic? || hinge.edge2.is_dynamic?

          val = 0
          val += shared_a_hinge_count[hinge] - 1 if shared_a_hinge_count[hinge] > 1
          val += shared_b_hinge_count[hinge] - 1 if shared_b_hinge_count[hinge] > 1
          val += 1 if hinge.is_actuator_hinge && !connects_actuator
          #val -= 1 if hinge.is_actuator_hinge && connects_actuator
          val += 1 if hinge_connects_to_groups(group_edge_map, hinge, 2)

          hinge_values.push([hinge, val])
        end

        hinge_values.sort! { |a, b| b[1] <=> a[1] }
        new_hinges.delete(hinge_values.first[0])
      end

      # check that all subhubs are only connected to at most one hinge
      # remove hinges if there are more than one, starting with double hinges
      hubs[node].drop(1).each do |edges|
        edges.each do |edge|
          edge_hinges = new_hinges.select { |hinge| hinge.edges.include?(edge) }
          edge_hinges.sort_by! { |hinge| hinge.is_actuator_hinge ? 0 : 1 }

          while edge_hinges.size > 1
            new_hinges.delete(edge_hinges.first)
            edge_hinges.delete(edge_hinges.first)
          end
        end
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
      main_hub = @hubs[node][0]

      node_edges = edges.select { |edge| edge.nodes.include?(node) && edge.link_type != 'actuator' }
      node_edges.each do |edge|
        if main_hub.nil? || !main_hub.include?(edge)
          disconnect_edge_from_hub(edge, node)
        end
      end
    end

    @hinges.each do |node, hinges|
      hinges.each do |hinge|
        visualize_hinge(hinge)
      end
    end

    group_nr = 0
    static_groups.reverse.each do |group|
      if group.length == 1
        color_triangle(group)
        next
      end
      color_group(group, group_nr)
      group_nr += 1
    end

    hinge_layer = Sketchup.active_model.layers.at(Configuration::HINGE_VIEW)
    hinge_layer.visible = true
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

    is_edge1_connected = other_edges.include? cur_hinge.edge1
    is_edge2_connected = other_edges.include? cur_hinge.edge2

    raise 'Hinge is not connected to any other hinge' if !is_edge1_connected && !is_edge2_connected

    if is_edge1_connected && !is_edge2_connected
      cur_hinge.swap_edges
    end
  end

  # get the hinge that is connected to the least number of other hinges
  # this will be the start of the chain
  def get_first_hinge(hinges)
    sorted_hinges = hinges.sort { |h1, h2| h1.num_connected_hinges(hinges) <=> h2.num_connected_hinges(hinges) }
    sorted_hinges[0]
  end

  # orders hinges so that they form a chain:
  # the result will be arrays of hinges, where edge2 of a hinge and edge1
  # of the following hinge match, if they are connected
  def order_hinges(hinge_map)
    result = Hash.new { |h,k| h[k] = [] }

    hinge_map.each do |node, hinges|
      cur_hinge = get_first_hinge(hinges)
      if cur_hinge.num_connected_hinges(hinges) > 0
        align_first_hinge(hinges, cur_hinge)
      end

      new_hinges = []

      while new_hinges.size < hinges.size
        new_hinges.push(cur_hinge)

        break if new_hinges.size == hinges.size

        # check which hinges can connect to the current hinge B part
        next_hinge_possibilities = hinges.select { |hinge| hinge.edges.include?(cur_hinge.edge2) && !new_hinges.include?(hinge) }
        if next_hinge_possibilities.size > 1
          raise 'More than one next hinge can be connected at node ' + node.id.to_s
        end

        if next_hinge_possibilities.empty?
          remaining_hinges = hinges - new_hinges
          cur_hinge = get_first_hinge(remaining_hinges)
          if cur_hinge.num_connected_hinges(remaining_hinges) > 0
            align_first_hinge(remaining_hinges, cur_hinge)
          end

          next
        end

        next_hinge = next_hinge_possibilities[0]

        # make sure that B part of current hinge connects to A part of next hinge
        if cur_hinge.edge2 != next_hinge.edge1
          next_hinge.swap_edges
        end
        cur_hinge = next_hinge
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
    triangles.reject! { |t| t.is_dynamic? }

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

    triangle.adjacent_triangles.reject { |t| t.is_dynamic? }.each do |other_triangle|
      is_visited = visited_triangles.include?(other_triangle)
      is_rotating = rotation_partners[triangle].include?(other_triangle)
      if !is_visited && !is_rotating
        recursive_find_substructure(other_triangle, group, visited_triangles, rotation_partners)
      end
    end
  end

  def color_group(group, group_nr)
    case group_nr
      when 0
        group_color = "1f78b4" # dark blue
      when 1
        group_color = "e31a1c" # dark red
      when 2
        group_color = "ff7f00" # dark orange
      when 3
        group_color = "984ea3" # purple
      when 4
        group_color = "a65628" # brown
      when 5
        group_color = "a6cee3" # light blue
      when 6
        group_color = "e78ac3" # pink
      when 7
        group_color = "fdbf6f" # light orange
      else
        group_color = "%06x" % (rand * 0xffffff)
    end

    group.each do |triangle|
      triangle.edges.each do |edge|
        edge.thingy.change_color(group_color)
      end
    end
  end

  def disconnect_edge_from_hub(rotating_edge, node)
    if rotating_edge.first_node?(node)
      rotating_edge.thingy.disconnect_from_hub(true)
    else
      rotating_edge.thingy.disconnect_from_hub(false)
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
    # don't extend all the way in order not to break structure
    # TODO: find a better way to extend actuator without breaking structure
    piston.controller = edge.thingy.max / 4.0 if piston
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

    result.reject! { |_, edge| edge.is_dynamic? }

    result
  end

  def elongate_edges
    Edge.enable_bottle_freeze

    l2 = PRESETS::L2
    l3_min = PRESETS::L3_MIN

    elongation_tuple = get_elongation_tuple

    loop do
      relaxation = Relaxation.new

      is_finished = true

      elongation_tuple.each do |node, edge|
        l1 = @node_l1[node]

        # if pods are fixed and edge can not be elongated, raise error
        edge_fixed = edge.nodes.any? { |node| node.fixed? }
        if edge_fixed
          raise "#{edge.inspect} is fixed, e.g. by a pod, but needs to be elongated since a hinge connects to it."
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

    Edge.disable_bottle_freeze
  end

end
