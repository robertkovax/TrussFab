require ProjectHelper.database_directory + '/node.rb'
require ProjectHelper.database_directory + '/edge.rb'
require ProjectHelper.database_directory + '/graph_surface.rb'

class Graph
  include Singleton

  attr_reader :edges, :nodes, :surfaces

  def initialize
    @edges = Hash.new
    @nodes = Hash.new
    @surfaces = Hash.new
  end

  def create_edge_from_points first_position, second_position, link_type, model_name, first_elongation_length, second_elongation_length
    first_node = create_node first_position
    second_node = create_node second_position
    create_edge first_node, second_node, link_type, model_name, first_elongation_length, second_elongation_length
  end

  def create_edge first_node, second_node, link_type, model_name, first_elongation_length, second_elongation_length
    edge = Edge.new first_node, second_node, link_type, model_name, first_elongation_length, second_elongation_length
    @edges[edge.id] = edge
    edge
  end

  def create_surface_from_nodes first_node, second_node, third_node
    surface = GraphSurface.new first_node, second_node, third_node
    @surfaces[surface.id] = surface
    surface
  end

  def get_closest_edge position
    min = Float::INFINITY
    closest_edge = nil
    @edges.values.each do |edge|
      if edge.distance(position) < min
        min = edge.distance position
        closest_edge = edge
      end
    end
    closest_edge
  end

  def get_closest_surface position
    min = Float::INFINITY
    closest_surface = nil
    @surfaces.values.each do |surface|
      if surface.distance(position) < min
        min = surface.distance position
        closest_surface = surface
      end
    end
    closest_surface
  end

  def get_closest_node position
    min = Float::INFINITY
    closest_node = nil
    @nodes.values.each do |node|
      if node.distance(position) < min
        min = node.distance position
        closest_node = node
      end
    end
    closest_node
  end

  def get_node_at position
    node_at_position = nil
    @nodes.values.each do |node|
      if node.position == position
        node_at_position = node
        break
      end
    end
    node_at_position
  end

  # this expects a 3-node array
  def duplicated_surface? nodes
    duplicated = false
    @surfaces.values.each do |surface|
      duplicated = true if nodes.include?(surface.first_node) and
          nodes.include?(surface.second_node) and
          nodes.include?(surface.third_node)
      break if duplicated
    end
    duplicated
  end

  private
  # nodes should never be created without a corresponding edge, therefore private
  def create_node position
    node = get_node_at position
    return node unless node.nil?
    node = Node.new position
    @nodes[node.id] = node
    node
  end
end