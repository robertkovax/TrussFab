require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/algorithms/rigidity_tester.rb'
require 'src/simulation/thingy_rotation.rb'

class ActuatorTool < Tool

  MIN_ANGLE_DEVIATION = 0.05

  def initialize(ui)
    super
    @mouse_input = MouseInput.new(snap_to_edges: true)
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
    @edge = @mouse_input.snapped_object
    return if @edge.nil?
    create_actuator(view)
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  #
  # Tool logic
  #

  def create_actuator(view)
    Sketchup.active_model.start_operation('toggle edge to actuator', true)
    @edge.link_type = 'actuator'
    view.invalidate
    Sketchup.active_model.commit_operation
  end
end
