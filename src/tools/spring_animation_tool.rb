require 'csv'
require 'src/spring_animation.rb'

class SpringAnimationTool < Tool
  def initialize(ui)
    super(ui)


    @data = CSV.read(ProjectHelper.asset_directory +
               '/exported_plot_data.csv')

    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
    @edge = nil
    @spring = nil
    @initial_edge_length = nil
    @initial_edge_position = nil
    @animation = nil
  end

  def onLButtonDown(_flags, x, y, view)
    if @animation
      @animation.halt
    end
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Edge) && obj.link_type == 'spring'
      @edge = obj

      @initial_edge_length = @edge.length
      @initial_edge_position = @edge.mid_point
      @first_vector = @initial_edge_position.vector_to(@edge.first_node.position)
      @second_vector = @initial_edge_position.vector_to(@edge.second_node.position)

      @animation = SpringAnimation.new(@data, @first_vector, @second_vector, @initial_edge_position, @edge)
      Sketchup.active_model.active_view.animation = @animation
    end


  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end




end
