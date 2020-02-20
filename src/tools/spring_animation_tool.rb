require 'csv'
require 'src/spring_animation.rb'
require 'src/system_simulation/modellica_export.rb'
require 'src/geometry_animation.rb'
require 'src/trace_animation.rb'
require 'src/system_simulation/simulation_runner.rb'

class SpringAnimationTool < Tool
  INTERACT_HTML_FILE = '../ui/spring-interact/index.html'.freeze
  INSIGHTS_HTML_FILE = '../ui/spring-insights/index.html'.freeze

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)

    # Array of AnimationDataSamples, each containing geometry information for hubs for a certain point in time.
    @simulation_data = nil

    # Animation that makes the geometry move according to the specified simulation data.
    @animation = nil

    # Instance of the simulation runner used as an interface to the system simulation.
    @simulation_runner = nil

    # TODO factor out
    @insights_dialog = nil

    # TODO replace by map edgeID => springConstant to support multiple springs
    # Spring constant
    @constant = 20000

    # Visualizing animation samples by plotting a circle.
    @trace_points = []

    # Group containing trace circles.
    @group = Sketchup.active_model.active_entities.add_group
  end

  def activate
    # Instantiates SimulationRunner and compiles model.
    @simulation_runner = SimulationRunner.new unless @simulation_runner
  end

  def onLButtonDown(_flags, x, y, view)
    # Open spring insights dialog.
    open_insights_dialog if @insights_dialog == nil

    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Node) # && obj.link_type == 'spring'
      obj.hub.toggle_attached_user

      # Populate simulation data.
      simulate
      #@insights_dialog.execute_script("set_period(#{get_period})")

      # Set geometry into equilibrium.
      set_graph_to_data_sample(0)

      # Visualize for current spring constant.
      add_circle_trace(["18", "20"], 4)

    else
      # Reset trace visualization.
      reset_trace

      # Stop Animation.
      toggle_animation
    end


  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  private

  def toggle_animation
    if @animation
      if @animation.running
        @animation.toggle_running()
      else
        create_animation
      end
    end

  end

  def create_animation
    @animation = GeometryAnimation.new(@simulation_data)
    Sketchup.active_model.active_view.animation = @animation
  end

  def get_period(constant=2000)
    period = @simulation_runner.get_period(constant)
    update_period(period)
  end

  def update_period(value)
    @insights_dialog.execute_script("set_period(#{value})")
  end


  def simulate
    @simulation_data = @simulation_runner.get_hub_time_series(nil, 0, 0, @constant.to_i)
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

  #
  # Trace logic
  #
  #
  def add_sphere_trace(node_ids, sparse_factor)
    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      next unless index % sparse_factor == 0

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      entities = @group.entities

      color = Sketchup::Color.new(72,209,204)
      materialToSet = Sketchup.active_model.materials.add("MyColor_1")
      materialToSet.color = color
      materialToSet.alpha = 0.2

      radius = 1
      num_segments = 20
      circle = entities.add_circle(current_data_sample.position_data[node_ids[0]], Geom::Vector3d.new(1,0,0), radius, num_segments)
      face = entities.add_face(circle)
      face.material = materialToSet unless face.deleted?
      face.back_material = materialToSet unless face.deleted?
      face.reverse!
      # Create a temporary path for follow me to use to perform the revolve.
      # This path should not touch the face.
      path = entities.add_circle(current_data_sample.position_data[node_ids[0]], Geom::Vector3d.new(0,0,1), radius * 2, num_segments)
      # This creates the sphere.
      face.followme(path)

      entities.erase_entities(path)


      circle = entities.add_circle(current_data_sample.position_data[node_ids[1]], Geom::Vector3d.new(1,0,0), radius, num_segments)
      face = entities.add_face(circle)
      face.material = materialToSet unless face.deleted?
      face.back_material = materialToSet unless face.deleted?
      face.reverse!
      # Create a temporary path for follow me to use to perform the revolve.
      # This path should not touch the face.
      path = entities.add_circle(current_data_sample.position_data[node_ids[1]], Geom::Vector3d.new(0,0,1), radius * 2, num_segments)
      # This creates the sphere.
      face.followme(path)

      entities.erase_entities(path)

      #    entities.grep(Sketchup::Edge).each{|e| e.hidden=true }
    end
  end

  def add_circle_trace(node_ids, sparse_factor)
    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      next unless index % sparse_factor == 0

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      entities = @group.entities

      color = Sketchup::Color.new(72,209,204)
      materialToSet = Sketchup.active_model.materials.add("MyColor_1")
      materialToSet.color = color
      materialToSet.alpha = 0.4

      edgearray = entities.add_circle(current_data_sample.position_data[node_ids[0]], Geom::Vector3d.new(1,0,0), 1, 10)
      edgearray.each{|e| e.hidden=true }
      first_edge = edgearray[0]
      arccurve = first_edge.curve
      face = entities.add_face(arccurve)
      face.material = materialToSet unless face == nil

      edgearray = entities.add_circle(current_data_sample.position_data[node_ids[1]], Geom::Vector3d.new(1,0,0), 1, 10)
      edgearray.each{|e| e.hidden=true }
      first_edge = edgearray[1]
      arccurve = first_edge.curve
      face = entities.add_face(arccurve)
      face.material = materialToSet unless face == nil

      #    entities.grep(Sketchup::Edge).each{|e| e.hidden=true }
    end
  end

  def add_sparse_trace(node_ids, sparse_factor)
    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      next unless index % sparse_factor == 0

      model = Sketchup.active_model
      entities = model.active_entities
      @trace_points << entities.add_cpoint(current_data_sample.position_data[node_ids[0]])
      @trace_points << entities.add_cpoint(current_data_sample.position_data[node_ids[1]])
      #puts(current_data_sample.time_stamp)
    end
  end

  def add_trace(node_ids)
    add_sparse_trace(node_ids, 100)
  end

  def reset_trace()
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a)
    if @trace_points.count > 0
      Sketchup.active_model.active_entities.erase_entities(@trace_points)
    end
    @trace_points = []
  end

  #
  # Dialog logic
  #
  #
  def open_insights_dialog
    return if @insights_dialog
    props = {
        # resizable: false,
        preferences_key: 'com.trussfab.spring_insights',
        width: 200,
        height: 250,
        left: 5,
        top: 5,
        min_width: 400,
        min_height: 120,
        # max_height: @height
        :style => UI::HtmlDialog::STYLE_UTILITY
    }

    @insights_dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), INSIGHTS_HTML_FILE)
    @insights_dialog.set_file(file)
    @insights_dialog.set_position(500, 500)
    @insights_dialog.show
    register_insights_callbacks
  end

  def register_insights_callbacks
    @insights_dialog.add_action_callback('spring_insights_change') do |_, value|
      puts(value)
      reset_trace()
      @constant = value
      simulate
      drawing_time = Benchmark.realtime { add_circle_trace(["18", "20"], 4) }
      puts("drawing time: " + drawing_time.to_s + "s")
      #get_period(value)
      #@animation.factor = @animation.factor + 2
    end

    @insights_dialog.add_action_callback('spring_insights_toggle_play') do |_, value|
      if @animation
        toggle_animation
      else
        create_animation
      end
    end
  end

end
