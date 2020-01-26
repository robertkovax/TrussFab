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


    @data = nil

    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
    @edge = nil
    @spring = nil
    @initial_edge_length = nil
    @initial_edge_position = nil
    @animation = nil
    @interaction_dialog = nil
    @insights_dialog = nil
    @simulation_runner = nil

    @trace_points = []
    @group = Sketchup.active_model.active_entities.add_group
  end

  def activate
    @simulation_runner = SimulationRunner.new unless @simulation_runner
  end

  def onLButtonDown(_flags, x, y, view)
    open_insights_dialog if @insights_dialog == nil

    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Edge) # && obj.link_type == 'spring'
      @data = @simulation_runner.get_hub_time_series(nil, 0, 0)

      @edge = obj

      @initial_edge_length = @edge.length
      @initial_edge_position = @edge.mid_point
      @first_vector = @initial_edge_position.vector_to(@edge.first_node.position)
      @second_vector = @initial_edge_position.vector_to(@edge.second_node.position)

      @animation = TraceAnimation.new(@data)
      #Sketchup.active_model.active_view.animation = @animation


      #@animation = GeometryAnimation.new(@data)
      #@animation = SpringAnimation.new(@data, @first_vector, @second_vector, @initial_edge_position, @edge)
      #

      # add trace visualizing every data point using a points
      #add_trace(["18", "20"])

      # only draw a point for every 500th data point
      #add_sparse_trace(["18", "20"], 500)

      # visualize data points using transparent circle or sphere
       add_circle_trace(["18", "20"], 1)
      # add_sphere_trace(["18", "20"], 80)
    else
      reset_trace()
      return
      if @animation
        if @animation.running
          @animation.toggle_running()
        else
          @animation = TraceAnimation.new(@data)
          Sketchup.active_model.active_view.animation = @animation
        end

      end
    end


  end

  def add_sphere_trace(node_ids, sparse_factor)
    @data.each_with_index do |current_data_sample, index|
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
    @data.each_with_index do |current_data_sample, index|
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
    @data.each_with_index do |current_data_sample, index|
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

  def open_interaction_dialog(x,y)
    return if @interaction_dialog
    props = {
      # resizable: false,
      preferences_key: 'com.trussfab.spring_interaction',
      width: 200,
      height: 250,
      left: 5,
      top: 5,
      min_width: 200,
      min_height: 150,
      max_width: 100,
      # max_height: @height
      :style => UI::HtmlDialog::STYLE_UTILITY
    }

    @interaction_dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), INTERACT_HTML_FILE)
    @interaction_dialog.set_file(file)
    puts("" + x.to_s + " " + y.to_s)
    @interaction_dialog.set_position(x / 2 - 150,y / 2 + 100)
    @interaction_dialog.show
    register_callbacks
  end

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

  def simulate(c)
    # TODO make initial simulation call use this method
    @simulation_runner.get_hub_time_series(nil, 0, 0, c.to_i)
    import_time = Benchmark.realtime { @data = ModellicaExport.import_csv("seesaw3_res.csv") }
    puts("parse csv time: " + import_time.to_s + "s")

    drawing_time = Benchmark.realtime { add_circle_trace(["18", "20"], 2) }
    puts("drawing time: " + drawing_time.to_s + "s")

  end

  def register_insights_callbacks
    @insights_dialog.add_action_callback('spring_insights_change') do |_, value|
      puts(value)
      reset_trace()
      simulate(value)
      #@animation.factor = @animation.factor + 2
    end
  end

  def register_callbacks
    @interaction_dialog.add_action_callback('spring_interaction_plus') do |_|
      puts("plus")
      @animation.factor = @animation.factor + 2
    end

    @interaction_dialog.add_action_callback('spring_interaction_minus') do |_|
      puts("minus")
      @animation.factor = @animation.factor - 2
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end




end
