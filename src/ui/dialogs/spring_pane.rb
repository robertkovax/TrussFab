require 'benchmark'

require 'src/system_simulation/geometry_animation.rb'
require 'src/system_simulation/spring_picker.rb'
require 'src/system_simulation/simulation_runner_client.rb'
require 'src/utility/json_export.rb'
require 'src/system_simulation/period_animation.rb'
require 'src/ui/widget/widget.rb'

# Ruby integration for spring insights dialog
class SpringPane
  attr_accessor :force_vectors, :trace_visualization, :spring_hinges, :spring_edges
  INSIGHTS_HTML_FILE = '../spring-pane/index.erb'.freeze
  DEFAULT_STATS = { 'period' => Float::NAN,
                    'max_acceleration' => { 'value' => Float::NAN, 'index' => -1 },
                    'max_velocity' => { 'value' => Float::NAN, 'index' => -1 } }.freeze

  def initialize
    @refresh_callback = nil
    @toggle_animation_callback = nil

    @color_permutation_index = 0

    update_springs

    # Instance of the simulation runner used as an interface to the system simulation.
    @simulation_runner = nil
    # Array of AnimationDataSamples, each containing geometry information for hubs for a certain point in time.
    # { age => array<AnimationDataSamples> }
    @simulation_data = nil
    # Sketchup animation object which animates the graph according to simulation data frames.
    @animation = nil
    # A simple visualization for simulation data, plotting circles into the scene.
    @trace_visualization = nil
    @animation_running = false
    @period_animation_running = false

    @simulation_duration = 5.0

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

    @spring_hinges = {}

    @energy = 1000 # in Joule

    @initial_hub_positions = {}

    # load attachable users such that they dont start loading during the user interaction
    ModelStorage.instance.attachable_users

    @visualization_offset = Geom::Vector3d.new(0, 0, 30)

    @widget = nil
  end

  # spring / graph manipulation logic:

  def update_constant_for_spring(spring_id, new_constant)
    edge = @spring_edges.find { |edge| edge.id == spring_id }
    parameters = get_spring(edge, new_constant)
    p parameters
    edge.link.spring_parameters = parameters
    edge.link.actual_spring_length = parameters[:unstreched_length].m
    simulate
  end

  def enable_preloading_for_spring(spring_id)
    edge = @spring_edges.find { |edge| edge.id == spring_id }
    edge.link.spring_parameters[:enable_preloading] = true

    update_dialog if @dialog
  end

  def disable_preloading_for_spring(spring_id)
    edge = @spring_edges.find { |edge| edge.id == spring_id }
    edge.link.spring_parameters[:enable_preloading] = false

    update_dialog if @dialog
  end

  def set_preloading_for_spring(spring_id, value)
    edge = @spring_edges.find { |edge| edge.id == spring_id }
    edge.link.spring_parameters[:enable_preloading] = value
    p "set preloading to #{value} for #{edge.id}"
    update_dialog if @dialog
  end

  def set_simulation_duration(new_duration)
    @simulation_duration = new_duration.to_f
    simulate
  end

  def force_vectors=(vectors)
    @force_vectors = vectors
    update_trace_visualization
    play_animation
  end

  def get_spring(edge, new_constant)
    mount_offset = Configuration::SPRING_MOUNT_OFFSET
    @spring_picker.get_spring(new_constant, edge.length.to_m - mount_offset)
  end

  def update_springs
    @spring_edges = Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }
  end

  def update_trace_visualization
    Sketchup.active_model.start_operation("visualize trace", true)

    @trace_visualization ||= TraceVisualization.new visualization_offset: @visualization_offset
    @trace_visualization.reset_trace
    # TODO pass in multiple age groups for simulation data and user stats
    # visualize every node with a mounted user
    @trace_visualization.add_bars(mounted_users.keys.map(&:to_s), 4, @simulation_data, @user_stats)
    # @trace_visualization.add_trace(mounted_users.keys.map(&:to_s), 4, @simulation_data.values[0], @user_stats.values[0])

    # Visualized period
    #  TODO: make this work for multiple users and move into seperate method
    node_id = mounted_users.keys.first
    if @user_stats.nil? || @user_stats.values[0][node_id].nil?
      puts "No user stats for node #{node_id}"
      # return
    end
    Sketchup.active_model.commit_operation
    # TODO check if this still works with multiple age groups
    # @animation = PeriodAnimation.new(@simulation_data, @user_stats.values[0][node_id.to_s]['period'], node_id) do
    #   @period_animation_running = false
    #   update_dialog
    #   puts "stop"
    # end
    # Sketchup.active_model.active_view.animation = @animation
    # @period_animation_running = true
    #
    add_widget(node_id)
  end

  def add_widget(node_id)
    movement_curve = @trace_visualization.handles[node_id][0].movement_curve
    puts movement_curve
    midpoint = Geometry.midpoint(movement_curve[0], movement_curve[-1])
    @widget = Widget.new(midpoint + Geom::Vector3d.new(0, 0, 50.mm), ["easy", "medium", "hard"])
  end

  def update_bode_diagram
    @bode_plot = SimulationRunnerClient.bode_plot
  end

  def put_geometry_into_equilibrium(spring_id)
    equilibrium_index = @simulation_runner.find_equilibrium(spring_id)
    set_graph_to_data_sample(equilibrium_index)
  end

  def set_graph_to_data_sample(index)
    # TODO how to choose the age here? / check if this is still needed
    current_data_sample = @simulation_data.values[0][index]

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
    return unless Configuration::COLOR_STATIC_GROUPS

    Sketchup.active_model.start_operation('Color static groups', true)
    @static_groups = StaticGroupAnalysis.find_static_groups
    visualizer = NodeExportVisualization::Visualizer.new
    visualizer.color_static_groups @static_groups
    Sketchup.active_model.commit_operation

    # TODO: maybe call at another point
    #calculate_hinge_edges
  end

  def cycle_static_group_colors(to_add=1)
    @color_permutation_index += to_add
    Sketchup.active_model.start_operation('Color static groups', true)
    visualizer = NodeExportVisualization::Visualizer.new
    permutations = @static_groups.permutation.to_a
    @color_permutation_index = 0 if @color_permutation_index >= permutations.length
    visualizer.color_static_groups permutations[@color_permutation_index]
    puts @color_permutation_index
    puts permutations.length
    Sketchup.active_model.commit_operation
  end

  def notify_model_changed
    p "Model was changed."
    # Reset what ever needs to be reset as soon as the model changed.
    if @animation && @animation.running
      @animation.stop
      @animation_running = false
    end

    simulate
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

  def mounted_users_excitement
    excitement = {}
    Graph.instance.nodes.each do |node_id, node|
      hub = node.hub
      next unless hub.is_user_attached

      excitement[node_id] = hub.user_excitement
    end
    excitement
  end

  def update_mounted_users
    simulate
  end

  def update_mounted_users_excitement
    # TODO implement user actuation here
  end

  def get_extensions_from_equilibrium_positions
    extensions = SimulationRunnerClient.get_spring_extensions

    Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }.each do |edge|
      edge.link.spring_parameters[:unstreched_length] = extensions[edge.id.to_s]
      # edge.link.upadate_spring_visualization
    end
    update_dialog if @dialog
  end

  def request_compilation
    simulate
  end

  def set_visualization_offset(x, y, z)
    @visualization_offset = Geom::Vector3d.new(x, y, z)
    @trace_visualization.reset_trace if @trace_visualization
    @trace_visualization = nil
    puts "New visualization offset: #{@visualization_offset}"
    update_trace_visualization
  end

  private

  def constants_for_springs
    spring_constants = {}
    @spring_edges.map(&:link).each do |link|
      spring_constants[link.edge.id] = link.spring_parameters[:k]
    end
    spring_constants
  end

  # "4"=>Point3d(201.359, -30.9042, 22.6955), "5"=>Point3d(201.359, -56.2592, 15.524)}
  def preload_geometry_to(position_data)
    Sketchup.active_model.start_operation('Set geometry to preloading positions', true)
    position_data.each do |node_id, position|
      node = Graph.instance.nodes[node_id.to_i]
      next unless node

      update_node_position(node, position)
    end

    position_data.each do |node_id, _|
      node = Graph.instance.nodes[node_id.to_i]
      next unless node

      node.update_sketchup_object
    end

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
    Sketchup.active_model.commit_operation
  end

  def update_node_position(node, position)
    node.update_position(position)
    #node.hub.update_position(position)
    #node.hub.update_user_indicator
    node.adjacent_triangles.each { |triangle| triangle.update_sketchup_object if triangle.cover }
  end


  # Parses data retrieved from a csv, must contain header at the first index.
  def self.parse_timeseries_data(data_array)
    # parse in which columns the coordinates for each node are stored
    indices_map = AnimationDataSample.indices_map_from_header(data_array[0])

    # remove header of loaded data
    data_array.shift

    # parse csv
    data_samples = []
    data_array.each do |value|
      data_samples << AnimationDataSample.from_raw_data(value, indices_map)
    end
    data_samples
  end

  # compilation / simulation logic
  def simulate
    Sketchup.active_model.start_operation('compile simulation', true)
    SimulationRunnerClient.update_model(JsonExport.graph_to_json(nil, [], @simulation_duration)) do |json_response|
      simulation_results = json_response["simulation_results"]
      @simulation_data = Hash.new
      @user_stats = Hash.new
      simulation_results.keys.each do |age|
        result = simulation_results[age.to_s]

        timeseries_data = self.class.parse_timeseries_data(result["data"])
        user_stats = result["user_stats"]

        @simulation_data[age.to_s] = timeseries_data
        @user_stats[age.to_s] = user_stats
      end

      update_trace_visualization
      update_dialog if @dialog
    end
    Sketchup.active_model.commit_operation
  end

  # animation logic:

  def play_animation
    # recreate animation
    create_animation
  end

  def toggle_animation
    start_animation = !@animation_running

    if start_animation
      simulate unless @simulation_data
      @animation.stop if @period_animation_running
      create_animation
      @animation_running = true
    elsif @animation
      @animation.stop
      @animation_running = false
    end

    update_dialog
  end

  def optimize
    SimulationRunnerClient.optimize_spring_for_constrain.each do |spring_id, constant|
      update_constant_for_spring(spring_id.to_i, constant)
    end
  end

  def create_animation
    # TODO: adjust: we need the age id (retrieved by click on bar)
    @animation = GeometryAnimation.new(@simulation_data.values[0]) do
      @animation_running = false
      update_dialog
    end
    Sketchup.active_model.active_view.animation = @animation
  end

  def preload_springs
    Graph.instance.nodes.each do |node_id, node|
      @initial_hub_positions[node_id] = node.position
    end
    # "4"=>Point3d(201.359, -30.9042, 22.6955), "5"=>Point3d(201.359, -56.2592, 15.524)}
    preloading_enabled_spring_ids = @spring_edges.map(&:link).select { |link| link.spring_parameters[:enable_preloading]}.map(&:id)
    @trace_visualization.reset_trace

    position_data = SimulationRunnerClient.get_preload_positions(@energy, preloading_enabled_spring_ids).position_data
    preload_geometry_to position_data
  end

  def register_callbacks
    @dialog.add_action_callback('spring_constants_change') do |_, spring_id, value|
      update_constant_for_spring(spring_id, value.to_i)
    end

    @dialog.add_action_callback('spring_set_preloading') do |_, spring_id, value|
      set_preloading_for_spring(spring_id, value)
      update_dialog
    end


    @dialog.add_action_callback('spring_insights_energy_change') do |_, value|
      @energy = value.to_i
    end

    @dialog.add_action_callback('spring_insights_preload') do
      preload_springs
    end

    @dialog.add_action_callback('spring_insights_compile') do
      simulate
    end

    @dialog.add_action_callback('spring_insights_simulate') do
      simulate
    end

    @dialog.add_action_callback('spring_insights_toggle_play') do
      toggle_animation
    end

    @dialog.add_action_callback('spring_insights_optimize') do
      optimize
    end

    @dialog.add_action_callback('spring_insights_reset_hubs') do
      preload_geometry_to(@initial_hub_positions)
    end

    @dialog.add_action_callback('user_weight_change') do |_, node_id, value|
      weight = value.to_i
      Graph.instance.nodes[node_id].hub.user_weight = weight
      simulate
      puts "Update user weight: #{weight}"
      # TODO: probably this is a duplicate call, cleanup this updating the dialog logic
    end

    @dialog.add_action_callback('user_excitement_change') do |_, node_id, value|
      excitement = value.to_i
      Graph.instance.nodes[node_id].hub.user_excitement = excitement
      simulate
      puts "Update user excitement: #{excitement}"
    end
  end

end
