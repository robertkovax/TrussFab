class ScaleOscillationTool < Tool
  SCALE_DELTA = 0.5.m

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
  end


  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)

    obj = @mouse_input.snapped_object
    # TODO: choose node dynamically
    user_node = Graph.instance.nodes[@ui.spring_pane.mounted_users.keys[0]]

    if !obj.nil? && obj.is_a?(Edge) && obj.link.is_a?(SpringLink)
      scale_user_node_for_spring_edge(user_node, obj)
    elsif !obj.nil? && obj.is_a?(Node) && obj.hub.is_user_attached
      @ui.spring_pane.spring_edges.each do |spring_edge|
        scale_user_node_for_spring_edge(user_node, spring_edge)
      end
    end

    # Compile, simulate and refresh motion path after changing geometry
    #@ui.spring_pane.compile
    ## Also update trace visualization to provide visual feedback to user
    #@ui.spring_pane.update_stats
    #@ui.spring_pane.update_dialog if @dialog
    #@ui.spring_pane.update_trace_visualization true

  end

  def scale_user_node_for_spring_edge(user_node, spring_edge)
    point = @ui.spring_pane.spring_hinges[spring_edge.id][:point]
    hinge_edge = Graph.instance.edges[@ui.spring_pane.spring_hinges[spring_edge.id][:edge_id]]
    plane = [point, hinge_edge.direction]
    projected_user_position = user_node.position.project_to_plane(plane)
    translation_vector = projected_user_position - point

    translation_vector.length = SCALE_DELTA
    # Adjust geometry
    new_position = user_node.position + translation_vector
    #user_node.move_to(new_position)
    user_node.update_position(new_position)
    user_node.hub.update_position(new_position)

    # Make link aware that it's actual length changed, meaning it's not compressed but actually a different link now
    spring_edge.link.initial_edge_length = spring_edge.length.to_f

    user_node.update_sketchup_object
    user_node.hub.update_user_indicator
    user_node.adjacent_triangles.each { |triangle| triangle.update_sketchup_object if triangle.cover }

    constpoint = Sketchup.active_model
                     .active_entities
                     .add_cpoint projected_user_position
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
