require 'src/system_simulation/simulation_runner.rb'
require 'src/system_simulation/geometry_animation.rb'

# Ruby integration for spring insights dialog
class SpringPane
  INSIGHTS_HTML_FILE = '../spring-pane/index.erb'.freeze

  def initialize
    @refresh_callback = nil
    @toggle_animation_callback = nil

    update_springs

    # Instance of the simulation runner used as an interface to the system simulation.
    @simulation_runner = nil
    # Array of AnimationDataSamples, each containing geometry information for hubs for a certain point in time.
    @simulation_data = nil
    # Sketchup animation object which animates the graph according to simulation data frames.
    @animation = nil
    # A simple visualization for simulation data, plotting circles into the scene.
    @trace_visualization = nil

    @dialog = nil
    open_dialog

  end

  # spring / graph manipulation logic:

  def update_constant_for_spring(spring_id, new_constant)
    edge = @spring_edges.find { |edge| edge.id == spring_id }
    edge.link.spring_parameter_k = new_constant

    # update simulation data and visualizations with adjusted results
    simulate
    put_geometry_into_equilibrium(spring_id)
    update_trace_visualization

    update_dialog if @dialog
  end

  def update_springs
    @spring_edges = Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }
    update_dialog if @dialog
  end

  def update_trace_visualization
    @trace_visualization ||= TraceVisualization.new
    @trace_visualization.reset_trace
    @trace_visualization.add_trace(['18', '20'], 4, @simulation_data)
  end

  def put_geometry_into_equilibrium(spring_id)
    equilibrium_index = @simulation_runner.find_equilibrium(spring_id)
    set_graph_to_data_sample(equilibrium_index)
  end

  def set_graph_to_data_sample(index)
    current_data_sample = @simulation_data[index]

    Graph.instance.nodes.each do | node_id, node|
      node.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_user_indicator()
    end

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
  end

  # dialog logic:

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

  # compilation / simulation logic:

  def try_compile
    @simulation_runner ||= SimulationRunner.instance
    @simulation_data ||= simulate
    @simulation_runner
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

  # compilation / simulation logic:

  def simulate
    @simulation_data = @simulation_runner.get_hub_time_series
  end

  # animation logic:

  def toggle_animation
    puts "toggle_animation"
    simulate
    if @animation && @animation.running
      @animation.toggle_running
    else
      create_animation
    end

  end

  def create_animation
    puts "create_animation"
    @animation = GeometryAnimation.new(@simulation_data)
    Sketchup.active_model.active_view.animation = @animation
  end

end
