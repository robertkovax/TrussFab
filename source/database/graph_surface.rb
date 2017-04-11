require ProjectHelper.database_directory + '/graph_object.rb'
require ProjectHelper.database_directory + '/surface.rb'

class GraphSurface < GraphObject
  attr_reader :first_node, :second_node, :third_node

  def initialize first_node, second_node, third_node, id: nil
    @first_node = first_node
    @second_node = second_node
    @third_node = third_node
    super id
    register_observers
  end

  def position
    center
  end

  def center
    Geometry::triangle_incenter @first_node.position, @second_node.position, @third_node.position
  end

  def distance point
    center.distance point
  end

  def update symbol
    delete if symbol == :deleted
  end

  def nodes
    [first_node, second_node, third_node]
  end

  def delete
    delete_observers
    super
  end

  private
  def create_thingy id
    @thingy = Surface.new @first_node.position, @second_node.position, @third_node.position, id: id
  end

  def delete_thingy
    @thingy.delete
  end

  def delete_observers
    @first_node.delete_observer self
    @second_node.delete_observer self
    @third_node.delete_observer self
  end

  def register_observers
    @first_node.add_observer self
    @second_node.add_observer self
    @third_node.add_observer self
  end
end