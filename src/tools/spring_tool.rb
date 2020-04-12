require 'src/tools/link_tool.rb'
require 'src/export/node_export_visualization'

# creates a gas spring-type link
class SpringTool < ActuatorTool
  def initialize(ui)
    super(ui, 'spring')
  end

  PISTON_SPEED = 10

  def activate
    @scheduled_pistons = []
    @simulation = Simulation.new
    @simulation.disable_coloring
    @simulation.setup
    @simulation.disable_gravity


    Sketchup.active_model.active_view.animation = @simulation
    @simulation.start
    Sketchup.active_model.commit_operation
  end

  def deactivate(view)
    super
    reset
  end

  def reset
    Sketchup.active_model.start_operation('deactivate simulation', true)
    @simulation.stop
    @simulation.reset
    Sketchup.active_model.commit_operation
  end

  def onLButtonDown(flags, x, y, view)
    super
    @ui.spring_pane.update_springs
    Sketchup.active_model.start_operation('Color static groups', true)
    static_groups = StaticGroupAnalysis.find_static_groups
    visualizer = NodeExportVisualization::Visualizer.new
    visualizer.color_static_groups static_groups
    Sketchup.active_model.commit_operation
    reset
    activate
  end

  def onMouseMove(_flags, x, y, view)
    super
    snapped_object = @mouse_input.snapped_object
    if snapped_object.is_a?(Edge) && snapped_object.link.is_a?(SpringLink) && !@scheduled_pistons.include?(snapped_object)
      @simulation.schedule_piston_for_testing(snapped_object, PISTON_SPEED)
      @scheduled_pistons.push snapped_object
      puts "added #{snapped_object}"
    end
    @scheduled_pistons.delete_if do |piston|
      if piston != snapped_object
        @simulation.unschedule_piston_for_testing piston, PISTON_SPEED
        puts "deleted: #{piston}"
      end
      piston != snapped_object
    end
    puts @scheduled_pistons
  end
end
