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
    # Will be lazy initialized in nextFrame loop
    @label_position = nil

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

    current_position = current_data_sample.position_data[@node_id.to_s]

    @label_position ||= current_position.offset(Geom::Vector3d.new(0, 1, -1), 20.cm)

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
    entities.add_text("#{@period.round(2)}s", current_position, @label_position - current_position)


    view.refresh

    # Sketchup animations will continue to run as long as this method returns true and stop as soon as it returns false
    @running
  end

  # Finds closest data sample for a given time stamp.
  def next_valid_index(time_stamp)
    @data.find_index { |data_sample| data_sample.time_stamp.to_f >= time_stamp }
  end
end
