# Simulate data samples of a system simulation by plotting a trace consisting of transparent circles into the scene.
class TraceVisualization
  TRACE_DOT_ALPHA = 0.6

  def initialize
    # Simulation data to visualize
    @simulation_data = nil

    # Group containing trace circles.
    @group = Sketchup.active_model.active_entities.add_group

    # List of trace circles.
    @trace_points = []

    # Visualization parameters
    #@color = Sketchup::Color.new(72,209,204)
    @colors = [Sketchup::Color.new(255,0,0), Sketchup::Color.new(255,255,0), Sketchup::Color.new(0,255,0)]
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

    @id_label.erase! if @id_label && @id_label.valid?
  end

  private

  def add_circle_trace(node_id, _sampling_rate, stats)
    period = stats['period']
    period ||= 3.0

    max_acceleration_index = stats['max_acceleration']['index']

    last_position = @simulation_data[0].position_data[node_id]
    curve_points = []

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

      # Transform circle definition to match current data sample
      # dots shouldn't be scaled down below half the original size
      scale_factor = Geometry.clamp(ratio, 0.5, 1.0)
      scaling = Geom::Transformation.scaling(scale_factor, 1.0, scale_factor)
      translation = Geom::Transformation.translation(position)
      transformation = translation * scaling

      color_min_value = 50.0
      color_max_value = 100.0
      color_hue = 117
      color_weight = ratio * color_min_value

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      circle_instance = @group.entities.add_instance(circle_definition, transformation)
      circle_instance.layer = circle_trace_layer
      if max_acceleration_index == index
        puts "maximum acceleration index: #{index}"
        circle_instance.material = "red"
        add_label(position, position.offset(Geom::Vector3d.new(0,10.cm, 0)) ,"    #{stats['max_acceleration']['value'].round(3)}m/s^2 ")
      else
        circle_instance.material = material_from_hsv(color_hue, color_min_value + color_weight,
                                                     color_max_value - color_weight)
      end
      raw_acceleration = stats["time_velocity"][index]
      acceleration = Geom::Vector3d.new(raw_acceleration["x"].mm, raw_acceleration["y"].mm, raw_acceleration["z"].mm)
      @group.entities.add_cline(position, position + acceleration)

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
      return { max_distance: max_distance, is_planar: is_planar } if current_data_sample.time_stamp.to_f >= period.to_f
    end
    { max_distance: max_distance, is_planar: is_planar }
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
    edgearray.each{ |e| e.hidden = true }
    first_edge = edgearray[0]
    arccurve = first_edge.curve
    entities.add_face(arccurve)
    circle_definition
  end

  def material_from_hsv(h,s,v)
    material = Sketchup.active_model.materials.add("VisualizationColor #{v}")
    material.color = hsv_to_rgb(h, s, v)
    material.alpha = TRACE_DOT_ALPHA
    material
  end

  # http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically
  def hsv_to_rgb(h, s, v)
    h, s, v = h.to_f/360, s.to_f/100, v.to_f/100
    h_i = (h*6).to_i
    f = h*6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)
    r, g, b = v, t, p if h_i==0
    r, g, b = q, v, p if h_i==1
    r, g, b = p, v, t if h_i==2
    r, g, b = p, q, v if h_i==3
    r, g, b = t, p, v if h_i==4
    r, g, b = v, p, q if h_i==5
    # [(r*255).to_i, (g*255).to_i, (b*255).to_i]
    Sketchup::Color.new((r*255).to_i, (g*255).to_i, (b*255).to_i)
  end

  # Places a describing label at the given position.
  def add_label(described_item_position, label_position, label_text)
    # always recreate label
    @id_label.erase! if @id_label && @id_label.valid?

    @id_label = Sketchup.active_model.entities.add_text(label_text,
                                                        described_item_position, label_position - described_item_position)
    @id_label.layer = Sketchup.active_model.layers[Configuration::SPRING_INSIGHTS]
  end
end
