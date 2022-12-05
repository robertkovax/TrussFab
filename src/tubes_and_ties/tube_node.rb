require 'src/database/graph_object.rb'

class TubeNode < GraphObject
  attr_accessor :edges

  def initialize(id)
    super(id)
    @edges = []
  end

  def adjacent_nodes
    @edges.map { |edge| edge.opposite(self) }
  end

  def edge_to(node)
    @edges.find { |edge| edge.opposite(self) == node }
  end

  def adjacent_nodes_without_first_mark
    edges_without_first_mark.map { |edge| edge.opposite(self) }
  end

  def edges_without_first_mark
    @edges.reject(&:first_mark)
  end

  def open
    adjacent_nodes_without_first_mark.length > 0
  end

  def create_sketchup_object(_id)

  end

end
