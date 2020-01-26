require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'

class RagdollTool < Tool
  def initialize(ui)
    super(ui)

    link_type = 'bottle_link';
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
    @link_type = link_type
    @edge = nil
  end

  #
  # Sketchup Tool methods
  #

  def deactivate(view)
    super
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    create_ragdoll(@mouse_input.update_positions(view, x, y))
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  #
  # Tool logic
  #
  #
  def create_ragdoll(position)
    # create body
    lower_end = create_body(position)

    # head
    create_limb(position, Geom::Vector3d.new(0, 0, 1), 20.cm)

    # two arms
    create_limb(position, Geom::Vector3d.new(1, 0, 0), 38.5.cm)
    create_limb(position, Geom::Vector3d.new(-1, 0, 0), 38.5.cm)

    # two legs
    create_limb(lower_end, Geom::Vector3d.new(1, 0, -1).normalize, 47.cm)
    create_limb(lower_end, Geom::Vector3d.new(-1, 0, -1).normalize, 47.cm)
  end

  def create_body(position, length = 36.cm)
    upper_end = position
    direction = Geom::Vector3d.new(0, 0, -1)
    direction.length = length
    lower_end = position + direction
    Sketchup.active_model.start_operation("Create ragdoll link", true)
    @edge = Graph.instance.create_edge_from_points(upper_end,
                                                   lower_end,
                                                   link_type: @link_type,
                                                   use_best_model: true)
    Sketchup.active_model.commit_operation
    lower_end
  end

  def create_limb(position, direction, length = 38.5.cm)
    body_end = position
    direction.length = length
    hand_end = position + direction
    Sketchup.active_model.start_operation("Create ragdoll link", true)
    @edge = Graph.instance.create_edge_from_points(body_end,
                                                   hand_end,
                                                   link_type: @link_type,
                                                   use_best_model: true)
    Sketchup.active_model.commit_operation
  end


end
