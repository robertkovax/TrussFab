require 'src/database/graph_object.rb'
require 'src/sketchup_objects/hub.rb'
require 'src/sketchup_objects/hub_entities/pod.rb'

# Node
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

  def hub
    @sketchup_object
  end

  # This only updates the position variable, e.g. to let the MouseInput know
  # where the Node is
  def update_position(position)
    @position = position
    hub.position = position
  end

  def move_to(position)
    Sketchup.active_model.start_operation('move node and relax', true)
    relaxation = Relaxation.new
    relaxation.move_and_fix_node(self, position)
    relaxation.relax
    hub.update_position position
    Sketchup.active_model.commit_operation
  end

  # Moves all connected components
  # this is very slow. Only do this if necessary (i.e. not in simulation)
  # It is important to first update the hubs, as some edges will use the hub
  def update_sketchup_object
    pods.each { |pod| pod.update_position(@position) }
    hub.update_position @position
    @incidents.each(&:update_sketchup_object)
    @adjacent_triangles.each(&:update_sketchup_object)
  end

  def distance(point)
    @position.distance(point)
  end

  def vector_to(other_node)
    @position.vector_to(other_node.position)
  end

  def pods
    hub.pods
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
    pods.any?(&:is_fixed)
  end

  def frozen?
    # TODO: check if node is frozen by context menu, manually saving this node
    # and connected edges from being changed
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

  def incident?(edge)
    @incidents.include?(edge)
  end

  def adjacent?(node)
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

  def connected_component
    return if @incidents.empty?

    @incidents[0].connected_component
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
    # @pod_directions.each do |id, direction|
    #   constraint = @pod_constraints[id]
    #   new_pods[id] = other_node.add_pod(direction, constraint: true, id: id)
    # end

    merged_adjacent_triangles = []
    @adjacent_triangles.each do |triangle|
      new_triangle = triangle.nodes - [self] + [other_node]
      next unless Graph.instance.find_triangle(new_triangle).nil?

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
    Graph.instance.cleanup
  end

  def find_pod(direction)
    id, = pods.find do |pod|
      direction.angle_between(pod.direction) <= POD_ANGLE_THRESHOLD
    end
    hub.pods.find { |pod| pod.id == id }
  end

  def add_pod(direction = nil, is_fixed: true, id: nil)
    id = IdManager.instance.generate_next_id if id.nil?
    direction = direction.nil? ? Geometry::Z_AXIS.reverse : direction.normalize
    existing_pod = find_pod(direction)
    return existing_pod unless existing_pod.nil?

    hub.add_pod(direction, id: id, is_fixed: is_fixed)
  end

  def delete_pod(id)
    hub.delete_child(id)
  end

  def pod?(id)
    pods.any? { |pod| pod.id == id }
  end

  def delete
    if !hub.nil? && hub.has_addons?
      hub.delete_addons
      return
    end
    super
    @incidents.clone.each(&:delete)
    @adjacent_triangles.clone.each do |triangle|
      triangle.delete unless triangle.deleted
    end
  end

  def inspect
    "Node #{@id}: " + @position.to_s
  end

  private

  def create_sketchup_object(id)
    @sketchup_object = Hub.new(@position, id: id, incidents: incidents)
  end

  def dangling?
    @incidents.empty?
  end
end
