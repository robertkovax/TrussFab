class GeometryAnimation
  attr_accessor :factor, :running
  def initialize(data, index = 0)
    @data = data
    @index = index
    @running = true
    @factor = 1

  end

  def toggle_running
    @running = !@running;
  end

  def nextFrame(view)
    update_graph_with_data_sample @data[@index]

    view.refresh

    if @index + @factor >= @data.length
      @running = false
      update_graph_with_data_sample @data[0]
    end
    @index += @factor

    view.refresh

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
