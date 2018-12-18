require 'src/tools/simulation_tool.rb'

# Ruby integration for animation pane js
class AnimationPane
  attr_accessor :sidebar_menu, :animation_values
  HTML_FILE = '../animation-pane/build/index.html'.freeze

  def initialize
    @simulation_tool = SimulationTool.new(self)
    @width = 455
    @dev_width = 570 # for dev
    @height = 300

    @collapsed = false
    @dev_mode = true
    @collapsed_width = 53
    @animation_values = []
  end

  def open_dialog(sidebar_menu_width, sidebar_menu_height)
    left = sidebar_menu_width + 5
    top = sidebar_menu_height - @height

    props = {
      # resizable: false,
      preferences_key: 'com.trussfab.animation_pane',
      width: @dev_width,
      height: @height,
      left: left,
      top: top,
      min_width: @dev_width,
      # min_height: @height,
      max_width: @dev_width,
      # max_height: @height
    }

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), HTML_FILE)
    @dialog.set_file(file)
    @dialog.show

    register_callbacks
    @dialog
  end

  def close_dialog
    @dialog.close
  end

  def refresh
    file = File.join(File.dirname(__FILE__), HTML_FILE)
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

  def add_piston_with_animation(animation)
    @dialog.execute_script("addPistonWithAnimation(#{animation})")
  end

  def stop_simulation
    @dialog.execute_script('cleanupUiAfterStoppingSimulation();')
  end

  def simulation_broke
    @dialog.execute_script('simulationJustBroke();')
  end

  def sync_hidden_status(map)
    @dialog.execute_script("syncHiddenStatus(#{map.to_json})")
  end

  # a factor of 1 fits, if Sketchup runs with 60fps. If it runs with 30fps, the
  # factor has to be 0.5
  def change_timeline_factor(factor)
    @dialog.execute_script("changeTimelineFactor(#{factor})")
  end

  def toggle_dev_mode
    if @dev_mode
      @dialog.set_size(@width, @height)
      @dev_mode = false
    else
      @dialog.set_size(@dev_width, @height)
      @dev_mode = true
    end
    @dialog.execute_script('toggleDevMode()')
  end

  private

  def set_simulation_parameters
    breaking_force = @simulation_tool.breaking_force
    stiffness = @simulation_tool.stiffness
    display_values = @simulation_tool.display_values
    highest_force_mode = @simulation_tool.highest_force_mode
    peak_force_mode = @simulation_tool.peak_force_mode
	timesteps = @simulation_tool.timesteps
    @dialog.execute_script("initSimulationState(#{breaking_force},
                                                #{stiffness} * 100,
                                                #{display_values},
                                                #{highest_force_mode},
                                                #{peak_force_mode},
												#{timesteps})")
  end

  def start_simulation_setup_scripts
    @sidebar_menu.deselect_tool

    Sketchup.active_model.select_tool(@simulation_tool)
    set_simulation_parameters
  end

  def register_callbacks
    @dialog.add_action_callback('animation_pane_toggle') do |_|
      if @collapsed
        @dialog.set_size(@width, @height)
      else
        @dialog.set_size(@collapsed_width, @height)
      end
      @collapsed = !@collapsed
    end

    @dialog.add_action_callback('start_simulation') do |_context|
      if @simulation_tool.simulation.nil? ||
         @simulation_tool.simulation.stopped?
        start_simulation_setup_scripts
      end
    end

    @dialog.add_action_callback('stop_simulation') do |_context|
      unless @simulation_tool.simulation.nil? || stop_simulation
        Sketchup.active_model.select_tool(nil)
      end
    end

    @dialog.add_action_callback('restart_simulation') do |_context|
      @simulation_tool.restart
    end

    @dialog.add_action_callback('pause_simulation') do |_context|
      @simulation_tool.pause_simulation
    end

    @dialog.add_action_callback('unpause_simulation') do |_context|
      @simulation_tool.unpause_simulation
    end

    @dialog.add_action_callback('change_piston_value') do |_, id, new_value|
      @simulation_tool.change_piston_value(id, new_value)
    end

    @dialog.add_action_callback('test_piston') do |_context, id|
      @simulation_tool.test_piston(id)
    end

    @dialog.add_action_callback('set_breaking_force') do |_context, value|
      @simulation_tool.breaking_force = value
    end

    @dialog.add_action_callback('set_max_speed') do |_context, value|
      @simulation_tool.max_speed = value
    end

    @dialog.add_action_callback('change_highest_force_mode') do |_ctx, checked|
      @simulation_tool.change_highest_force_mode(checked)
    end

    @dialog.add_action_callback('change_peak_force_mode') do |_context, checked|
      @simulation_tool.change_peak_force_mode(checked)
    end

    @dialog.add_action_callback('change_display_values') do |_context, checked|
      @simulation_tool.change_display_values(checked)
    end
	
	@dialog.add_action_callback('change_simulation_timesteps') do |_context, value|
      @simulation_tool.simulation_timesteps = value
    end
	
    @dialog.add_action_callback('apply_force') do |_context|
      @simulation_tool.pressurize_generic_link
    end

    @dialog.add_action_callback('persist_keyframes') do |_ctx, keyframes|
      @animation_values = keyframes
    end

    @dialog.add_action_callback('move_joint') do |_, id, next_value, duration|
      @simulation_tool.move_joint(id, next_value, duration)
    end

    @dialog.add_action_callback('stop_actuator') do |_context, id|
      @simulation_tool.stop_actuator(id)
    end

    @dialog.add_action_callback('set_dialog_size') do |_, width, height|
      set_dialog_size(width, height)
    end

    @dialog.add_action_callback('set_stiffness') do |_, stiffness|
      @simulation_tool.stiffness = stiffness
    end

    @dialog.add_action_callback('on_load') do |_context|
      set_simulation_parameters
    end
  end
end
