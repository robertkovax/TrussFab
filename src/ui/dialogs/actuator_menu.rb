require 'src/tools/simulation_tool.rb'

class ActuatorMenu
  attr_accessor :sidebar_menu

  def initialize
    @HTML_FILE = '../piston-scheduler/build/index.html'
    @simulation_tool = SimulationTool.new(self)
    @width = 600
    @height = 300
  end

  def open_dialog(sidebar_menu_width , sidebar_menu_height)

    left = sidebar_menu_width
    top = sidebar_menu_height - @height

    props = {
      :resizable => false,
      :width => @width,
      :height => @height,
      :left => left,
      :top => top,
      :min_width => @width,
      :min_height => @height,
      :max_width => @width,
      :max_height => @height
    }

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), @HTML_FILE)
    @dialog.set_file(file)
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

  def set_dialog_size(width, height)
    @dialog.set_size(width, height)
  end

  def update_piston_group(movement_group)
    @dialog.execute_script("update_pistons(#{movement_group})")
  end

  def add_piston(id)
    @dialog.execute_script("addPiston(#{id})")
  end

  def stop_simulation
    @dialog.execute_script("cleanupUiAfterStoppingSimulation();")
  end

  def simulation_broke
    @dialog.execute_script("simulationJustBroke();")

    #make sure to only draw one line. Right now this would be triggered every frame after the
    #object broke.
    #Maybe have an instance variable in the simulation called @broken and the broken? function
    #only triggers if it was false or something like that
  end

  private

  def start_simulation_setup_scripts
    @sidebar_menu.deselect_tool

    Sketchup.active_model.select_tool(@simulation_tool)

    pistons = @simulation_tool.get_pistons
    breaking_force = @simulation_tool.get_breaking_force
    max_speed = @simulation_tool.get_max_speed
    stiffness = @simulation_tool.get_stiffness
    @dialog.execute_script("initState(#{breaking_force}, #{stiffness})")
  end

  def register_callbacks
    @dialog.add_action_callback('toggle_simulation') do |_context|
      if @simulation_tool.simulation.nil? || @simulation_tool.simulation.stopped?
        start_simulation_setup_scripts
      else
        stop_simulation
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

    @dialog.add_action_callback('change_peak_force_mode') do |_context, checked|
      @simulation_tool.change_peak_force_mode(checked)
    end

    @dialog.add_action_callback('apply_force') do |_context|
      @simulation_tool.pressurize_generic_link
    end

    # @dialog.add_action_callback('expand_actuator') do |_context, id|
    #   @simulation_tool.expand_actuator(id)
    # end

    # @dialog.add_action_callback('retract_actuator') do |_context, id|
    #   @simulation_tool.retract_actuator(id)
    # end

    @dialog.add_action_callback('move_joint') do |_context, id, next_value, duration|
      @simulation_tool.move_joint(id, next_value, duration)
    end

    @dialog.add_action_callback('stop_actuator') do |_context, id|
      @simulation_tool.stop_actuator(id)
    end

    @dialog.add_action_callback('set_dialog_size') do |_, width, height|
      set_dialog_size(width, height)
    end

    @dialog.add_action_callback('set_stiffness') do |_, stiffness|
      @simulation_tool.set_stiffness(stiffness)
    end
  end
end
