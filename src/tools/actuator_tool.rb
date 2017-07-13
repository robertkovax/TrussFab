require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/ball_joint_simulation.rb'

class ActuatorTool < Tool
  def initialize(ui)
    super
    @simulation = BallJointSimulation.new
    @mouse_input = MouseInput.new(snap_to_edges: true)
  end

  #
  # Sketchup Tool methods
  #

  def deactivate(view)
    Sketchup.active_model.active_view.animation = nil
    super
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    edge = @mouse_input.snapped_object
    return if edge.nil?
    if edge.link_type == 'actuator'
      edge.thingy.change_piston_group
    else
      Sketchup.active_model.start_operation('toggle edge to actuator', true)
      create_actuator(edge)
      view.invalidate
      Sketchup.active_model.commit_operation
    end
    # start_simulation(edge)
    # highlight_triangle_pairs
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def draw(_view) end

  #
  # Tool logic
  #

  def start_simulation(edge)
    @simulation.edge = edge
    @simulation.setup
    @simulation.start
    Sketchup.active_model.active_view.animation = @simulation
  end

  def create_actuator(edge)
    edge.link_type = 'actuator'
  end

  def highlight_triangle_pairs
  end
end