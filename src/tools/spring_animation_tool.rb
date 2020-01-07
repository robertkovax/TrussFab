require 'csv'
require 'src/spring_animation.rb'
require 'src/system_simulation/modellica_export.rb'
require 'src/geometry_animation.rb'
require 'src/trace_animation.rb'

class SpringAnimationTool < Tool
  HTML_FILE = '../ui/spring-interact/index.html'.freeze

  def initialize(ui)
    super(ui)


    @data = nil

    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
    @edge = nil
    @spring = nil
    @initial_edge_length = nil
    @initial_edge_position = nil
    @animation = nil
    @dialog = nil

    @trace_points = []
  end

  def onLButtonDown(_flags, x, y, view)

    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Edge) # && obj.link_type == 'spring'
      # TODO adjust paths
      if (@data == nil)
        import_time = Benchmark.realtime { @data = ModellicaExport.import_csv("seesaw3_res.csv") }
        puts("parse csv time: " + import_time.to_s + "s")
      end


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
      add_trace(["18", "20"])

      # only draw a point for every 500th data point
      #add_sparse_trace(["18", "20"], 500)
    else
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
    if @trace_points.count > 0
      Sketchup.active_model.active_entities.erase_entities(@trace_points)
    end
    @trace_points = []
  end

  def open_dialog(x,y)
    return if @dialog
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

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), HTML_FILE)
    @dialog.set_file(file)
    puts("" + x.to_s + " " + y.to_s)
    @dialog.set_position(x / 2 - 150,y / 2 + 100)
    @dialog.show
    register_callbacks
  end

  def register_callbacks
    @dialog.add_action_callback('spring_interaction_plus') do |_|
      puts("plus")
      @animation.factor = @animation.factor + 2
    end

    @dialog.add_action_callback('spring_interaction_minus') do |_|
      puts("minus")
      @animation.factor = @animation.factor - 2
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end




end
