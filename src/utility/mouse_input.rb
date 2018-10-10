require 'set'

# Used to handle mouse pointer related issue, can snap to objects,
# maps input points to useful ones.
class MouseInput
  attr_reader :position, :snapped_object

  def initialize(snap_to_nodes: false,
                 snap_to_edges: false,
                 snap_to_surfaces: false,
                 snap_to_pods: false,
                 snap_to_covers: false,
                 should_highlight: true)
    @snap_to_nodes = snap_to_nodes
    @snap_to_edges = snap_to_edges
    @snap_to_surfaces = snap_to_surfaces
    @snap_to_pods = snap_to_pods
    @snap_to_covers = snap_to_covers
    @position = nil
    @should_highlight = should_highlight
    @snapping_disabled = false
    soft_reset
  end

  def soft_reset
    @position = nil
    unless @snapped_object.nil? ||
           @snapped_object.deleted? ||
           !@should_highlight
      @snapped_object.un_highlight
    end
    @snapped_object = nil
  end

  def disable_snapping
    @snapping_disabled = true
  end

  def enable_snapping
    @snapping_disabled = false
  end

  # NB: In the old version, there was given a reference point to the InputPoint
  # but it was not clear why.
  def update_positions(view, x, y, point_on_plane_from_camera_normal: nil)
    soft_reset

    input_point = Sketchup::InputPoint.new
    input_point.pick(view, x, y, Sketchup::InputPoint.new)
    @position = input_point.position

    snap_to_object
    @snapped_object.highlight unless @snapped_object.nil? || !@should_highlight
    @position = @snapped_object.position if @snapped_object

    # For some reason, we don't have to find the intersection on the plane if
    # it finds objects to snap on.
    if !point_on_plane_from_camera_normal.nil? && !@snapped_object
      # pick a point on the plane of the camera normal
      normal = view.camera.direction
      plane = [point_on_plane_from_camera_normal, normal]
      pickray = view.pickray(x, y)
      @position = Geom.intersect_line_plane(pickray, plane)
    end

    @position
  end

  def out_of_snap_tolerance?(object)
    object.distance(@position) > Configuration::SNAP_TOLERANCE
  end

  def should_snap?(object)
    !(object.nil? || out_of_snap_tolerance?(object) || @snapping_disabled)
  end

  def snap_to_object
    objects = []
    if @snap_to_pods
      pod = Graph.instance.closest_pod(@position)
      objects.push(pod) if should_snap?(pod)
    end
    if @snap_to_nodes
      node = Graph.instance.closest_node(@position)
      objects.push(node) if should_snap?(node)
    end
    if @snap_to_edges
      edge = Graph.instance.closest_edge(@position)
      objects.push(edge) if should_snap?(edge)
    end
    if @snap_to_surfaces
      surface = Graph.instance.closest_triangle(@position)
      objects.push(surface) if should_snap?(surface)
    end
    if @snap_to_covers
      surface = Graph.instance.closest_triangle(@position)
      objects.push(surface.cover) if should_snap?(surface) && surface.cover?
    end
    return if objects.empty?
    @snapped_object = objects.first
  end
end
