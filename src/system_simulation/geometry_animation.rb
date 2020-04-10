class GeometryAnimation
  attr_accessor :factor, :running
  def initialize(data, index = 0, &on_stop)
    # simulation data
    @data = data
    @index = index
    @running = true
    @factor = 1

    # callback to notify listeners about animation stop
    @on_stop_block = on_stop

    # time keeping
    @start_time = Time.now.to_f
  end


  def stop
    @running = false
    @index = 0
    update_graph_with_data_sample @data[@index]
    puts "on_stop_block: #{@on_stop_block}"
    @on_stop_block.call
    @running
  end

  def nextFrame(view)
    now = Time.now.to_f
    @index = next_valid_index(now - @start_time)

    return stop unless @index

    update_graph_with_data_sample @data[@index]

    view.refresh

    # Sketchup animations will continue to run as long as this method returns true and stop as soon as it returns false
    @running
  end

  def next_valid_index(time_stamp)
    @data.find_index { |data_sample| data_sample.time_stamp.to_f >= time_stamp }
  end

  def update_graph_with_data_sample(data_sample)
    # try to find a matching node (by id) in the graph and move it to the position parsed from current data sample
    data_sample.position_data.each do |node_id, position|
      node = Graph.instance.nodes[node_id.to_i]
      next unless node

      node.update_position(position)
      node.hub.update_position(position)
      if node.hub.is_user_attached
        additional_transformation = data_sample.rotation_data[node_id]
        puts "Rotation matrix: #{additional_transformation.to_a}"
        node.hub.update_user_indicator additional_transformation: additional_transformation
      else
        node.hub.update_user_indicator
      end
      node.adjacent_triangles.each { |triangle| triangle.update_sketchup_object if triangle.cover }
    end

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
    puts(data_sample.time_stamp)
  end

end
