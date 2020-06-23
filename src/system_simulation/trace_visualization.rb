require_relative './data_sample_visualization.rb'

# Simulate data samples of a system simulation by plotting a trace consisting of transparent circles into the scene.
class TraceVisualization

  def initialize
    # Simulation data to visualize
    @simulation_data = nil

    # Group containing trace circles.
    @group = Sketchup.active_model.active_entities.add_group

    # List of trace circles.
    @trace_points = []

    # Visualization parameters
    #@color = Sketchup::Color.new(72,209,204)
    @colors = [Sketchup::Color.new(255, 0, 0), Sketchup::Color.new(255, 255, 0), Sketchup::Color.new(0, 255, 0)]
  end

  def add_trace(node_ids, sampling_rate, data, user_stats)
    reset_trace
    @simulation_data = data
    node_ids.each do |node_id|
      add_circle_trace(node_id, sampling_rate, user_stats[node_id.to_i])
    end
  end

  def reset_trace
    if @group && !@group.deleted?
      Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a)
    end
    if @trace_points.count > 0
      Sketchup.active_model.active_entities.erase_entities(@trace_points)
    end
    @trace_points = []
    @visualizations = []

    @max_acceleration_label.erase! if @max_acceleration_label && @max_acceleration_label.valid?
  end

  def closest_visualization(point)
    return if @visualizations.length == 0
    @visualizations.min_by do |viz|
      point.distance(viz.position)
    end
  end

  def visualization_valid?(visualization)
    @visualizations.include? visualization
  end

  private

  def add_circle_trace(node_id, _sampling_rate, stats)
    period = stats['period']
    period ||= 3.0

    max_acceleration = stats['max_acceleration']['value']
    max_acceleration_index = stats['max_acceleration']['index']
    current_acceleration_is_max = false

    last_position = @simulation_data[0].position_data[node_id]
    curve_points = []
    @visualizations = []

    trace_analyzation = (analyze_trace node_id, period)
    max_distance = trace_analyzation[:max_distance]
    # Plot dots for either the period or a certain time span, if oscillation is not planar
    trace_time_limit = trace_analyzation[:is_planar] ? period.to_f : Configuration::NON_PLANAR_TRACE_DURATION
    puts "Trace maximum distance: #{max_distance}"
    puts "Trace is planar: #{trace_analyzation[:is_planar]}"

    circle_definition = create_circle_definition
    circle_trace_layer =
        Sketchup.active_model.layers[Configuration::MOTION_TRACE_VIEW]

    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      # next unless index % _sampling_rate == 0

      position = current_data_sample.position_data[node_id]

      curve_points << position

      # only plot dots for first period, after that only draw the curve line
      break if current_data_sample.time_stamp.to_f >= trace_time_limit

      # distance to last point basically representing the speed (since time interval between data samples is fixed)
      distance_to_last = position.distance(last_position)
      distance_ratio = (distance_to_last / max_distance)

      # invert distance ratio since high distance should plot a small and lightly colored dot
      ratio = 1 - distance_ratio

      if (current_acceleration_is_max = max_acceleration_index == index)
        puts "maximum acceleration index: #{index}"
        add_label(position, position.offset(Geom::Vector3d.new(0, 10.cm, 0)),"#{max_acceleration.round(3)}m/s^2 ")
      end

      viz = DataSampleVisualization.new(current_data_sample, node_id, circle_definition, ratio,
                                        current_acceleration_is_max, circle_definition)
      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      viz.add_dot_to_group(@group)

      raw_velocity = stats["time_velocity"][index]
      velocity = Geom::Vector3d.new(raw_velocity["x"].mm, raw_velocity["y"].mm, raw_velocity["z"].mm)
      viz.add_velocity_to_group(@group, velocity)

      raw_acceleration = stats["time_acceleration"][index]
      acceleration = Geom::Vector3d.new(raw_acceleration["x"].mm, raw_acceleration["y"].mm, raw_acceleration["z"].mm)
      viz.add_acceleration_to_group(@group, acceleration)

      @visualizations << viz

      last_position = position
    end

    # plot curve connecting all data points
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    entities = @group.entities
    entities.add_curve(curve_points)
    entities.each do |entity|
      entity.layer = circle_trace_layer
    end
  end

  # analyzes the simulation data for certain criterions
  def analyze_trace(node_id, period)
    last_position = @simulation_data[0].position_data[node_id]
    max_distance = 0
    is_planar = true
    plane = Geom.fit_plane_to_points([last_position, @simulation_data[1].position_data[node_id],
                                      @simulation_data[2].position_data[node_id]])
    @simulation_data.each_with_index do |current_data_sample, index|
      position = current_data_sample.position_data[node_id]
      distance_to_last = position.distance(last_position)
      max_distance = distance_to_last if distance_to_last > max_distance
      is_planar = position.distance_to_plane(plane) < Configuration::DISTANCE_TO_PLANE_THRESHOLD
      last_position = position
      return {max_distance: max_distance, is_planar: is_planar} if current_data_sample.time_stamp.to_f >= period.to_f
    end
    {max_distance: max_distance, is_planar: is_planar}
  end

  def difference_plane(plane_a, plane_b)
    return [0, 0, 0, 0] unless plane_a && plane_b
    plane_a.map.with_index { |coefficient_a, index| (coefficient_a - plane_b[index]).abs }
  end

  def create_circle_definition
    circle_definition = Sketchup.active_model.definitions.add "Circle Trace Visualization"
    circle_definition.behavior.always_face_camera = true
    entities = circle_definition.entities
    # always_face_camera will try to always make y axis face the camera
    edgearray = entities.add_circle(Geom::Point3d.new, Geom::Vector3d.new(0, -1, 0), 1, 10)
    edgearray.each { |e| e.hidden = true }
    first_edge = edgearray[0]
    arccurve = first_edge.curve
    entities.add_face(arccurve)
    circle_definition
  end

  # Places a describing label at the given position.
  def add_label(described_item_position, label_position, label_text)
    # always recreate label
    @max_acceleration_label.erase! if @max_acceleration_label && @max_acceleration_label.valid?

    @max_acceleration_label = Sketchup.active_model.entities.add_text(label_text,
                                                        described_item_position, label_position - described_item_position)
    @max_acceleration_label.layer = Sketchup.active_model.layers[Configuration::SPRING_INSIGHTS]
  end
end
