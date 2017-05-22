class Relaxation

  DEFAULT_MAX_ITERATIONS = 20_000
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
    change_length(edge, edge.next_longer_length)
    self
  end

  def shrink(edge)
    change_length(edge, edge.next_shorter_length)
    self
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
    @new_node_positions[node.id] = position
    add_edges(node.partners.map { |partner| partner[:edge] })
    update_neighbor_links(node)
    self
  end

  def relax
    compute_fixed_nodes
    number_connected_edges = connected_edges
    count = 0
    (1..@max_iterations).each do
      edge = pick_random_edge
      next if deviation(edge) < CONVERGENCE_DEVIATION
      add_edges(edge.directly_connected_edges) unless @clinks.length == number_connected_edges
      adapt_edges(edge, deviation(edge) * @dampening_factor)
      count += 1
    end
    update_nodes
    self
  end

  private

  # delta is dampened to prevent undesired behavior like length jumping between two extreme cases
  # it will adapt to the desired length over a larger number of iterations
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

  def adapt_edge(edge, delta)
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
        @new_node_positions[second_node_id] = new_start_position + new_direction
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

  def deviation(edge)
    if @new_direction_vectors[edge.id]
      edge.desired_length - @new_direction_vectors[edge.id].length
    else
      0
    end
  end

  def connected_edges
    all_edges = Set.new
    @edges.each { |edge| all_edges.merge(edge.connected_edges) }
    all_edges.length
  end

  def pick_random_edge
    @edges[rand(@edges.length)]
  end

  def constrain_node(node)
    @fixed_nodes[node.id] = node unless node.nil?
    self
  end

  def is_fixed(node)
    node_id = node.id
    partners_frozen = node.partners.values.values.map { |partner| partner[:node].frozen? }.any?
    @ignore_node_fixation[node_id].nil? && (@fixed_nodes[node_id] ||
                                            node.fixed? ||
                                            partners_frozen)
  end

  def compute_fixed_nodes
    Graph.instance.nodes.each_value do |node|
      @fixed_nodes[node.id] = is_fixed(node)
    end
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
    @new_node_positions[second_node_id] = edge.second_node.position unless @new_node_positions[second_node_id]

    @new_direction_vectors[edge_id] = edge.direction unless @new_direction_vectors[edge_id]
    @new_start_positions[edge_id] = edge.first_node.position
  end
end