class ScaleOscillationTool < Tool
  SCALE_DELTA = 0.5.m

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
  end


  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Edge) && obj.link.is_a?(SpringLink)
      spring_edge = obj
      point = @ui.spring_pane.spring_hinges[spring_edge.id]
    elsif !obj.nil? && obj.is_a?(Node) && obj.hub.is_user_attached
      points = @ui.spring_pane.spring_hinges.map do | hinge |
        hinge[1]
      end

      x = y = z = 0

      points.each do |point|
        x += point.x
        y += point.y
        z += point.z
      end
      point = Geom::Point3d.new(x / points.length, y / points.length, z / points.length)
    end

    return unless point

    user_node = Graph.instance.nodes[@ui.spring_pane.mounted_users.keys[0]]
    scale_user_node_from_hinge(user_node, nil, point)

    # Compile, simulate and refresh motion path after changing geometry
    #@ui.spring_pane.compile
    ## Also update trace visualization to provide visual feedback to user
    #@ui.spring_pane.update_stats
    #@ui.spring_pane.update_dialog if @dialog
    #@ui.spring_pane.update_trace_visualization true

  end

  def scale_user_node_from_hinge(user_node, spring, hinge_point)
    translation_vector = user_node.position - hinge_point

    translation_vector.length = SCALE_DELTA
    # Adjust geometry
    new_position = user_node.position + translation_vector
    user_node.update_position(new_position)
    user_node.hub.update_position(new_position)
    user_node.update_sketchup_object
    user_node.hub.update_user_indicator
    user_node.adjacent_triangles.each { |triangle| triangle.update_sketchup_object if triangle.cover }

  end

end
