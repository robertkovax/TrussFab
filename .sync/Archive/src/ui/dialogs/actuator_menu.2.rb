require 'src/tools/simulation_tool.rb'

class ActuatorMenu
  attr_accessor :sidebar_menu

  def initialize
    @HTML_FILE = '../html/actuator_menu.erb'
    @simulation_tool = SimulationTool.new(self)

  end

  def open_dialog(sidebar_menu_width , sidebar_menu_height)
    width = 500
    height = 200

    left = sidebar_menu_width
    top = sidebar_menu_height - height

    props = {
      :resizable => false,
      :width => width,
      :height => height,
      :left => left,
      :top => top,
      :min_width => width,
      :min_height =>height,
      :max_width => width,
      :max_height => height
    }

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), @HTML_FILE)
    @dialog.set_file(file)
    # @dialog.set_size(Configuration::UI_WIDTH, Configuration::UI_HEIGHT)
    @dialog.set_position(left, top)
    @dialog.show

    register_callbacks
    @dialog
  end

  def close_dialog
    @dialog.close
  end

  def refresh
    file = File.join(File.dirname(__FILE__), @HTML_FILE)
    @dialog.set_file(file)
  end

  def update_piston_group(movement_group)
    @dialog.execute_script("update_pistons(#{movement_group})")
  end

  private

  def start_simulation_setup_scripts
    @sidebar_menu.deselect_tool

    Sketchup.active_model.select_tool(@simulation_tool)

    # TODO UPate clyce

    pistons = @simulation_tool.get_pistons
    breaking_force = @simulation_tool.get_breaking_force
    max_speed = @simulation_tool.get_max_speed
    @dialog.execute_script("showManualActuatorSettings(#{pistons.keys}, #{breaking_force}, #{max_speed})")

    @dialog.execute_script("showManualActuatorSettings(#{pistons.keys}, #{breaking_force}, #{max_speed})")

  end

  def register_callbacks
    puts 'register callbacks called'
    @dialog.add_action_callback('toggle_simulation') do |_context|
      if @simulation_tool.simulation.nil? || @simulation_tool.simulation.stopped?
        start_simulation_setup_scripts
      else
        Sketchup.active_model.select_tool(nil)
      end
    end

    @dialog.add_action_callback('restart_simulation') do |_context|
      @simulation_tool.restart
    end

    @dialog.add_action_callback('toggle_pause_simulation') do |_context|
      @simulation_tool.toggle_pause
    end

    @dialog.add_action_callback('change_piston_value') do |_context, id, new_value|
      @simulation_tool.change_piston_value(id, new_value)
    end

    @dialog.add_action_callback('test_piston') do |_context, id|
      @simulation_tool.test_piston(id)
    end

    @dialog.add_action_callback('set_breaking_force') do |_context, value|
      @simulation_tool.set_breaking_force(value)
    end

    @dialog.add_action_callback('set_max_speed') do |_context, value|
      @simulation_tool.set_max_speed(value)
    end

    @dialog.add_action_callback('change_highest_force_mode') do |_context, checked|
      @simulation_tool.change_highest_force_mode(checked)
    end

    @dialog.add_action_callback('stop_actuator') do |_context|
      p 'TODO: Stop actuator'
    end

    @dialog.add_action_callback('expand_actuator') do |_context|
      p 'TODO: expand_actuator'
    end

    @dialog.add_action_callback('retract_actuator') do |_context|
      p 'TODO: retract_actuator'
    end
  end
end
