require 'benchmark'

require 'src/system_simulation/geometry_animation.rb'
require 'src/system_simulation/spring_picker.rb'
require 'src/system_simulation/simulation_runner_client.rb'
require 'src/utility/json_export.rb'
require 'src/system_simulation/period_animation.rb'

# Ruby integration for spring insights dialog
class SpringPane
  attr_accessor :force_vectors, :trace_visualization
  INSIGHTS_HTML_FILE = '../spring-pane/index.erb'.freeze
  DEFAULT_STATS = { 'period' => Float::NAN,
                    'max_acceleration' => { 'value' => Float::NAN, 'index' => -1 },
                    'max_velocity' => { 'value' => Float::NAN, 'index' => -1 } }.freeze

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
    @animation_running = false

    # { node_id => {
    #               period: {value: float, index: int}, max_a: {value: float, index: int},
    #               max_v: {value: float, index: int}, time_velocity: [{time: float, velocity: float}],
    #               time_acceleration: [{time: float, acceleration: float}]
    #              }
    # }
    @user_stats = {}

    @bode_plot = { "magnitude" =>  [],  "frequencies" => [], "phase" => [] }

    @spring_picker = SpringPicker.instance

    @force_vectors = []

    @dialog = nil
    open_dialog

    @pending_compilation = false
  end

  # spring / graph manipulation logic:

  def update_constant_for_spring(spring_id, new_constant)
    edge = @spring_edges.find { |edge| edge.id == spring_id }
    parameters = get_spring(edge, new_constant)
    p parameters
    edge.link.spring_parameters = parameters
    edge.link.actual_spring_length = parameters[:unstreched_length].m
    # notify simulation runner about changed constants
    SimulationRunnerClient.update_spring_constants(constants_for_springs)

    update_stats
    # TODO: fix and reenable
    # put_geometry_into_equilibrium(spring_id)
    update_trace_visualization true

    update_bode_diagram

    update_dialog if @dialog
  end

  def force_vectors=(vectors)
    @force_vectors = vectors
    update_trace_visualization true
    play_animation
  end

  def get_spring(edge, new_constant)
    # TODO: calculate mount_offset
    mount_offset = 0.1
    @spring_picker.get_spring(new_constant, edge.length.to_m - mount_offset)
  end

  def update_springs
    @spring_edges = Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }
    update_dialog if @dialog
  end

  def update_mounted_users
    SimulationRunnerClient.update_mounted_users(mounted_users)
    update_stats
    update_dialog if @dialog
  end

  def update_stats
    mounted_users.keys.each do |node_id|
      stats = SimulationRunnerClient.get_user_stats(node_id)
      stats = DEFAULT_STATS if stats == {}
      @user_stats[node_id] = stats
    end
  end

  def update_trace_visualization(force_simulation = true)
    # update simulation data and visualizations with adjusted results
    simulate if force_simulation

    @trace_visualization ||= TraceVisualization.new
    @trace_visualization.reset_trace
    # visualize every node with a mounted user
    @trace_visualization.add_trace(mounted_users.keys.map(&:to_s), 4, @simulation_data, @user_stats)

    # Visualized period
    #  TODO: make this work for multiple users and move into seperate method
    node_id = mounted_users.keys.first
    @animation = PeriodAnimation.new(@simulation_data, @user_stats[node_id]['period'], node_id) do
      @animation_running = false
      update_dialog
      puts "stop"
    end
    Sketchup.active_model.active_view.animation = @animation
  end

  def update_bode_diagram
    @bode_plot = SimulationRunnerClient.bode_plot
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
    focus_main_window
  end

  # Opens a dummy dialog, to focus the main Sketchup Window again
  def focus_main_window
    dialog = UI::WebDialog.new('', true, '', 0, 0, 10_000, 10_000, true)
    dialog.show
    dialog.close
  end

  def open_dialog
    return if @dialog && @dialog.visible?

    props = {
      resizable: true,
      preferences_key: 'com.trussfab.spring_insights',
      width: 300,
      height: 50 + @spring_edges.length * 200,
      left: 500,
      top: 500,
      style: UI::HtmlDialog::STYLE_DIALOG
    }

    @dialog = UI::HtmlDialog.new(props)
    file_path = File.join(File.dirname(__FILE__), INSIGHTS_HTML_FILE)
    content = File.read(file_path)
    t = ERB.new(content)
    @dialog.set_html(t.result(binding))
    @dialog.show
    register_callbacks
  end

  # compilation / simulation logic:
  def color_static_groups
    Sketchup.active_model.start_operation('Color static groups', true)
    static_groups = StaticGroupAnalysis.find_static_groups
    visualizer = NodeExportVisualization::Visualizer.new
    visualizer.color_static_groups static_groups
    Sketchup.active_model.commit_operation
  end

  def notify_model_changed
    # Reset what ever needs to be reset as soon as the model changed.
    if @animation && @animation.running
      @animation.stop
      @animation_running = false
    end
    request_compilation
    update_trace_visualization false
  end

  def request_compilation
    @pending_compilation = true
    update_dialog if @dialog
  end

  def compile
    Sketchup.active_model.start_operation('compile simulation', true)
    compile_time = Benchmark.realtime do
      SimulationRunnerClient.update_model(
        JsonExport.graph_to_json(nil, [], constants_for_springs, mounted_users)
      )
    end
    Sketchup.active_model.commit_operation
    puts "Compiled the modelica model in #{compile_time.round(2)} seconds."
    color_static_groups
    @pending_compilation = false
    update_dialog if @dialog
  end

  private

  def constants_for_springs
    spring_constants = {}
    @spring_edges.map(&:link).each do |link|
      spring_constants[link.edge.id] = link.spring_parameters[:k]
    end
    spring_constants
  end

  def mounted_users
    mounted_users = {}
    Graph.instance.nodes.each do |node_id, node|
      hub = node.hub
      next unless hub.is_user_attached

      mounted_users[node_id] = hub.user_weight
    end
    mounted_users
  end

  # compilation / simulation logic:

  def simulate
    simulation_time = Benchmark.realtime do
      @simulation_data = SimulationRunnerClient.get_hub_time_series(@force_vectors)
    end
    puts "Simulated the compiled model in #{simulation_time.round(2)} seconds."
  end

  # animation logic:

  def play_animation
    # recreate animation
    create_animation
  end

  def toggle_animation
    simulate
    if @animation && @animation.running
      @animation.stop
      @animation_running = false
    else
      create_animation
      @animation_running = true
    end
    update_dialog
  end

  def optimize
    SimulationRunnerClient.optimize_spring_for_constrain.each do |spring_id, constant|
      update_constant_for_spring(spring_id.to_i, constant)
    end
  end

  def create_animation
    @animation = GeometryAnimation.new(@simulation_data) do
      @animation_running = false
      update_dialog
    end
    Sketchup.active_model.active_view.animation = @animation
  end

  def register_callbacks
    @dialog.add_action_callback('spring_constants_change') do |_, spring_id, value|
      update_constant_for_spring(spring_id, value.to_i)
    end

    @dialog.add_action_callback('spring_insights_compile') do
      compile
      # Also update trace visualization to provide visual feedback to user
      update_stats
      update_bode_diagram
      update_dialog if @dialog
      update_trace_visualization true
    end

    @dialog.add_action_callback('spring_insights_toggle_play') do
      toggle_animation
    end

    @dialog.add_action_callback('spring_insights_optimize') do
      optimize
    end

    @dialog.add_action_callback('user_weight_change') do |_, node_id, value|
      weight = value.to_i
      Graph.instance.nodes[node_id].hub.user_weight = weight
      update_mounted_users
      update_bode_diagram
      update_trace_visualization true
      puts "Update user weight: #{weight}"

      # TODO: probably this is a duplicate call, cleanup this updating the dialog logic
      update_dialog if @dialog
    end
  end

end
