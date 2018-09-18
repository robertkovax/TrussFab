require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/configuration/configuration.rb'

# Starts the simulation
class SimulationTool < Tool
  attr_reader :simulation, :breaking_force, :peak_force_mode,
              :highest_force_mode, :display_values, :stiffness

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_nodes: true,
                                  snap_to_edges: true,
                                  should_highlight: false)
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
    Sketchup.active_model.start_operation('activate simulation', true)
    @simulation = Simulation.new(@ui)
    @simulation.setup
    setup_simulation_parameters
    @simulation.open_sensor_dialog
    @auto_piston_group = @simulation.auto_piston_group
    Sketchup.active_model.active_view.animation = @simulation
    @simulation.start
    Sketchup.active_model.commit_operation
  end

  def deactivate(_ui)
    Sketchup.active_model.start_operation('deactivate simulation', true)
    @simulation.stop
    @simulation.reset
    @simulation.close_sensor_dialog
    @simulation = nil
    @ui.stop_simulation
    Sketchup.active_model.commit_operation
  end

  def pause_simulation
    return if @simulation.nil?
    @simulation.pause
  end

  def unpause_simulation
    return if @simulation.nil?
    @simulation.unpause
  end

  def restart
    return if @simulation.nil?
    @simulation.restart
  end

  def apply_force
    return unless @moving
    @start_position = @node.hub.body.get_position(1)
    @end_position = @mouse_input.position
    force = @start_position.vector_to(@end_position)
    force.length *= Configuration::DRAG_FACTOR unless force.length.zero?
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
    elsif obj.is_a?(Edge) && obj.link.is_a?(ActuatorLink)
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
    @ui.simulation_broke if !simulation.nil? && @simulation.broken?

    apply_force

    return if @start_position.nil? || @end_position.nil?
    Sketchup.active_model.start_operation('SimTool: Draw', true)
    view.line_stipple = '_'
    view.draw_lines(@start_position, @end_position)
    force_value = (@start_position.vector_to(@end_position).length *
                  Configuration::DRAG_FACTOR).round(1).to_s
    point = Geometry.midpoint(@start_position, @end_position)
    if @force.nil?
      @force = Sketchup.active_model.entities.add_text(force_value, point)
    else
      @force.text = force_value
      @force.point = point
    end
    Sketchup.active_model.commit_operation
  end

  # Simulation Getters
  def pistons
    @simulation.pistons
  end

  def change_piston_value(id, value)
    @simulation.grouped_change_piston_value(id, value) unless @simulation.nil?
  end

  def test_piston(id)
    @simulation.moving_pistons.push(id: id.to_i, expanding: true, speed: 0.2)
  end

  def breaking_force=(param)
    @breaking_force = param.to_f
    setup_simulation_parameters
  end

  def max_speed=(param)
    @simulation.max_speed = param.to_f unless @simulation.nil?
  end

  def stiffness=(param)
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

  def change_display_values(param)
    @display_values = param
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
              '#E64D66', '#4DB380', '#FF4D4D', '#99E6E6', '#6666FF']
    # we don't want to create more groups than we have pistons
    # NB: piston_group is initialized with -1 so we have add one to
    # compare to size
    link = edge.link
    return if link.piston_group + 1 >= @simulation.pistons.length
    link.piston_group += 1

    if @simulation.auto_piston_group[link.piston_group].nil?
      @simulation.auto_piston_group[link.piston_group] = []
      @ui.update_piston_group(link.piston_group)
    end

    unless link.piston_group.zero?
      @simulation.auto_piston_group[link.piston_group - 1]
                 .delete(edge)
    end

    @simulation.auto_piston_group[link.piston_group].push(edge)
    mat = @simulation.bottle_dat[link][3]
    mat.color = colors[link.piston_group]
    # persist the piston group array
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
