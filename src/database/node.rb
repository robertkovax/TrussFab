require 'src/database/graph_object.rb'
require 'src/thingies/hub.rb'
require 'src/thingies/hub_entities/pod.rb'

class Node < GraphObject
  attr_reader :position, :incidents, :pod_directions, :pod_constraints

  def initialize(position, id: nil)
    @deleting = false
    @position = position
    @incidents = []             # connected edges
    @adjcacent_triangles = []   # connceted triangles
    @pod_directions = {}
    @pod_constraints = {}
    super(id)
  end

  def move(position)
    @position = position
    @thingy.update_position(position)
    @incidents.each(&:move)
    @adjcacent_triangles.each(&:move)
  end

  def distance(point)
    @position.distance(point)
  end

  def pods
    @thingy.pods
  end

  def fixed?
    @pod_constraints.value?(true)
  end

  def frozen?
    # TODO: check if node is frozen by context menu, manually saving this node and connected edges from being changed
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

  def add_pod(direction = nil, constraint: true)
    id = IdManager.instance.generate_next_id
    direction = direction.normalize
    @pod_directions[id] = direction.nil? ? Geometry::Z_AXIS.reverse : direction
    @pod_constraints[id] = constraint
    @thingy.add_pod(@pod_directions[id], id: id)
  end

  def delete_pod(id)
    @pod_directions.delete(id)
    @pod_constraints.delete(id)
    @thingy.delete_sub_thingy(id)
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
