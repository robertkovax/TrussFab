require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/configuration/configuration.rb'

class SimulationTool < Tool

  attr_reader :simulation

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true, snap_to_edges: true, should_highlight: false)
    @move_mouse_input = nil

    @node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
    @force = nil
    @auto_piston_group = []

    # simulation parameters
    @breaking_force = Configuration::JOINT_BREAKING_FORCE
    @peak_force_mode = false
    @highest_force_mode = false
    @display_values = false
    @stiffness = Configuration::JOINT_STIFFNESS
  end

  def setup_simulation_parameters
    return if @simulation.nil?
    @simulation.breaking_force = @breaking_force
    @simulation.peak_force_mode = @peak_force_mode
    @simulation.highest_force_mode = @highest_force_mode
    @simulation.stiffness = @stiffness
  end


  def activate
    @simulation = Simulation.new
    setup_simulation_parameters
    @simulation.setup
    @simulation.open_sensor_dialog
    @simulation.auto_piston_group = @auto_piston_group
    Sketchup.active_model.active_view.animation = @simulation
    @simulation.start
  end

  def deactivate(ui)
    @simulation.stop
    @simulation.reset
    @simulation.close_sensor_dialog
    @simulation.close_automatic_movement_dialog
    @simulation = nil
    @ui.stop_simulation
  end

  def toggle_pause
    return if @simulation.nil?
    @simulation.toggle_pause
  end

  def restart
    return if @simulation.nil?
    @simulation.restart
  end

  def apply_force(view)
    return unless @moving
    @start_position = @node.thingy.body.get_position(1)
    @end_position = @mouse_input.position
    force = @start_position.vector_to(@end_position)
    force.length *= Configuration::DRAG_FACTOR unless force.length == 0
    @simulation.add_force_to_node(@node, force)
  end

  def update(view, x, y)
    @mouse_input.update_positions(
      view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )
  end

  def reset
    @node = nil
    @start_position = nil
    @end_position = nil
    @moving = false
    @force.text = ''
    @force = nil
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    obj = @mouse_input.snapped_object
    return if obj.nil?
    if obj.is_a?(Node)
      @moving = true
      @node = obj
      @start_position = @end_position = @mouse_input.position
    elsif obj.thingy.is_a?(ActuatorLink)
      toggle_piston_group(obj)
    end
  end

  def onMouseMove(_flags, x, y, view)
    update(view, x, y)
  end

  def onLButtonUp(_flags, x, y, view)
    update(view, x, y)
    return unless @moving
    @end_position = @mouse_input.position
    reset
  end

  def draw(view)
    if !simulation.nil? && @simulation.broken?
      @ui.simulation_broke
    end

    view.model.start_operation('SimTool: Apply Force', true)
    apply_force(view)
    view.model.commit_operation

    return if @start_position.nil? || @end_position.nil?
    view.model.start_operation('SimTool: Draw', true)
    view.line_stipple = '_'
    view.draw_lines(@start_position, @end_position)
    force_value = (@start_position.vector_to(@end_position).length * Configuration::DRAG_FACTOR).round(1).to_s
    point = Geometry.midpoint(@start_position, @end_position)
    if @force.nil?
      @force = view.model.entities.add_text(force_value, point)
    else
      @force.text = force_value
      @force.point = point
    end
    view.model.commit_operation
  end

  # Simulation Getters
  def get_pistons
    @simulation.pistons
  end

  def get_breaking_force
    @simulation.breaking_force
  end

  def get_max_speed
    @simulation.max_speed
  end

  def get_stiffness
    @simulation.stiffness
  end

  def change_piston_value(id, value)
    @simulation.change_piston_value(id, value) unless @simulation.nil?
  end

  def test_piston(id)
    @simulation.moving_pistons.push({:id=>id.to_i, :expanding=>true, :speed=>0.2})
  end

  def set_breaking_force(param)
    @breaking_force = param.to_f
    setup_simulation_parameters
  end

  def set_max_speed(param)
    @simulation.max_speed = param.to_f unless @simulation.nil?
  end

  def set_stiffness(param)
    @stiffness = param.to_f / 100
    setup_simulation_parameters
  end

  def change_highest_force_mode(param)
    @highest_force_mode = param
    setup_simulation_parameters
  end

  def change_peak_force_mode(param)
    @peak_force_mode = param
    setup_simulation_parameters
  end

  def pressurize_generic_link
    @simulation.apply_force unless @simulation.nil?
  end

  def toggle_piston_group(edge)
    colors = ['#FF6633', '#FFB399', '#FF33FF', '#FFFF99', '#00B3E6',
              '#E6B333', '#3366E6', '#999966', '#99FF99', '#B34D4D',
              '#80B300', '#809900', '#E6B3B3', '#6680B3', '#66991A',
              '#FF99E6', '#CCFF1A', '#FF1A66', '#E6331A', '#33FFCC',
              '#66994D', '#B366CC', '#4D8000', '#B33300', '#CC80CC',
              '#66664D', '#991AFF', '#E666FF', '#4DB3FF', '#1AB399',
              '#E666B3', '#33991A', '#CC9999', '#B3B31A', '#00E680',
              '#4D8066', '#809980', '#E6FF80', '#1AFF33', '#999933',
              '#FF3380', '#CCCC00', '#66E64D', '#4D80CC', '#9900B3',
              '#E64D66', '#4DB380', '#FF4D4D', '#99E6E6', '#6666FF'];
    # we don't want to create more groups than we have pistons
    # NB: automatic_movement_group is initialized with -1 so we have add one to compare to size
    return if edge.automatic_movement_group + 1 >= @simulation.pistons.length
    edge.automatic_movement_group += 1
    if @simulation.auto_piston_group[edge.automatic_movement_group].nil?
      @simulation.auto_piston_group[edge.automatic_movement_group] = []
      @ui.update_piston_group(edge.automatic_movement_group)
    end
    @simulation.auto_piston_group[edge.automatic_movement_group - 1].delete(edge) unless edge.automatic_movement_group == 0
    @simulation.auto_piston_group[edge.automatic_movement_group].push(edge)
    link = edge.thingy
    mat = @simulation.bottle_dat[link][3]
    mat.color = colors[edge.automatic_movement_group]
    # persist the piston gropu array
    @auto_piston_group = @simulation.auto_piston_group
  end

  def expand_actuator(group_id)
    @simulation.expand_actuator(group_id)
  end

  def retract_actuator(group_id)
    @simulation.retract_actuator(group_id)
  end

  def move_joint(id, new_value, duration)
    @simulation.move_joint(id, new_value, duration) unless @simulation.nil?
  end

  def stop_actuator(group_id)
    @simulation.stop_actuator(group_id)
  end
end
