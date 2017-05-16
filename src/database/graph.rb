require 'singleton'
require 'src/database/node.rb'
require 'src/database/edge.rb'
require 'src/database/triangle.rb'

class Graph
  include Singleton

  attr_reader :edges, :nodes, :surfaces

  def initialize
    @edges = {}
    @nodes = {}
    @surfaces = {}
  end

  #
  # Methods to to create one node, edge or surface
  #

  # nodes should never be created without a corresponding edge, therefore private
  private def create_node(position)
    node = find_node(position)
    return node unless node.nil?
    node = Node.new(position)
    @nodes[node.id] = node
    node
  end

  def create_edge_from_points(first_position, second_position, model_name, first_elongation_length, second_elongation_length, link_type: 'bottle_link')
    first_node = create_node(first_position)
    second_node = create_node(second_position)
    create_edge(first_node, second_node, model_name, first_elongation_length, second_elongation_length, link_type: link_type)
  end

  def create_edge(first_node, second_node, model_name, first_elongation_length, second_elongation_length, link_type: 'bottle_link')
    nodes = [first_node, second_node]
    edge = find_edge(nodes)
    return edge unless edge.nil?
    edge = Edge.new(first_node, second_node, model_name, first_elongation_length, second_elongation_length, link_type: link_type)
    @edges[edge.id] = edge
    edge
  end

  def create_surface_from_points(first_position, second_position, third_position, definition)
    first_node = create_node(first_position)
    second_node = create_node(second_position)
    third_node = create_node(third_position)
    model = definition.model
    create_edge(first_node, second_node, model.name, 0, 0)
    create_edge(second_node, third_node, model.name, 0, 0)
    create_edge(first_node, third_node, model.name, 0, 0)
    create_surface(first_node, second_node, third_node)
  end

  def create_surface(first_node, second_node, third_node)
    nodes = [first_node, second_node, third_node]
    surface = find_surface(nodes)
    return surface unless surface.nil?
    surface = Triangle.new(first_node, second_node, third_node)
    @surfaces[surface.id] = surface
    surface
  end

  #
  # Methods to get closest node, edge or surface
  #

  def closest_node(position)
    @nodes.values.min_by { |node| node.distance(position) }
  end

  def closest_edge(position)
    @edges.values.min_by { |edge| edge.distance(position) }
  end

  def closest_surface(position)
    @surfaces.values.min_by { |surface| surface.distance(position) }
  end

  #
  # Methods to check whether a node, edge or surface already exists
  # and return the duplicate if there is some
  #

  def find_node(position)
    @nodes.values.detect { |node| node.position == position }
  end

  # this function expects a 2-node array
  def find_edge(nodes)
    @edges.values.detect do |edge|
      edge.nodes.all? { |node| nodes.include?(node) }
    end
  end

  # this function expects a 3-node array
  def find_surface(nodes)
    @surfaces.values.detect do |surface|
      surface.nodes.all? { |node| nodes.include?(node) }
    end
  end

  def empty?
    return nodes.empty? 
  end
  #
  # Method to delete either a node, an edge or a surface
  #

  def delete_object(object)
    hash = @nodes if object.is_a?(Node)
    hash = @edges if object.is_a?(Edge)
    hash = @surfaces if object.is_a?(Triangle)
    return if hash.nil?
    hash.delete(object.id)
  end
end
