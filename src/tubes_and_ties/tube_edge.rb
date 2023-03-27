require 'src/database/graph_object.rb'

class TubeEdge < GraphObject
  attr_accessor :first_node, :second_node, :first_mark, :second_mark, :marked_as_double

  def initialize(first_node, second_node, id)
    super(id)
    @first_node = first_node
    @second_node = second_node

    @first_mark = false
    @second_mark = false
  end

  def opposite(node)
    return @second_node if node == @first_node
    return @first_node if node == @second_node
    nil
  end

  def create_sketchup_object(_id)

  end
end
