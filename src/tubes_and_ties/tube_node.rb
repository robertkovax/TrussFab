require 'src/database/graph_object.rb'

class TubeNode < GraphObject
  attr_accessor :edges, :dfs_mark

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

  def adjacent_nodes_without_dfs_mark
    edges.map { |edge| edge.opposite(self) }.reject { |node| node.dfs_mark }
  end

  def adjacent_nodes_without_first_mark
    edges_without_first_mark.map { |edge| edge.opposite(self) }
  end

  def adjacent_nodes_without_second_mark
    edges_without_second_mark.map { |edge| edge.opposite(self) }
  end

  def adjacent_nodes_with_user_mark
    edges_with_user_mark.map { |edge| edge.opposite(self) }
  end

  def edges_without_first_mark
    @edges.reject(&:first_mark)
  end

  def edges_without_second_mark
    @edges.reject(&:second_mark)
  end

  def edges_with_second_mark
    @edges.select(&:second_mark)
  end

  def edges_with_user_mark
    @edges.select(&:marked_as_double)
  end

  # a node is open if it has been partially visited but not fully.
  def open
    adjacent_nodes_without_first_mark.length > 0
  end

  def create_sketchup_object(_id)

  end

end
