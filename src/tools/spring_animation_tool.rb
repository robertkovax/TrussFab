require 'csv'
require 'src/spring_animation.rb'
require 'src/system_simulation/modellica_export.rb'
require 'src/geometry_animation.rb'
require 'src/trace_animation.rb'
require 'src/system_simulation/simulation_runner.rb'
require 'src/system_simulation/trace_visualization.rb'
require 'src/ui/dialogs/spring_pane.rb'

# TODO rename to place user tool, delete old one and add documentation here.
class SpringAnimationTool < Tool

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)

    # Array of AnimationDataSamples, each containing geometry information for hubs for a certain point in time.
    @simulation_data = nil

    # Animation that makes the geometry move according to the specified simulation data.
    @animation = nil

    # Instance of the simulation runner used as an interface to the system simulation.
    @simulation_runner = nil

    @insights_pane = nil

    # TODO replace by map edgeID => springConstant to support multiple springs
    # Spring constant
    @constant = 20000

    # Visualize oscillation as a trace, will be instantiated with simulation data.
    @trace_visualization = nil

    # All spring links in the scene right now
    @spring_links = []

  end

  def activate
    # Instantiates SimulationRunner and compiles model.
    @simulation_runner = SimulationRunner.new unless @simulation_runner
    @spring_links = Graph.instance.edges.values.
        select { |edge| edge.link_type == 'spring' }.
        map(&:link)
  end

  def onLButtonDown(_flags, x, y, view)
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
      @trace_visualization = TraceVisualization.new
      @trace_visualization.add_trace(['18', '20'], 4, @simulation_data)

      # Open spring insights dialog.
      if @insights_pane == nil
        @insights_pane = SpringPane.new(@trace_visualization, @constant, @animation,
                                        Proc.new{|spring_id, value| spring_constant_changed(spring_id, value)},
                                        Proc.new{toggle_animation})
      end

    else
      # Reset trace visualization.
      @trace_visualization.reset_trace

      # Stop Animation.
      toggle_animation
    end


  end

  def spring_constant_changed(spring_id, value)
    puts(value)
    @spring_links.select{ |spring| spring.id == spring_id }[0].spring_parameter_k = value.to_f
    @trace_visualization.reset_trace
    @constant = value
    simulate
    drawing_time = Benchmark.realtime { @trace_visualization.add_trace(["18", "20"], 4, @simulation_data) }
    puts("drawing time: " + drawing_time.to_s + "s")
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end

  private

  def toggle_animation
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

  def get_period(constant=2000)
    period = @simulation_runner.get_period(constant)
    update_period(period)
  end

  def update_period(value)
    @insights_pane.set_period(value)

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


end
