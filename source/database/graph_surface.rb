require ProjectHelper.database_directory + '/graph_object.rb'
require ProjectHelper.database_directory + '/surface.rb'

class GraphSurface < GraphObject
  def initialize node1, node2, node3, id: nil
    @node1 = node1
    @node2 = node2
    @node3 = node3
    super id
  end

  def center
    Geometry::triangle_incenter @position1, @position2, @position3
  end

  private
  def create_thingy id
    @thingy = Surface.new @node1.position, @node2.position, @node3.position, id: id
  end
end