# Ruby integration for spring insights dialog
class SpringPane
  INSIGHTS_HTML_FILE = '../spring-pane/index.erb'.freeze

  def initialize
    @refresh_callback = nil
    @toggle_animation_callback = nil

    update_springs

    @animation = nil
    @simulation_runner = nil

    @dialog = nil
    open_dialog

  end

  def update_constant_for_spring(spring_id, new_constant)
    edge = @spring_edges.find { |edge| edge.id == spring_id }
    edge.link.spring_parameter_k = new_constant
    update_springs
  end

  def update_springs
    @spring_edges = Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }
    update_dialog if @dialog
  end

  def set_period(value)
    @dialog.execute_script("set_period(#{value})")
  end

  def set_constant(value, spring_id = 25)
    @dialog.execute_script("set_constant(#{spring_id},#{value})")
  end

  # TODO: should probably always be called when a link is changed... e.g also in actuator tool
  def update_dialog
    # load updated html
    file_path = File.join(File.dirname(__FILE__), INSIGHTS_HTML_FILE)
    content = File.read(file_path)
    t = ERB.new(content)

    # display updated html
    @dialog.set_html(t.result(binding))
  end

  def open_dialog
    return if @dialog && @dialog.visible?

    props = {
        resizable: true,
        preferences_key: 'com.trussfab.spring_insights',
        width: 200,
        height: 50 + @spring_edges.length * 200,
        left: 5,
        top: 5,
        # max_height: @height
        style: UI::HtmlDialog::STYLE_DIALOG
    }

    @dialog = UI::HtmlDialog.new(props)
    file_path = File.join(File.dirname(__FILE__), INSIGHTS_HTML_FILE)
    content = File.read(file_path)
    t = ERB.new(content)
    @dialog.set_html(t.result(binding))
    @dialog.set_position(500, 500)
    @dialog.show
    register_callbacks
  end

  private

  def register_callbacks
    @dialog.add_action_callback('spring_constants_change') do |_, spring_id, value|
      update_constant_for_spring(spring_id, value.to_i)
    end

    @dialog.add_action_callback('spring_insights_compile') do
      try_compile
    end

    @dialog.add_action_callback('spring_insights_toggle_play') do
      toggle_animation
    end
  end

  def try_compile
    @simulation_runner ||= SimulationRunner.instance
    @simulation_data ||= simulate
  end

  def simulate
    @simulation_data = @simulation_runner.get_hub_time_series
  end


  def toggle_animation
    simulate
    if @animation && @animation.running
      @animation.toggle_running
    else
      create_animation
    end

  end

  def create_animation
    @animation = GeometryAnimation.new(@simulation_data)
    Sketchup.active_model.active_view.animation = @animation
  end

end
