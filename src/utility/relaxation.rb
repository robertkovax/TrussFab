require 'set'

class Relaxation
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
    @new_direction_vectors = []
    @new_node_positions = []
    @new_start_positions = []

    @fixed_nodes = Set.new
    @ignore_node_fixation = Set.new

    # Contains edges that were `touched`. We choose randomly out of
    # this array for the iterations.
    # (Not quite sure if I understand this remark from the author correctly
    # - Johannes)
    @edges = []

    @edge_ids = Array.new(IdManager.instance.last_id)

    # All edges want to preserve their original length. In this map,
    # we save the values which never get changed.
    @original_lengths = {}
  end

  def stretch(edge)
    change_length(edge, edge.next_longer_length)
    self
  end

  def shrink(edge)
    change_length(edge, edge.next_shorter_length)
    self
  end

  def move_node(node, position)
    return if node.nil?
    @fixed_nodes << node
    @new_node_positions[node.id] = position
    add_edges(node.incidents)
    update_incident_edges(node)
    self
  end

  def relax
    fix_nodes
    number_connected_edges = connected_edges.length
    count = 0
    (1..@max_iterations).each do
      edge = @edges.sample
      next if deviation(edge).abs < CONVERGENCE_DEVIATION
      add_edges(edge.incidents) unless @edges.length == number_connected_edges
      adapt_edge(edge, deviation(edge) * @dampening_factor)
      count += 1
    end
    puts "Relaxation iterations: #{count}"
    update_nodes
    self
  end

  private

  def change_length(edge, target_length)
    add_edge(edge)
    @original_lengths[edge] = target_length
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

  def deviation(edge)
    if @new_direction_vectors[edge.id]
      @original_lengths[edge] - @new_direction_vectors[edge.id].length
    else
      0.0
    end
  end

  def add_edges(edges)
    edges.each { |edge| add_edge(edge) }
  end

  def add_edge(edge)
    edge_id = edge.id
    return if @edge_ids[edge_id]

    @edge_ids[edge_id] = true
    @edges << edge
    @original_lengths[edge] = edge.length

    first_node_id = edge.first_node.id

    unless @new_node_positions[first_node_id]
      @new_node_positions[first_node_id] = edge.first_node.position
    end

    second_node_id = edge.second_node.id

    unless @new_node_positions[second_node_id]
      @new_node_positions[second_node_id] = edge.second_node.position
    end

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
    is_first_node_fixed = @fixed_nodes.include?(edge.first_node)

    second_node_id = edge.second_node.id
    is_second_node_fixed = @fixed_nodes.include?(edge.second_node)

    new_direction_vector = @new_direction_vectors[edge_id]

    if is_first_node_fixed && is_second_node_fixed
      @original_lengths[edge] = new_direction_vector.length
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

  def update_nodes
    nodes = Set.new
    @edges.each do |edge|
      nodes.add(edge.first_node)
      nodes.add(edge.second_node)
    end
    nodes.each do |node|
      next if @new_node_positions[node.id] == node.position
      node.move(@new_node_positions[node.id])
    end
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
    node_id = node.id
    incidents_frozen = node.incidents.any? do |incident|
      incident.opposite(node).frozen?
    end

    !@ignore_node_fixation.include?(node) &&
      (@fixed_nodes.include?(node) || node.fixed? || incidents_frozen)
  end
end
