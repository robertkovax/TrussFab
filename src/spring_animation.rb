class SpringAnimation
  attr_accessor :factor
  def initialize(data, first_vector, second_vector, initial_edge_position, edge)
    @data = data
    @first_vector = first_vector
    @second_vector = second_vector
    @initial_edge_position = initial_edge_position
    @edge = edge
    @index = 1
    @running = true
    @factor = 16

  end

  def halt
    @running = false;
  end

  def nextFrame(view)
    value = @data[@index]

    # new_position = Geom::Point3d.new(value[1].to_f().mm * 1000, value[2].to_f().mm * 1000, value[3].to_f().mm * 1000)
    new_position = Geom::Point3d.new(value[1], value[2], value[3])

    # scaled_first_vector = @first_vector.clone
    # scaled_first_vector.length = @first_vector.length * value[1].to_f.abs

    scaled_second_vector = @second_vector.clone
    scaled_second_vector.length = ((@second_vector.length * 2) * (1.0 + value[1].to_f) * @factor) - @second_vector.length

    # @edge.first_node.update_position(@initial_edge_position + scaled_first_vector)
    # @edge.first_node.hub.update_position(@edge.first_node.hub.position)

    @edge.second_node.update_position(new_position)
    puts(@edge.second_node.id)
    # @edge.second_node.update_position(@initial_edge_position + scaled_second_vector)
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
    @index = @index + @factor
    if @index + @factor >= @data.length
      @index = 0
      sleep(1)
    end

    return @running
  end
end
