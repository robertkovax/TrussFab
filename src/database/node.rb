require 'src/database/graph_object.rb'
require 'src/thingies/hub.rb'
require 'src/thingies/hub_entities/pod.rb'

class Node < GraphObject
  attr_reader :position, :incidents, :pod_directions, :pod_constraints, :adjacent_triangles

  POD_ANGLE_THRESHOLD = 0.2

  def initialize(position, id: nil)
    @deleting = false
    @position = position
    @incidents = []             # connected edges
    @adjacent_triangles = []    # connected triangles
    @related_joints = []        # joints between edges belonging to this node
    @pod_directions = {}
    @pod_constraints = {}
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
    @pod_constraints.values.any?
  end

  def frozen?
    # TODO: check if node is frozen by context menu, manually saving this node and connected edges from being changed
    false
  end

  def add_incident(edge)
    @incidents << edge
  end

  def add_joint(joint)
    return if joint.nil?
    @related_joints << joint
  end

  def remove_joints
    @related_joints.each do |joint|
      joint = nil
    end
    @related_joints.clear
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

  def is_incident(edge)
    @incidents.include?(edge)
  end

  def is_adjacent(node)
    @incidents.any? { |edge| edge.include?(node) }
  end

  def adjacent_nodes
    @incidents.map { |edge| edge.opposite(self) }
  end

  def edge_to(node)
    @incidents.find { |edge| edge.opposite(self) == node }
  end

  def edge_to?(other_node)
    adjacent_nodes.include?(other_node)
  end

  def dangling?
    @incidents.empty?
  end

  def connected_component
    unless @incidents.empty?
      @incidents[0].connected_component
    end
  end

  def merge_into(other_node)
    merged_incidents = []
    @incidents.each do |edge|
      edge_opposite_node = edge.opposite(self)
      next if other_node.edge_to?(edge_opposite_node)
      edge.exchange_node(self, other_node)
      other_node.add_incident(edge)
      merged_incidents << edge
    end
    @incidents -= merged_incidents

    new_pods = {}
    @pod_directions.each do |id, direction|
      constraint = @pod_constraints[id]
      new_pods[id] = other_node.add_pod(direction, constraint: constraint, id: id)
    end

    merged_adjacent_triangles = []
    @adjacent_triangles.each do |triangle|
      new_triangle = triangle.nodes - [self] + [other_node]
      next unless Graph.instance.find_surface(new_triangle).nil?
      triangle.exchange_node(self, other_node)
      other_node.add_adjacent_triangle(triangle)
      if triangle.cover?
        cover_pod = triangle.cover.pods.find { |pod| pods.include?(pod) }
        triangle.cover.exchange_pod(cover_pod, new_pods[cover_pod.id])
      end
      merged_adjacent_triangles << triangle
    end
    @adjacent_triangles -= merged_adjacent_triangles

    delete
  end

  def find_pod(direction)
    id, = @pod_directions.find do |_id, other_direction|
      direction.angle_between(other_direction) <= POD_ANGLE_THRESHOLD
    end
    @thingy.pods.find { |pod| pod.id == id }
  end

  def add_pod(direction = nil, constraint: true, id: nil)
    id = IdManager.instance.generate_next_id if id.nil?
    direction = direction.nil? ? Geometry::Z_AXIS.reverse : direction.normalize
    existing_pod = find_pod(direction)
    unless existing_pod.nil?
      @pod_constraints[existing_pod.id] |= constraint
      return existing_pod
    end
    @pod_directions[id] = direction
    @pod_constraints[id] = constraint
    @thingy.add_pod(self, @pod_directions[id], id: id)
  end

  def delete_pod(id)
    delete_pod_information(id)
    @thingy.delete_sub_thingy(id)
  end

  def delete_pod_information(id)
    @pod_directions.delete(id)
    @pod_constraints.delete(id)
  end

  def pod?(id)
    !@pod_directions[id].nil?
  end

  def delete
    super
    @incidents.clone.each(&:delete)
    @adjacent_triangles.clone.each do |triangle|
      triangle.delete unless triangle.deleted
    end
  end

  private

  def create_thingy(id)
    @thingy = Hub.new(@position, id: id)
  end
end
