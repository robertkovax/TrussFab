module Relaxation

  DEFAULT_MAX_ITERATIONS = 20000
  CONVERGENCE_DEVIATION = 1.mm
  DAMPENING_FACTOR = 0.9

  attr_reader :new_hub_positions, :new_direction_vectors, :new_start_positions, :max_iterations

  def initialize(max_iterations: DEFAULT_MAX_ITERATIONS)
    @dampening_factor = DAMPENING_FACTOR
    @max_iterations = max_iterations

    @new_direction_vectors = []
    @new_node_positions = []
    @new_start_positions = []
    @fixed_nodes = []
    @ignore_node_fixation = []

    @edges = []
    @edge_ids = Array.new(IdManager.instance.last_id)
  end

  def stretch(edge)
    # TODO compute new length
    # edge.next_longer_length
    change_length(edge, edge.length)
  end

  def shrink(edge)
    # TODO compute new length
    change_length(edge, edge.length)
  end

  def change_length(edge, target_length)
    add_edge(edge)
    edge.desired_length = target_length
    if is_fixed(edge.first_node) && is_fixed(edge.second_node)
      @ignore_node_fixation[edge.first_node.id] = edge.first_node
      @ignore_node_fixation[edge.second_node.id] = edge.second_node
    end
    self
  end

  def move_node(node)
    return if node.nil?
    constrain_node(node)
    @new_hub_positions[node.id] = position
    add_clinks(node.partners.map { |partner| partner[:edge] })
    update_neighbor_links(node)
  end

  def relax
    compute_fixed_nodes
    number_connected_edges = connected_edges
    count = 0
    (1..@max_iterations).each do
      edge = pick_random_edge
      next if deviation(edge) < CONVERGENCE_DEVIATION
      add_edges(edge.get_directly_connected_edges) unless @clinks.length == number_connected_edges
      adapt_edge(edge, deviation(edge) * @dampening_factor)
      count += 1
    end
    update_edges
  end

  # delta is dampened to prevent undesired behavior like length jumping between two extreme cases
  # it will adapt to the desired length over a larger number of iterations
  def adapt_edges(edge, delta)
    edge_id = edge.id
    first_node_id = edge.first_node.id
    first_node_fixed = @fixed_nodes[first_node_id]
    second_node_id = edge.second_node.id
    second_node_fixed = @fixed_nodes[second_node_id]
    new_direction = @new_direction_vectors[edge_id]

    if first_node_fixed && second_node_fixed
      clink.desired_stretch_length = new_direction.length
    else
      stretch_vector = new_direction.clone # clone vector to preserve old vector
      stretch_vector.length = delta
      new_direction = @new_direction_vectors[edge_id] = new_direction + stretch_vector
      if first_node_fixed
        @new_node_positions[second_node_id] = @new_start_positions[edge_id] + new_direction
        update_neighbor_links(edge.first_node)
      elsif second_node_fixed
        new_start_position = @new_start_positions[edge_id] = @new_start_positions[edge_id] - stretch_vector
        @new_node_positions[first_node_id] = new_start_position
        update_neighbor_links(edge.second_node)
      else
        new_start_position = @new_start_positions[edge_id] = @new_start_positions[edge_id] - Geometry::scale(stretch_vector, 0.5)
        @new_node_positions[first_node_id] = new_start_position
        @new_node_position[second_node_id] = new_start_position + new_direction
        update_neighbor_links(edge.first_node)
        update_neighbor_links(edge.second_node)
      end
    end
  end

  def update_neighbor_links(node)
    node.partners.each do |partner|
      partner_edge = partner[:edge]
      partner_edge_id = partner_edge.id
      new_node_position = @new_node_positions[node.id]
      if parnter_edge.first_node == node
        @new_start_positions[partner_edge_id] = new_node_position
        @new_direction_vectors[partner_edge_id] = @new_hub_positions[partner_edge.second_node.id] - new_node_position
      else
        @new_direction_vectors[partner_edge_id] = new_node_position - @new_start_positions[partner_edge_id]
      end
    end
  end

  def update_edges
    @edges.each do |edge|
      edge_id = edge.id
      edge.desired_stretch_length = nil
      start_position = @new_start_positions[edge_id]
      end_position = start_position + @new_direction_vectors[edge_id]

      next if start_position = edge.position && end_position = edge.end_position


    end
  end

  def deviation(edge)
    edge.desired_stretch_length - @new_direction_vectors[edge.id].length
  end

  def connected_edges
    all_edges = Set.new
    @edges.each { |edge| all_edges.merge(edge.get_connected_edges) }
    all_edges.length
  end

  def pick_random_edge
    @edges[rand(@edges.length)]
  end

  def constrain_node(node)
    @fixed_nodes[node.id] = hub unless node.nil?
    self
  end

  def is_fixed(node)
    node_id = node.id
    partners_fixed = false
    node.partners.each { |partner| partners_fixed = true if partner[:node].fixed}
    @ignore_node_fixation[hub_id].nil? && (@fixed_nodes[node_id] || node.fixed? || partners_fixed)
  end

  def compute_fixed_nodes
    Graph.instance.nodes.each_value { |node| @fixed_nodes[node.id] = is_fixed(node) }
  end

  def add_edges(edges)
    edges.each { |edge| add_edge(edge) }
  end

  def add_edge(edge)
    edge_id = edge.id
    return if @edge_ids[edge_id]

    @edge_ids[edge_id] = true
    @edges.push(edge)
    edge.desired_length = edge.length

    first_node_id = edge.first_node.id
    @new_node_positions[first_node_id] = edge.first_node.position unless @new_node_positions[first_node_id]
    second_node_id = edge.second_node.id
    @new_node_positions[secnod_node_id] = edge.second_node.position unless @new_node_positions[second_node_id]

    @new_direction_vectors[edge_id] = edge.direction unless @new_direction_vectors[edge_id]
    @new_start_positions[edge_id] = edge.first_node.position
  end
end