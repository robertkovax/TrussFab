require 'src/database/graph_object.rb'
require 'src/thingies/hub.rb'
require 'src/thingies/hub_entities/pod.rb'

class Node < GraphObject

  attr_accessor :position
  attr_reader :position, :incidents, :adjacent_triangles, :pod_directions

  def initialize(position, id: nil)
    @deleting = false
    @position = position
    @incidents = []            # connected edges
    @adjacent_triangles = []   # connceted triangles
    @pod_directions = {}
    super(id)
  end

  def move(position)
    @position = position
    @thingy.update_position(position)
    @incidents.each(&:move)
    @adjacent_triangles.each(&:move)
  end

  def transform(transformation)
    @position = transformation * @position
    @thingy.transform(transformation)
  end

  def distance(point)
    @position.distance(point)
  end

  def vector_to(other_node)
    @position.vector_to(other_node.position)
  end

  def pods
    @thingy.pods
  end

  def fixed?
    not @pod_directions.empty?
  end

  def frozen?
    # TODO check if node is frozen by context menu, manually saving this node and connected edges from being changed
    false
  end

  def adjacent_nodes
    @incidents.map { |edge| edge.other_node(self) }
  end

  def edge_to(node)
    @incidents.find { |edge| edge.other_node(self) == node }
  end

  def add_incident(edge)
    @incidents << edge
  end

  def add_adjacent_triangle(triangle)
    @adjacent_triangles << triangle
  end

  def delete_incident(edge)
    @incidents.delete(edge)
    delete if dangling?
  end

  def delete_adjacent_triangle(triangle)
    @adjacent_triangles.delete(triangle)
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

  def add_pod(direction = nil)
    id = IdManager.instance.generate_next_id
    @pod_directions[id] = direction.nil? ? Geometry::Z_AXIS.reverse : direction
    @thingy.add_pod(@pod_directions[id], id: id)
  end

  def delete_pod(id)
    @pod_directions.delete(id)
    @thingy.delete_sub_thingy(id)
  end

  def delete
    super
    @incidents.each(&:delete)
    @adjacent_triangles.clone.each do |triangle|
      triangle.delete unless triangle.deleted
    end
  end

  private

  def create_thingy(id)
    Hub.new(@position, id: id)
  end
end
