require 'json'
require 'src/tools/tool'
require 'src/simulation/simulation'
require 'src/utility/scheduler'

class TimelineTool < Tool
  def initialize(ui)
    super
    @timeline_dialog = nil
    @simulation = nil
    @scheduler = Scheduler.instance
    @mouse_input = MouseInput.new(snap_to_edges: true)
    # create_timeline_dialog
    slider_dialog
    @dialog.show
    @active = false
  end

  def activate
    @active = true
    run_simulation
    @simulation.static_schedule_state = 0
  end

  def deactivate(_view)
    @active = false
    stop_simulation
    # close_timeline_dialog
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

  # def create_timeline_dialog
  #   @timeline_dialog = UI::HtmlDialog.new(Configuration::TIMELINE_HTML_DIALOG)
  #   file = File.join(File.dirname(__FILE__), '../ui/html/timeline_panel.html')
  #   @timeline_dialog.set_file(file)
  #   @timeline_dialog.add_action_callback('schedule_changed') do |_context, json_string|
  #     schedule_changed(json_string)
  #   end

  #   @timeline_dialog.add_action_callback('run') { run_simulation }
  #   @timeline_dialog.add_action_callback('pause') { pause_simulation }
  #   @timeline_dialog.add_action_callback('stop') { stop_simulation }
  # end

  def slider_dialog
    return if @scheduler.groups.empty?
    @dialog = UI::HtmlDialog.new(Configuration::TIMELINE_HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__), '../ui/html/piston_slider.erb'))
    template = ERB.new(file_content)
    @dialog.set_html(template.result(binding))
    @dialog.add_action_callback('change_piston') do |_context, group_id, idx, value|
      Sketchup.active_model.select_tool(self) unless @active
      value = value.to_f
      group_id = group_id.to_i
      idx = idx.to_i
      @simulation.static_schedule_state = idx
      @scheduler.alter(group_id, idx, value)
    end
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
    @simulation.static_schedule_state = nil
  end

  def stop_simulation
    return if @simulation.nil?
    Sketchup.active_model.active_view.animation = nil
    @simulation = nil
  end
end