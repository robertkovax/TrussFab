require 'src/database/graph_object.rb'
require 'src/thingies/hub.rb'
require 'src/thingies/hub_entities/pod.rb'

class Node < GraphObject
  attr_accessor :original_position
  attr_reader :position, :incidents, :adjacent_triangles

  POD_ANGLE_THRESHOLD = 0.2

  def initialize(position, id: nil)
    @deleting = false
    @position = position
    @original_position = position
    @incidents = []             # connected edges
    @adjacent_triangles = []    # connected triangles
    node_id = id.nil? ? IdManager.instance.generate_next_tag_id('node') : id
    super(node_id)
  end

  # This only updates the position variable, e.g. to let the MouseInput know
  # where the Node is
  def update_position(position)
    @position = position
    @thingy.position = position
  end

  # Moves all connected components
  # this is very slow. Only do this if necessary (i.e. not in simulation)
  def update_thingy
    @incidents.each(&:update_thingy)
    @adjacent_triangles.each(&:update_thingy)
    @thingy.entity.move!(Geom::Transformation.new(@position))
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

  def pod_export_info
    export_pods = []

    pods.each do |pod|
      pod_info = {}
      pod_info['direction'] = pod.direction
      pod_info['is_fixed'] = pod.is_fixed
      export_pods.push(pod_info)
    end

    export_pods
  end

  def pod(id)
    possible_pods = pods.select { |pod| pod.id == id }
    raise "Node #{@id} does not have exactly one pod" if possible_pods.size != 1
    possible_pods.first
  end

  def fixed?
    pods.any? { |pod| pod.is_fixed }
  end

  def frozen?
    # TODO: check if node is frozen by context menu, manually saving this node and connected edges from being changed
    false
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

    # TODO: fix merging of pods
    new_pods = {}
    #@pod_directions.each do |id, direction|
    #  constraint = @pod_constraints[id]
    #  new_pods[id] = other_node.add_pod(direction, constraint: true, id: id)
    #end

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
    id, = pods.find do |pod|
      direction.angle_between(pod.direction) <= POD_ANGLE_THRESHOLD
    end
    @thingy.pods.find { |pod| pod.id == id }
  end

  def add_pod(direction = nil, is_fixed: true, id: nil)
    id = IdManager.instance.generate_next_id if id.nil?
    direction = direction.nil? ? Geometry::Z_AXIS.reverse : direction.normalize
    existing_pod = find_pod(direction)
    unless existing_pod.nil?
      return existing_pod
    end
    @thingy.add_pod(direction, id: id, is_fixed: is_fixed)
  end

  def delete_pod(id)
    @thingy.delete_sub_thingy(id)
  end

  def pod?(id)
    pods.any? { |pod| pod.id == id }
  end

  def delete
    super
    @incidents.clone.each(&:delete)
    @adjacent_triangles.clone.each do |triangle|
      triangle.delete unless triangle.deleted
    end
  end

  def inspect
    "Node: " + @position.to_s
  end

  private

  def create_thingy(id)
    @thingy = Hub.new(@position, id: id, incidents: incidents)
  end
end
