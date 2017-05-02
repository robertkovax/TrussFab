require 'set'

class MouseInput
  attr_reader :position, :snapped_thingy

  def initialize(snap_to_nodes: false, snap_to_edges: false, snap_to_surfaces: false, highlight: true)
    @snap_to_nodes = snap_to_nodes
    @snap_to_edges = snap_to_edges
    @snap_to_surfaces = snap_to_surfaces
    @highlight = highlight
    soft_reset
  end

  def soft_reset
    @position = nil
    @snapped_thingy.un_highlight if @snapped_thingy
    @snapped_thingy = nil
  end

  def update_positions(view, x, y)
    soft_reset

    input_point = Sketchup::InputPoint.new
    input_point.pick(view, x, y, Sketchup::InputPoint.new)

    @position = input_point.position
    snap_to_closest_thingy
    @snapped_thingy.highlight if @snapped_thingy
    @position = @snapped_thingy.position if @snapped_thingy
  end

  def out_of_snap_tolerance?(graph_obj)
    graph_obj.distance(@position) > Configuration::SNAP_TOLERANCE
  end

  def snap_to_closest_thingy
    thingies = Set.new
    if @snap_to_edges
      edge = Graph.instance.closest_edge(@position)
      thingies.add(edge) unless edge.nil? || out_of_snap_tolerance?(edge)
    end
    if @snap_to_nodes
      node = Graph.instance.closest_node(@position)
      thingies.add(node) unless node.nil? || out_of_snap_tolerance?(node)
    end
    if @snap_to_surfaces
      surface = Graph.instance.closest_surface(@position)
      thingies.add(surface) unless surface.nil? || out_of_snap_tolerance?(surface)
    end
    return nil if thingies.empty?
    @snapped_thingy = thingies.min_by { |thingy| thingy.distance(@position) }
  end
end
