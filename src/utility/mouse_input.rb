require 'set'

class MouseInput
  attr_reader :position, :snapped_graph_object, :snapped_pod

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
    unless @snapped_graph_object.nil? || @snapped_graph_object.thingy.nil?
      @snapped_graph_object.thingy.un_highlight
    end
    unless @snapped_pod.nil?
      @snapped_pod.un_highlight
    end
    @snapped_graph_object = nil
    @snapped_pod = nil
  end

  def update_positions(view, x, y)
    soft_reset

    input_point = Sketchup::InputPoint.new
    input_point.pick(view, x, y, Sketchup::InputPoint.new)

    @position = input_point.position
    snap_to_graph_object
    snap_to_pod

    @snapped_graph_object.thingy.highlight unless @snapped_graph_object.nil?
    @snapped_pod.highlight unless @snapped_pod.nil?
    @position = @snapped_graph_object.position if @snapped_graph_object
  end

  def out_of_snap_tolerance?(object)
    object.distance(@position) > Configuration::SNAP_TOLERANCE
  end

  def snap_to_graph_object
    graph_objects = Set.new
    if @snap_to_edges
      edge = Graph.instance.closest_edge(@position)
      graph_objects.add(edge) unless edge.nil? || out_of_snap_tolerance?(edge)
    end
    if @snap_to_nodes
      node = Graph.instance.closest_node(@position)
      graph_objects.add(node) unless node.nil? || out_of_snap_tolerance?(node)
    end
    if @snap_to_surfaces
      surface = Graph.instance.closest_surface(@position)
      unless surface.nil? || out_of_snap_tolerance?(surface)
        graph_objects.add(surface)
      end
    end
    return nil if graph_objects.empty?
    @snapped_graph_object = graph_objects.min_by do |graph_object|
      graph_object.distance(@position)
    end
  end

  def snap_to_pod
    if @snap_to_pods
      pod = Graph.instance.closest_pod(@position)
      unless pod.nil? || out_of_snap_tolerance?(pod)
        if @snapped_graph_object.distance(@position) > pod.distance(@position)
          @snapped_pod = pod
          @snapped_graph_object = nil
        end
      end
    end
  end
end
