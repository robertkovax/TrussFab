require 'csv'
require 'src/spring_animation.rb'
require 'src/system_simulation/modellica_export.rb'
require 'src/geometry_animation.rb'
require 'src/trace_animation.rb'
require 'src/system_simulation/simulation_runner.rb'
require 'src/system_simulation/trace_visualization.rb'
require 'src/ui/dialogs/spring_pane.rb'

# Places a user into the geometry i.e. someone who is injecting force into the system. This tool simulates the system
# and opens a panel that shows information and the possibility to change parameters of the springs.
class PlaceUserTool < Tool

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
    end
  end

end
