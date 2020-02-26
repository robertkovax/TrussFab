require_relative 'spring_simulation_tool.rb'
require 'csv'
require 'src/spring_animation.rb'
require 'src/system_simulation/modellica_export.rb'
require 'src/geometry_animation.rb'
require 'src/trace_animation.rb'
require 'src/system_simulation/simulation_runner.rb'
require 'src/system_simulation/trace_visualization.rb'
require 'src/ui/dialogs/spring_pane.rb'

# Places a user into the geometry i.e. someone who is injecting force into the system. This tool simulates the system
# and opens a panel that shows information and the possiblity to change parameters of the springs.
class PlaceUserTool < SpringSimulationTool

  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)

    # Animation that makes the geometry move according to the specified simulation data.
    @animation = nil

    @insights_pane = nil

    # Visualize oscillation as a trace, will be instantiated with simulation data.
    @trace_visualization = nil

  end

  def onLButtonDown(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Node) # && obj.link_type == 'spring'
      obj.hub.toggle_attached_user

      # Populate simulation data.
      simulate

      # Set geometry into equilibrium.
      set_graph_to_data_sample(0)

      # Visualize for current spring constant.
      @trace_visualization = TraceVisualization.new
      @trace_visualization.add_trace(['18', '20'], 4, @simulation_data)

      # Open spring insights dialog.
      if @insights_pane == nil
        @insights_pane = SpringPane.new(Proc.new{|spring_id, value| spring_constant_changed(spring_id, value)},
                                        Proc.new{toggle_animation})
      end

    else
      @trace_visualization.reset_trace
      toggle_animation
    end


  end

  def spring_constant_changed(spring_id, value)
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

end
