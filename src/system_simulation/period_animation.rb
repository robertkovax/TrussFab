class PeriodAnimation
  attr_accessor :factor, :running

  def initialize(data, period, node_id, index = 0, &on_stop)
    # simulation data
    @data = data
    @node_id = node_id
    @period = period
    @index = index
    @running = true
    @factor = 1

    @group = Sketchup.active_model.entities.add_group

    # callback to notify listeners about animation stop
    @on_stop_block = on_stop

    # time keeping
    @start_time = Time.now.to_f

    @pulse_position = @data[0].position_data[@node_id.to_s].offset(Geom::Vector3d.new(0, 1, 0), 30.cm)
    @pulse_definition = create_pulse
  end

  def stop
    @running = false
    @index = 0

    # Remove objects from last frames
    if @group && !@group.deleted?
      Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a)
    end

    @on_stop_block.call
    @running
  end

  def nextFrame(view)
    now = Time.now.to_f
    ellapsed_time = now - @start_time
    @index = next_valid_index(ellapsed_time)
    if ellapsed_time > @period
      @start_time = now
      @index = 0
    end

    return stop unless @index

    current_data_sample = @data[@index]

    # Remove objects from last frames
    if @group && !@group.deleted?
      Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a)
    end

    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    @group.layer = Configuration::SPRING_INSIGHTS
    entities = @group.entities

    #materialToSet = Sketchup.active_model.materials.add("MyColor_1")
    #materialToSet.color = Sketchup::Color.Red;
    #materialToSet.alpha = 1.0

    current_position = current_data_sample.position_data[@node_id.to_s]

    radius = 1
    num_segments = 20
    circle = entities.add_circle(current_position, Geom::Vector3d.new(1,0,0), radius, num_segments)
    face = entities.add_face(circle)
    face.material = [200, 200, 200]
    face.back_material = [200, 200, 200]
    face.reverse!
    # Create a temporary path for follow me to use to perform the revolve.
    # This path should not touch the face.
    path = entities.add_circle(current_position, Geom::Vector3d.new(0,0,1), radius * 2, num_segments)
    # This creates the sphere.
    face.followme(path)

    entities.erase_entities(path)

    # Add period label
    # TODO: Add label to Configuration::SPRING_INSIGHTS layer
    # TODO: how to correctly achieve offsetting direction
    label = entities.add_text("#{@period.round(2)}s", current_position.offset(Geom::Vector3d.new(0,1,0), 5.cm))
    label.line_weight = 40

    scale_pulse(@pulse_definition, (((@period - ellapsed_time).abs / @period) - (@period / 2)).abs)
    #update_graph_with_data_sample @data[@index]

    view.refresh

    # Sketchup animations will continue to run as long as this method returns true and stop as soon as it returns false
    @running
  end

  def create_pulse()
    pulse_definition = Sketchup.active_model.definitions.add "Circle Trace Visualization"
    entities = pulse_definition.entities

    radius = 8.cm
    num_segments = 20
    circle = entities.add_circle(@pulse_position, Geom::Vector3d.new(1,0,0), radius, num_segments)
    face = entities.add_face(circle)
    face.material = [252, 186, 3]
    face.back_material = [252, 186, 3]
    face.reverse!
    # Create a temporary path for follow me to use to perform the revolve.
    # This path should not touch the face.
    path = entities.add_circle(@pulse_position, Geom::Vector3d.new(0,0,1), radius * 2, num_segments)
    # This creates the sphere.
    face.followme(path)
    entities.erase_entities(path)

    pulse_definition
  end

  def scale_pulse(definition, factor)
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    @group.layer = Configuration::SPRING_INSIGHTS

    transformation = Geom::Transformation.scaling(@pulse_position, factor)
    pulse_instance = @group.entities.add_instance(definition, transformation)
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
      node.hub.update_user_indicator
      node.adjacent_triangles.each { |triangle| triangle.update_sketchup_object if triangle.cover }
    end

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
    puts(data_sample.time_stamp)
  end

end
