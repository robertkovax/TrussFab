require 'set'

class MouseInput
  attr_reader :position, :snapped_thingy

  def initialize(snap_to_nodes: false, snap_to_edges: false, snap_to_surfaces: false)
    @snap_to_nodes = snap_to_nodes
    @snap_to_edges = snap_to_edges
    @snap_to_surfaces = snap_to_surfaces
    soft_reset
  end

  def soft_reset
    @position = nil
    @snapped_thingy = nil
  end

  def update_positions(view, x, y)
    soft_reset

    input_point = Sketchup::InputPoint.new
    input_point.pick(view, x, y, Sketchup::InputPoint.new)

    @position = input_point.position
    snap_to_closest_thingy
    @position = @snapped_thingy.position if @snapped_thingy
  end

  def snap_to_closest_thingy
    thingies = Set.new
    if @snap_to_edges
      edge = Graph.instance.closest_edge(@position)
      thingies.add(edge) unless edge.nil? || edge.distance(@position) > Configuration::SNAP_TOLERANCE
    end
    if @snap_to_nodes
      node = Graph.instance.closest_node(@position)
      thingies.add(node) unless node.nil? || node.distance(@position) > Configuration::SNAP_TOLERANCE
    end
    if @snap_to_surfaces
      surface = Graph.instance.closest_surface(@position)
      thingies.add(surface) unless surface.nil? ||  surface.distance(@position) > Configuration::SNAP_TOLERANCE
    end
    return nil if thingies.empty?
    closest_thingy = thingies.first
    thingies.each do |thingy|
      closest_thingy = thingy if thingy.distance(@position) < closest_thingy.distance(@position)
    end
    @snapped_thingy = closest_thingy
  end
end
