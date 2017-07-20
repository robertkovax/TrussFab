require 'json'
require 'src/tools/tool'
require 'src/simulation/simulation'
require 'src/simulation/piston_scheduler'

class TimelineTool < Tool
  def initialize(ui)
    super
    @timeline_dialog = nil
    @simulation = nil
    @piston_scheduler = PistonScheduler.new
    @mouse_input = MouseInput.new(snap_to_edges: true)
    create_timeline_dialog
  end

  def activate
    open_timeline_dialog
  end

  def deactivate(_view)
    close_timeline_dialog
  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    edge = @mouse_input.snapped_object
    return if edge.nil?
    # todo change group of edge if actuator
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  def create_timeline_dialog
    @timeline_dialog = UI::HtmlDialog.new(Configuration::TIMELINE_HTML_DIALOG)
    file = File.join(File.dirname(__FILE__), '../ui/html/timeline_panel.html')
    @timeline_dialog.set_file(file)
    @timeline_dialog.add_action_callback('schedule_changed') do |_context, json_string|
      schedule_changed(json_string)
    end

    @timeline_dialog.add_action_callback('run') { run_simulation }
    @timeline_dialog.add_action_callback('pause') { pause_simulation }
    @timeline_dialog.add_action_callback('stop') { stop_simulation }
  end

  def run_simulation
    @simulation = Simulation.new if @simulation.nil?
    if @simulation.paused?
      @simulation.resume
    else
      @simulation.setup
      @simulation.start
      @simulation.add_ground
      Sketchup.active_model.active_view.animation = @simulation
    end
  end

  def pause_simulation
    return if @simulation.nil?
    @simulation.pause
  end

  def stop_simulation
    return if @simulation.nil?
    Sketchup.active_model.active_view.animation = nil
    @simulation = nil
  end

  def open_timeline_dialog
    @timeline_dialog.show
  end

  def close_timeline_dialog
    @timeline_dialog.close
  end

  def schedule_changed(json_string)
    # format:
    # {
    #  'a': [...],
    #  'b': [...],
    #  'c': [...]
    # }
    schedule = JSON.parse(json_string)
    @piston_scheduler.update_schedule(schedule)
  end
end