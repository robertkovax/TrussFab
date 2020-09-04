require 'src/tools/link_tool.rb'
require 'src/export/node_export_visualization'

# creates a gas spring-type link
class SpringTool < ActuatorTool

  PISTON_SPEED = 0.5
  ANIMATE = Configuration::PLACE_SPRING_ANIMATIONS

  def initialize(ui)
    super(ui, 'spring')
  end

  def activate
    super
    @ui.spring_pane.update_springs
    @ui.spring_pane.color_static_groups
    if ANIMATE
      @scheduled_pistons = []
      @simulation = Simulation.new
      @simulation.disable_coloring
      @simulation.setup
      @simulation.disable_gravity

      Sketchup.active_model.active_view.animation = @simulation
      @simulation.start
      Sketchup.active_model.commit_operation
    end
  end

  def deactivate(view)
    super
    reset if ANIMATE
  end

  def reset
    Sketchup.active_model.start_operation('deactivate simulation', true)
    Sketchup.active_model.active_view.animation = nil
    @simulation.stop
    @simulation.reset
    Sketchup.active_model.commit_operation
  end

  def onLButtonDown(flags, x, y, view)
    super
    @ui.spring_pane.update_springs
    @ui.spring_pane.color_static_groups
    if ANIMATE
      reset
      activate
    end
  end

  # Adds springs into the @scheduled_pistons, and removes them if their are not
  # hovered any more
  def onMouseMove(_flags, x, y, view)
    super
    if ANIMATE
      snapped_object = @mouse_input.snapped_object
      if snapped_object.is_a?(Edge) && snapped_object.link.is_a?(SpringLink) &&
         !@scheduled_pistons.include?(snapped_object)
        @simulation.schedule_piston_for_testing(snapped_object, PISTON_SPEED)
        @scheduled_pistons.push snapped_object
      end
      @scheduled_pistons.delete_if do |piston|
        @simulation.unschedule_piston_for_testing piston, PISTON_SPEED if piston != snapped_object
        piston != snapped_object
      end

      Sketchup.active_model.layers[Configuration::MOTION_TRACE_VIEW].visible =
        @scheduled_pistons.empty?
    end
  end
end
