class GeometryAnimation
  attr_accessor :factor, :running
  def initialize(data, index = 0, &on_stop)
    @data = data
    @index = index
    @running = true
    @factor = 1
    @on_stop_block = on_stop

  end

  def stop
    @running = false
    @index = 0
    update_graph_with_data_sample @data[@index]
    @on_stop_block.call
  end

  def nextFrame(view)
    update_graph_with_data_sample @data[@index]

    view.refresh

    stop if @index + @factor >= @data.length

    @index += @factor

    view.refresh

    # Sketchup animations will continue to run as long as this method returns true and stop as soon as it returns false
    @running
  end

  def update_graph_with_data_sample(data_sample)
    # try to find a matching node (by id) in the graph and move it to the position parsed from current data sample
    data_sample.position_data.each do |node_id, position|
      node = Graph.instance.nodes[node_id.to_i]
      next unless node

      node.update_position(position)
      node.hub.update_position(position)
      node.hub.update_user_indicator
    end

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
    puts(data_sample.time_stamp)
  end

end
