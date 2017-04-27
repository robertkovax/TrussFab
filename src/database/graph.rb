require 'singleton'
require 'src/database/node.rb'
require 'src/database/edge.rb'
require 'src/database/triangle_surface.rb'

class Graph
  include Singleton

  attr_reader :edges, :nodes, :surfaces

  def initialize
    @edges = {}
    @nodes = {}
    @surfaces = {}
  end

  def create_edge_from_points(first_position, second_position, model_name, first_elongation_length, second_elongation_length, link_type: 'bottle_link')
    first_node = create_node(first_position)
    second_node = create_node(second_position)
    create_edge(first_node, second_node, model_name, first_elongation_length, second_elongation_length, link_type: link_type)
  end

  def create_edge(first_node, second_node, model_name, first_elongation_length, second_elongation_length, link_type: 'bottle_link')
    nodes = [first_node, second_node]
    return true if duplicated_edge?(nodes)
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
    return true if duplicated_surface?(nodes)
    surface = TriangleSurface.new(first_node, second_node, third_node)
    @surfaces[surface.id] = surface
    surface
  end

  def closest_edge(position)
    @edges.values.min_by { |edge| edge.distance(position) }
  end

  def closest_surface(position)
    @surfaces.values.min_by { |surface| surface.distance(position) }
  end

  def closest_node(position)
    @nodes.values.min_by { |node| node.distance(position) }
  end

  def duplicated_node?(position)
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
  def duplicated_surface?(nodes)
    duplicated = false
    @surfaces.each_value do |surface|
      duplicated = surface if nodes.include?(surface.first_node) &&
                              nodes.include?(surface.second_node) &&
                              nodes.include?(surface.third_node)
      break if duplicated
    end
    duplicated
  end

  # this function expects a 2-node array
  def duplicated_edge?(nodes)
    duplicated = false
    @edges.each_value do |edge|
      duplicated = edge if nodes.include?(edge.first_node) &&
                           nodes.include?(edge.second_node)
      break if duplicated
    end
    duplicated
  end

  def delete_object(object)
    hash = @nodes if object.is_a?(Node)
    hash = @edges if object.is_a?(Edge)
    hash = @surfaces if object.is_a?(TriangleSurface)
    return if hash.nil?
    hash.delete(object.id)
  end

  private

  # nodes should never be created without a corresponding edge, therefore private
  def create_node(position)
    node = duplicated_node?(position)
    return node unless node.nil?
    node = Node.new(position)
    @nodes[node.id] = node
    node
  end
end
