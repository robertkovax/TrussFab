require 'set'

class MouseInput
  attr_reader :position, :snapped_object

  def initialize(snap_to_nodes: false, snap_to_edges: false, snap_to_surfaces: false, snap_to_pods: false)
    @snap_to_nodes = snap_to_nodes
    @snap_to_edges = snap_to_edges
    @snap_to_surfaces = snap_to_surfaces
    @snap_to_pods = snap_to_pods
    @position = nil
    soft_reset
  end

  def soft_reset
    @position = nil
    unless @snapped_object.nil?
      @snapped_object.un_highlight
    end
    @snapped_object = nil
  end

  def update_positions(view, x, y)
    soft_reset

    input_point = Sketchup::InputPoint.new
    input_point.pick(view, x, y, Sketchup::InputPoint.new)

    @position = input_point.position
    snap_to_object

    @snapped_object.highlight unless @snapped_object.nil?
    @position = @snapped_object.position if @snapped_object
  end

  def out_of_snap_tolerance?(object)
    object.distance(@position) > Configuration::SNAP_TOLERANCE
  end

  def snap_to_object
    objects = Set.new
    if @snap_to_edges
      edge = Graph.instance.closest_edge(@position)
      objects.add(edge) unless edge.nil? || out_of_snap_tolerance?(edge)
    end
    if @snap_to_nodes
      node = Graph.instance.closest_node(@position)
      objects.add(node) unless node.nil? || out_of_snap_tolerance?(node)
    end
    if @snap_to_surfaces
      surface = Graph.instance.closest_surface(@position)
      unless surface.nil? || out_of_snap_tolerance?(surface)
        objects.add(surface)
      end
    end
    if @snap_to_pods
      pod = Graph.instance.closest_pod(@position)
      unless pod.nil? || out_of_snap_tolerance?(pod)
        objects.add(pod)
      end
    end
    return nil if objects.empty?
    @snapped_object = objects.min_by do |graph_object|
      graph_object.distance(@position)
    end
  end
end
