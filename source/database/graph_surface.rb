require ProjectHelper.database_directory + '/graph_object.rb'
require ProjectHelper.database_directory + '/surface.rb'

class GraphSurface < GraphObject
  attr_reader :first_node, :second_node, :third_node

  def initialize first_node, second_node, third_node, id: nil
    @first_node = first_node
    @second_node = second_node
    @third_node = third_node
    super id
  end

  def center
    Geometry::triangle_incenter @first_node.position, @second_node.position, @third_node.position
  end

  def distance point
    center.distance point
  end

  private
  def create_thingy id
    @thingy = Surface.new @first_node.position, @second_node.position, @third_node.position, id: id
  end
end