require 'singleton'
require 'src/database/node.rb'
require 'src/database/edge.rb'
require 'src/database/triangle.rb'
require 'src/utility/scad_export.rb'
require 'src/utility/bottle_counter.rb'

class Graph
  include Singleton

  attr_reader :edges, :nodes, :surfaces

  CLOSE_NODE_DIST = 50.mm

  def initialize
    @edges = {}       # {(id => edge)}
    @nodes = {}       # {(id => node)}
    @surfaces = {}    # {(id => surface)}
  end

  def nodes_and_edges
    [@edges.values, @nodes.values].flatten
  end

  def all_graph_objects
    [@edges.values, @nodes.values, @surfaces.values].flatten
  end

  def export_to_scad(path)
    ScadExport.export_to_scad(path)
  end

  #
  # Methods to to create one node, edge or surface
  #

  def create_edge_from_points(first_position, second_position, model_name: 'hard', bottle_type: Configuration::BIG_BIG_BOTTLE_NAME, link_type: 'bottle_link')
    first_node = create_node(first_position)
    second_node = create_node(second_position)
    edge = create_edge(first_node, second_node, model_name: model_name, bottle_type: bottle_type, link_type: link_type)
    edge
  end

  def create_edge(first_node, second_node, model_name: 'hard', bottle_type: Configuration::BIG_BIG_BOTTLE_NAME, link_type: 'bottle_link')
    nodes = [first_node, second_node]
    edge = find_edge(nodes)
    return edge unless edge.nil?
    edge = Edge.new(first_node, second_node, model_name: model_name, bottle_type: bottle_type, link_type: link_type)
    create_possible_surfaces(edge)
    @edges[edge.id] = edge
    BottleCounter.update_status_text
    edge
  end

  def create_surface_from_points(first_position, second_position, third_position, model_name: 'hard', bottle_type: Configuration::BIG_BIG_BOTTLE_NAME, link_type: 'bottle_link')
    first_node = create_node(first_position)
    second_node = create_node(second_position)
    third_node = create_node(third_position)
    create_edge(first_node, second_node, model_name: model_name, bottle_type: bottle_type, link_type: link_type)
    create_edge(second_node, third_node, model_name: model_name, bottle_type: bottle_type, link_type: link_type)
    create_edge(first_node, third_node, model_name: model_name, bottle_type: bottle_type, link_type: link_type)
  end

  def create_surface(first_node, second_node, third_node)
    nodes = [first_node, second_node, third_node]
    surface = find_surface(nodes)
    return surface unless surface.nil?
    surface = Triangle.new(first_node, second_node, third_node)
    @surfaces[surface.id] = surface
    surface
  end

  def create_possible_surfaces(edge)
    first_node = edge.first_node
    second_node = edge.second_node
    first_other_nodes = first_node.adjacent_nodes
    second_other_nodes = second_node.adjacent_nodes
    (first_other_nodes & second_other_nodes).each do |node|
      create_surface(first_node, second_node, node)
    end
  end

  #
  # Methods to get closest node, edge or surface
  #

  def closest_node(point)
    @nodes.values.min_by { |node| node.distance(point) }
  end

  def closest_edge(point)
    @edges.values.min_by { |edge| edge.distance(point) }
  end

  def closest_surface(point)
    @surfaces.values.min_by { |surface| surface.distance(point) }
  end

  def closest_pod(point)
    pods.min_by { |pod| pod.distance(point) }
  end

  def pods
    @nodes.values.flat_map(&:pods)
  end

  #
  # Methods to check whether a node, edge or surface already exists
  # and return the duplicate if there is some
  #

  def find_close_node(position, dist_delta: CLOSE_NODE_DIST)
    @nodes.values.detect do |node|
      node.position.distance(position) <= dist_delta
    end
  end

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
    nodes.empty?
  end

  #
  # Methods to clear graph or redraw/reset all graph objects
  #

  def clear!
    @edges = {}       # {(id => edge)}
    @nodes = {}       # {(id => node)}
    @surfaces = {}    # {(id => surface)}
    Sketchup.active_model.entities.clear!
  end

  def redraw
    all_graph_objects.each(&:redraw)
  end

  # This removes all objects with deleted instances
  # Call this prior to exporting, importing, or starting simulation
  def cleanup
    @edges.reject! { |id, e|
      !e.check_if_valid
    }
    @nodes.reject! { |id, e|
      !e.check_if_valid
    }
    @surfaces.reject! { |id, e|
      !e.check_if_valid
    }
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
    BottleCounter.update_status_text
  end

  # nodes should never be created without a corresponding edge, therefore private
  private
  def create_node(position)
    node = find_close_node(position)
    return node unless node.nil?
    node = Node.new(position)
    @nodes[node.id] = node
    node
  end
end
