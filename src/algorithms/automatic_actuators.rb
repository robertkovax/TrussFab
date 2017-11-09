require 'set'

# The class is a c & p from the relaxion algorithm and adapted to our needs.
# Instead of moving the nodes, it finds the shortest edge in the optimized model and transform it into an actuator.
# There is still a lot of work left to do in only works in some basic cases.
class AutomaticActuators
  DEFAULT_MAX_ITERATIONS = 20_000
  CONVERGENCE_DEVIATION = 1.mm
  DAMPENING_FACTOR = 0.9

  attr_reader :new_node_positions, :new_direction_vectors, :new_start_positions,
    :max_iterations

  def initialize(max_iterations: DEFAULT_MAX_ITERATIONS)
    @dampening_factor = DAMPENING_FACTOR
    @max_iterations = max_iterations

    # We first calculate over several iterations the new positions and
    # only update the final position in the end for performance reasons.
    @new_direction_vectors = {}
    @new_node_positions = {}
    @new_start_positions = {}

    @fixed_nodes = Set.new
    @ignore_node_fixation = Set.new

    # Contains edges that were already adapted.
    @edges = Set.new

    # All edges want to preserve their original length in the optimal case.
    @optimal_length = {}
  end

  def stretch(edge)
    change_length(edge, edge.next_longer_length)
    self
  end

  def shrink(edge)
    change_length(edge, edge.next_shorter_length)
    self
  end

  def move_and_fix_node(node, position)
    return if node.nil?
    fix_node(node)
    @new_node_positions[node.id] = position
    add_edges(node.incidents)
    update_incident_edges(node)
    self
  end

  def fix_node(node)
    @fixed_nodes << node
    self
  end

  def relax
    puts 'check'

    # Abort if there is nothing to do
    return if @edges.empty?
    fix_nodes
    number_connected_edges = connected_edges.length
    count = 0
    (1..@max_iterations).each do
      # pick a random edge
      edge = @edges.to_a.sample
      # only adapt edge if we have still stuff to do
      deviation = deviation_to_optiomal_length(edge)
      next if deviation.abs < CONVERGENCE_DEVIATION
      # add neighbors if we have still edges left to add
      add_edges(edge.incidents) unless @edges.length == number_connected_edges
      adapt_edge(edge, deviation * @dampening_factor)
      count += 1
    end
    puts "Relaxation iterations: #{count}"
    find_edge_minimum_length # returns omitted edge
  end

  private

  def change_length(edge, target_length)
    add_edge(edge)
    @optimal_length[edge] = target_length
    if fixed?(edge.first_node) && fixed?(edge.second_node)
      @ignore_node_fixation << edge.first_node
      @ignore_node_fixation << edge.second_node
    end
    self
  end

  def fix_nodes
    Graph.instance.nodes.each_value do |node|
      @fixed_nodes << node if fixed?(node)
    end
  end

  def connected_edges
    all_edges = Set.new
    @edges.each { |edge| all_edges.merge(edge.connected_component) }
    all_edges
  end

  def deviation_to_optiomal_length(edge)
    if @new_direction_vectors[edge.id]
      @optimal_length[edge] - @new_direction_vectors[edge.id].length
    else
      0.0
    end
  end

  def add_edges(edges)
    edges.each { |edge| add_edge(edge) }
  end

  def add_edge(edge)
    return if @edges.add?(edge).nil? # abort when already in set

    @optimal_length[edge] = edge.length

    first_node_id = edge.first_node.id
    unless @new_node_positions[first_node_id]
      @new_node_positions[first_node_id] = edge.first_node.position
    end

    second_node_id = edge.second_node.id
    unless @new_node_positions[second_node_id]
      @new_node_positions[second_node_id] = edge.second_node.position
    end

    edge_id = edge.id
    unless @new_direction_vectors[edge_id]
      @new_direction_vectors[edge_id] = edge.direction
    end

    @new_start_positions[edge_id] = edge.first_node.position
  end

  # delta is dampened to prevent undesired behavior like length jumping between
  # two extreme cases it will adapt to the desired length over a larger number
  # of iterations
  def adapt_edge(edge, delta)
    edge_id = edge.id
    first_node_id = edge.first_node.id
    second_node_id = edge.second_node.id

    is_first_node_fixed = @fixed_nodes.include?(edge.first_node)
    is_second_node_fixed = @fixed_nodes.include?(edge.second_node)

    new_direction_vector = @new_direction_vectors[edge_id]

    if is_first_node_fixed && is_second_node_fixed
      @optimal_length[edge] = new_direction_vector.length
    else
      stretch_vector = new_direction_vector.clone
      stretch_vector.length = delta
      if is_first_node_fixed
        new_direction_vector = @new_direction_vectors[edge_id] = new_direction_vector + stretch_vector

        @new_node_positions[second_node_id] =
          @new_start_positions[edge_id] + new_direction_vector

        update_incident_edges(edge.second_node)
      elsif is_second_node_fixed
        new_start_position = @new_start_positions[edge_id] = @new_start_positions[edge_id] - stretch_vector
        @new_direction_vectors[edge_id] = new_direction_vector + stretch_vector
        @new_node_positions[first_node_id] = new_start_position

        update_incident_edges(edge.first_node)
      else
        new_start_position = @new_start_positions[edge_id] = @new_start_positions[edge_id] - Geometry.scale(stretch_vector, 0.5)

        new_direction_vector = @new_direction_vectors[edge_id] =
          new_direction_vector + stretch_vector

        @new_node_positions[first_node_id] = new_start_position

        @new_node_positions[second_node_id] =
          new_start_position + new_direction_vector

        update_incident_edges(edge.first_node)
        update_incident_edges(edge.second_node)
      end
    end
  end

  def find_edge_minimum_length
    edges_array = @edges.to_a
    minimum_edge = edges_array.map(&:length).each_with_index.min
    puts "Omit Minimum Edge #{minimum_edge}"
    edges_array[minimum_edge[1]]
  end

  def update_incident_edges(node)
    node.incidents.each do |incident|
      incident_id = incident.id
      new_node_position = @new_node_positions[node.id]
      if incident.first_node == node
        @new_start_positions[incident_id] = new_node_position
        @new_direction_vectors[incident_id] =
          @new_node_positions[incident.second_node.id] - new_node_position
      else
        @new_direction_vectors[incident_id] =
          new_node_position - @new_start_positions[incident_id]
      end
    end
  end

  def fixed?(node)
    incidents_frozen = node.incidents.any? do |incident|
      incident.opposite(node).frozen?
    end

    !@ignore_node_fixation.include?(node) &&
      (@fixed_nodes.include?(node) || node.fixed? || incidents_frozen)
  end
end
