class Relaxation
  DEFAULT_MAX_ITERATIONS = 20_000
  CONVERGENCE_DEVIATION = 1.mm
  DAMPENING_FACTOR = 0.9

  attr_reader :new_node_positions, :new_direction_vectors, :new_start_positions, :max_iterations

  def initialize(max_iterations: DEFAULT_MAX_ITERATIONS)
    @dampening_factor = DAMPENING_FACTOR
    @max_iterations = max_iterations

    # We first calculate over several iterations the new positions and
    # only update the final position in the end for performance reasons.
    @new_direction_vectors = []
    @new_node_positions = []
    @new_start_positions = []
    @fixed_nodes = []
    @ignore_node_fixation = []

    # Contains edges that were `touched`. We choose randomly out of
    # this array for the iterations.
    # (Not quite sure if I undertand this remark from the author correctly
    # - Johannes)
    @edges = []

    @edge_ids = Array.new(IdManager.instance.last_id)

    # All edges want to preserve their original length. In this map,
    # we save the values which never get changed.
    @desired_lengths = {}
  end

  def stretch(edge)
    change_length(edge, edge.next_longer_length)
    self
  end

  def shrink(edge)
    change_length(edge, edge.next_shorter_length)
    self
  end

  def change_length(edge, target_length)
    add_edge(edge)
    @desired_lengths[edge] = target_length
    if fixed?(edge.first_node) && fixed?(edge.second_node)
      @ignore_node_fixation[edge.first_node.id] = edge.first_node
      @ignore_node_fixation[edge.second_node.id] = edge.second_node
    end
    self
  end

  def move_node(node, position)
    return if node.nil?
    constrain_node(node)
    @new_node_positions[node.id] = position
    add_edges(node.incidents)
    update_incident_edges(node)
    self
  end

  def relax
    compute_fixed_nodes
    number_connected_edges = connected_edges.length
    puts "num connected #{number_connected_edges}"
    count = 0
    (1..@max_iterations).each do
      edge = pick_random_edge
      next if deviation(edge).abs < CONVERGENCE_DEVIATION
      add_edges(edge.incidents) unless @edges.length == number_connected_edges
      adapt_edge(edge, deviation(edge) * @dampening_factor)
      count += 1
    end
    puts "Relaxation iterations: #{count}"
    update_nodes
    self
  end

  def constrain_node(node)
    @fixed_nodes[node.id] = node unless node.nil?
    self
  end

  private

  def compute_fixed_nodes
    Graph.instance.nodes.each_value do |node|
      @fixed_nodes[node.id] = fixed?(node)
    end
  end

  def connected_edges
    all_edges = Set.new
    @edges.each { |edge| all_edges.merge(edge.connected_component) }
    all_edges
  end

  def pick_random_edge
    @edges[rand(@edges.length)]
  end

  def deviation(edge)
    if @new_direction_vectors[edge.id]
      @desired_lengths[edge] - @new_direction_vectors[edge.id].length
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
    @desired_lengths[edge] = edge.length

    first_node_id = edge.first_node.id
    @new_node_positions[first_node_id] = edge.first_node.position unless @new_node_positions[first_node_id]
    second_node_id = edge.second_node.id
    @new_node_positions[second_node_id] = edge.second_node.position unless @new_node_positions[second_node_id]

    @new_direction_vectors[edge_id] = edge.direction unless @new_direction_vectors[edge_id]
    @new_start_positions[edge_id] = edge.first_node.position
  end

  # delta is dampened to prevent undesired behavior like length jumping between
  # two extreme cases it will adapt to the desired length over a larger number
  # of iterations
  def adapt_edge(edge, delta)
    edge_id = edge.id

    first_node_id = edge.first_node.id
    first_node_fixed = @fixed_nodes[first_node_id]
    second_node_id = edge.second_node.id
    second_node_fixed = @fixed_nodes[second_node_id]

    new_direction_vector = @new_direction_vectors[edge_id]

    if first_node_fixed && second_node_fixed
      @desired_lengths[edge] = new_direction_vector.length
    else
      stretch_vector = new_direction_vector.clone
      stretch_vector.length = delta
      if first_node_fixed
        new_direction_vector = @new_direction_vectors[edge_id] = new_direction_vector + stretch_vector
        @new_node_positions[second_node_id] = @new_start_positions[edge_id] + new_direction_vector
        update_incident_edges(edge.second_node)
      elsif second_node_fixed
        new_start_position = @new_start_positions[edge_id] = @new_start_positions[edge_id] - stretch_vector
        @new_direction_vectors[edge_id] = new_direction_vector + stretch_vector
        @new_node_positions[first_node_id] = new_start_position
        update_incident_edges(edge.first_node)
      else
        new_start_position = @new_start_positions[edge_id] = @new_start_positions[edge_id] - Geometry.scale(stretch_vector, 0.5)
        new_direction_vector = @new_direction_vectors[edge_id] = new_direction_vector + stretch_vector
        @new_node_positions[first_node_id] = new_start_position
        @new_node_positions[second_node_id] = new_start_position + new_direction_vector
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
        @new_direction_vectors[incident_id] = @new_node_positions[incident.second_node.id] - new_node_position
      else
        @new_direction_vectors[incident_id] = new_node_position - @new_start_positions[incident_id]
      end
    end
  end

  def fixed?(node)
    node_id = node.id
    incidents_frozen = node.incidents.any? { |incident| incident.opposite(node).frozen? }
    @ignore_node_fixation[node_id].nil? &&
      (@fixed_nodes[node_id] || node.fixed? || incidents_frozen)
  end
end
