module NodeExportVisualization

  public
  def NodeExportVisualization.visualize(export_interface)
    export_interface.hinges.each do |hinge|
      visualize_hinge(hinge)
    end

    hinge_layer = Sketchup.active_model.layers.at(Configuration::HINGE_VIEW)
    hinge_layer.visible = true

    # shorten elongations for all edges that are not part of the main hub
    nodes = Graph.instance.nodes.values
    nodes.each do |node|
      non_mainhub_edges = export_interface.non_mainhub_edges_at_node(node)
      non_mainhub_edges.each do |edge|
        disconnect_edge_from_hub(edge, node)
      end
    end

    # color static groups differently
    group_nr = 0
    export_interface.static_groups.reverse.each do |group|
      color_group(group, group_nr)
      group_nr += 1
    end
  end

  private
  def NodeExportVisualization.color_group(group, group_nr)
    group_color = case group_nr
                  when 0; '1f78b4' # dark blue
                  when 1; 'e31a1c' # dark red
                  when 2; 'ff7f00' # dark orange
                  when 3; '984ea3' # purple
                  when 4; 'a65628' # brown
                  when 5; 'a6cee3' # light blue
                  when 6; 'e78ac3' # pink
                  when 7; 'fdbf6f' # light orange
                  else
                    format('%06x', rand * 0xffffff)
                  end

    group.each do |triangle|
      triangle.edges.each do |edge|
        edge.thingy.change_color(group_color)
      end
    end
  end

  def NodeExportVisualization.disconnect_edge_from_hub(rotating_edge, node)
    if rotating_edge.first_node?(node)
      rotating_edge.thingy.disconnect_from_hub(true)
    else
      rotating_edge.thingy.disconnect_from_hub(false)
    end
  end

  def NodeExportVisualization.visualize_hinge(hinge)
    rotation_axis = hinge.edge1
    rotating_edge = hinge.edge2
    node = rotating_edge.shared_node(rotation_axis)

    mid_point1 = Geom::Point3d.linear_combination(0.7,
                                                  node.position,
                                                  0.3,
                                                  rotation_axis.mid_point)
    mid_point2 = Geom::Point3d.linear_combination(0.7,
                                                  node.position,
                                                  0.3,
                                                  rotating_edge.mid_point)

    # Draw hinge visualization
    mid_point = Geom::Point3d.linear_combination(0.5, mid_point2,
                                                 0.5, mid_point1)

    if hinge.is_double_hinge
      mid_point = Geom::Point3d.linear_combination(0.75, mid_point,
                                                   0.25, node.position)
    end

    line1 = Line.new(mid_point, mid_point1, HINGE_LINE)
    line2 = Line.new(mid_point, mid_point2, HINGE_LINE)

    rotating_edge.thingy.add(line1, line2)
  end
end
