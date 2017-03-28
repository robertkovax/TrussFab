require ProjectHelper.database_directory + '/node.rb'
require ProjectHelper.database_directory + '/edge.rb'
require ProjectHelper.database_directory + '/graph_surface.rb'

class Graph
  include Singleton

  def initialize
    @edges = Hash.new
    @nodes = Hash.new
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
    GraphSurface.new first_node, second_node, third_node
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