require 'src/database/graph_object.rb'
require 'src/thingies/surface.rb'

class Triangle < GraphObject
  attr_reader :first_node, :second_node, :third_node

  def initialize(first_node, second_node, third_node, id: nil)
    @first_node = first_node
    @second_node = second_node
    @third_node = third_node
    first_node.add_adjacent_triangle(self)
    second_node.add_adjacent_triangle(self)
    third_node.add_adjacent_triangle(self)
    super(id)
  end

  def position
    center
  end

  def center
    Geometry.triangle_incenter(@first_node.position,
                               @second_node.position,
                               @third_node.position)
  end

  def distance(point)
    center.distance(point)
  end

  def move
    @thingy.update_positions(@first_node.position,
                              @second_node.position,
                              @third_node.position)
  end

  def nodes
    [first_node, second_node, third_node]
  end

  private

  def create_thingy(id)
    Surface.new(@first_node.position,
                @second_node.position,
                @third_node.position,
                id: id)
  end
end
