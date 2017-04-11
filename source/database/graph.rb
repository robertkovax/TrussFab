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

  def create_edge_from_points first_position, second_position, model_name, first_elongation_length, second_elongation_length, link_type: "bottle_link"
    first_node = create_node first_position
    second_node = create_node second_position
    create_edge first_node, second_node, model_name, first_elongation_length, second_elongation_length, link_type: link_type
  end

  def create_edge first_node, second_node, model_name, first_elongation_length, second_elongation_length, link_type: "bottle_link"
    nodes = [first_node, second_node]
    return duplicated_edge?(nodes) if duplicated_edge?(nodes)
    edge = Edge.new first_node, second_node, model_name, first_elongation_length, second_elongation_length,link_type: link_type
    @edges[edge.id] = edge
    edge
  end

  def create_surface_from_points first_position, second_position, third_position, definition
    first_node = create_node first_position
    second_node = create_node second_position
    third_node = create_node third_position
    model = definition.model
    create_edge first_node, second_node, model.name, 0, 0
    create_edge second_node, third_node, model.name, 0, 0
    create_edge first_node, third_node, model.name, 0, 0
    create_surface first_node, second_node, third_node
  end

  def create_surface first_node, second_node, third_node
    nodes = [first_node, second_node, third_node]
    return duplicated_surface?(nodes) if duplicated_surface?(nodes)
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
    @surfaces.each_value do |surface|
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
    @nodes.each_value do |node|
      if node.distance(position) < min
        min = node.distance position
        closest_node = node
      end
    end
    closest_node
  end

  def duplicated_node? position
    node_at_position = nil
    @nodes.values.each do |node|
      if node.position == position
        node_at_position = node
        break
      end
    end
    node_at_position
  end

  # this function expects a 3-node array
  def duplicated_surface? nodes
    duplicated = false
    @surfaces.each_value do |surface|
      duplicated = surface if nodes.include?(surface.first_node) and
          nodes.include?(surface.second_node) and
          nodes.include?(surface.third_node)
      break if duplicated
    end
    duplicated
  end

  # this function expects a 2-node array
  def duplicated_edge? nodes
    duplicated = false
    @edges.each_value do |edge|
      duplicated = edge if nodes.include?(edge.first_node) and
          nodes.include?(edge.second_node)
      break if duplicated
    end
    duplicated
  end

  def delete_object object
    hash = @nodes if object.is_a? Node
    hash = @edges if object.is_a? Edge
    hash = @surfaces if object.is_a? Surface
    return if hash.nil?
    hash.delete object.id
  end

  private
  # nodes should never be created without a corresponding edge, therefore private
  def create_node position
    node = duplicated_node? position
    return node unless node.nil?
    node = Node.new position
    @nodes[node.id] = node
    node
  end
end