require 'src/database/graph_object.rb'
require 'src/thingies/hub.rb'

class Node < GraphObject

  attr_reader :position, :incidents

  def initialize(position, id: nil)
    @deleting = false
    @position = position
    @incidents = []             # connected edges
    @adjcacent_triangles = []   # connceted triangles
    super(id)
  end

  def move(position)
    @position = position
    @thingy.update_position(position)
    @incidents.each {|incident| incident.move}
    @adjcacent_triangles.each {|triangle| triangle.move}
  end

  def distance(point)
    @position.distance(point)
  end

  def fixed?
    # TODO check if pod on node or fixed/frozen manually
    false
  end

  def frozen?
    # TODO check if node is frozen by context menu, manually saving this node and connected edges from being changed
    false
  end

  def adjacent_nodes
    @incidents.map { |edge| edge.other_node(self) }
  end

  def add_incident(edge)
    @incidents << edge
  end

  def add_adjacent_triangle(triangle)
    @adjcacent_triangles << triangle
  end

  def delete_incident(edge)
    @incidents.delete(edge)
    return true if @deleting # prevent dangling check when deleting node
    delete if dangling?
  end

  def delete_adjacent_triangle(triangle)
    @adjcacent_triangles.delete(triangle)
  end

  def dangling?
    @incidents.empty?
  end

  def is_adjacent(node)
    @incidents.any? { |edge| edge.include?(node) }
  end

  def is_incident(edge)
    @incidents.include?(edge)
  end

  def delete
    super
    @incidents.each(&:delete)
    @adjcacent_triangles.clone.each do |triangle|
      triangle.delete unless triangle.deleted
    end
    false
  end

  private

  def create_thingy(id)
    Hub.new(@position, id: id)
  end

  def delete_thingy
    @thingy.delete unless @thingy.nil?
    @thingy = nil
  end
end
