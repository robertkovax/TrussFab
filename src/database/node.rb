require 'src/database/graph_object.rb'
require 'src/thingies/hub.rb'
require 'src/thingies/hub_entities/pod.rb'

class Node < GraphObject

  attr_reader :position, :incidents

  def initialize(position, id: nil)
    @deleting = false
    @position = position
    @incidents = []             # connected edges
    @adjcacent_triangles = []   # connceted triangles
    @pod_directions = {}
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

  def add_incident(edge)
    @incidents << edge
  end

  def add_adjacent_triangle(triangle)
    @adjcacent_triangles << triangle
  end

  def delete_incident(edge)
    @incidents.delete(edge)
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

  def add_pod(direction = nil)
    id = IdManager.instance.generate_next_id
    @pod_directions[id] = direction.nil? ? Geom::Vector3d.new(0,0,-1) : direction
    @thingy.add_pod(id, @pod_directions[id])
  end

  def delete_pod(id)
    @pod_directions.delete(id)
    @thingy.delete_pod(id)
  end

  def pod_distance(pod_id, position)
    second_point = position + @pod_directions[pod_id]
    Geometry.dist_point_to_segment(position, [position, second_point])
  end

  def delete
    super
    @incidents.each(&:delete)
    @adjcacent_triangles.clone.each do |triangle|
      triangle.delete unless triangle.deleted
    end
  end

  private

  def create_thingy(id)
    Hub.new(@position, id: id)
  end
end
