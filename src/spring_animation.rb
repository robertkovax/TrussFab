class SpringAnimation
  attr_accessor :factor
  def initialize(data, first_vector, second_vector, initial_edge_position, edge)
    @data = data
    @first_vector = first_vector
    @second_vector = second_vector
    @initial_edge_position = initial_edge_position
    @edge = edge
    @index = 0
    @running = true
    @factor = 1.0;

  end

  def halt
    @running = false;
  end

  def nextFrame(view)
    value = @data[@index];
    # scaled_first_vector = @first_vector.clone
    # scaled_first_vector.length = @first_vector.length * value[1].to_f.abs

    scaled_second_vector = @second_vector.clone
    scaled_second_vector.length = ((@second_vector.length * 2) * (1.0 + value[1].to_f) * @factor) - @second_vector.length

    # @edge.first_node.update_position(@initial_edge_position + scaled_first_vector)
    # @edge.first_node.hub.update_position(@edge.first_node.hub.position)
    @edge.second_node.update_position(@initial_edge_position + scaled_second_vector)
    @edge.second_node.hub.update_position(@edge.second_node.hub.position)
    # @edge.link.update_positions(@initial_edge_position + scaled_first_vector, @initial_edge_position + scaled_second_vector)

    # @edge.update_sketchup_object
    # @edge.first_node.update_sketchup_object
    # @edge.second_node.update_sketchup_object

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
      # edge.update_sketchup_object
    end
    view.refresh
    @index = @index + 1
    if @index == @data.length
      @index = 0
      sleep(1)
    end

    return @running
  end
end
