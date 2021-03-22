require_relative './data_sample_visualization.rb'

require_relative '../sketchup_objects/amplitude_handle'

# Simulate data samples of a system simulation by plotting a trace consisting of transparent circles into the scene.
class TraceVisualization
  attr_reader :handles
  BAR_HEIGHT = 1.5
  LETTER_OFFSET = 1
  BAR_COLORS = [Sketchup::Color.new(47, 72, 94, 150), Sketchup::Color.new(37, 113, 181, 150), Sketchup::Color.new(114, 174, 227, 150)].freeze

  def initialize(visualization_offset: Geom::Vector3d.new(0, 0, 30))
    # Group containing trace circles.
    @group = Sketchup.active_model.active_entities.add_group

    # Group containing velocity / acceleration annotations
    @annotations_group = Sketchup.active_model.active_entities.add_group
    @annotations_group.layer = Configuration::MAXIMUM_ACCELERATION_VELOCITY_VIEW

    # List of trace circles.
    @trace_points = []

    # Visualization parameters
    #@color = Sketchup::Color.new(72,209,204)
    @colors = [Sketchup::Color.new(255, 0, 0), Sketchup::Color.new(255, 255, 0), Sketchup::Color.new(0, 255, 0)]

    @visualization_offset = visualization_offset
    @handles = []
  end

  def add_bars(node_ids, sampling_rate, data, user_stats)
    reset_trace
    @simulation_data = data
    @simulation_data.each do |age, simulation_data|
      index = @simulation_data.keys.index(age)
      node_ids.each do |node_id|
        add_bar(node_id, sampling_rate, user_stats[age][node_id], simulation_data, index, age)
      end
    end

  end

  # def add_trace(node_ids, sampling_rate, data, user_stats)
  #   reset_trace
  #   @simulation_data = data
  #   node_ids.each do |node_id|
  #     add_circle_trace(node_id, sampling_rate, user_stats[node_id])
  #   end
  # end

  def reset_trace
    Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a) if @group && !@group.deleted?
    Sketchup.active_model.active_entities.erase_entities(@trace_points) if @trace_points.count > 0

    @handles.each { |_, handles| handles.each(&:delete)}
    @trace_points = []
    @visualizations = []
    @handles = {} #node_id to handles [handle_one, handle_two]

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

  def handles_position_array
    @handles.map{ |_, handles| handles.map do |handle|
      {
        x: handle.position.x.to_mm,
        y: handle.position.y.to_mm,
        z: handle.position.z.to_mm,
      }
    end
    }
  end

  private

  def add_handles(curve, user_id)
    puts "curve0 #{curve[0]}"
    puts "curve1 #{curve[-1]}"
    one = add_handle curve[0], curve, user_id
    two = add_handle curve[-1], curve, user_id
    one.partner_handle = two
    two.partner_handle = one
    @handles[user_id] = [one, two]
  end

  def add_handle(position, curve, user_id)
    puts "Add handle: #{position}"
    handle = AmplitudeHandle.new position, movement_curve: curve
    handle
  end

  def add_bar(node_id, _sampling_rate, stats, simulation_data, bar_index, age_text)
    period = stats['period']
    period ||= 3.0
    start_index = stats['largest_amplitude']['start']
    end_index = stats['largest_amplitude']['end']

    puts 'Warn: largest amplitude in server respond was empty'  if start_index.nil? || end_index.nil?
    start_index ||= 0
    end_index ||= simulation_data.length - 1

    curve_points = []
    @visualizations = []
    offsetted_curve_points = []

    # trace_analyzation = (analyze_trace node_id, start_index, end_index, simulation_data)
    # max_distance = trace_analyzation[:max_distance]
    # TODO renable planar check
    # Plot dots for either the period or a certain time span, if oscillation is not planar
    # trace_time_limit = trace_analyzation[:is_planar] ? period.to_f : Configuration::NON_PLANAR_TRACE_DURATION
    # puts "Trace maximum distance: #{max_distance}"
    # puts "Trace is planar: #{trace_analyzation[:is_planar]}"

    circle_trace_layer =
        Sketchup.active_model.layers[Configuration::MOTION_TRACE_VIEW]

    # Calculate the static offset
    node = Graph.instance.nodes[node_id.to_i]
    adjacent_node_ids = node.adjacent_nodes[0..1].map(&:id)
    inverse_starting_rotation = nil

    simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      # next unless index % _sampling_rate == 0

      position = current_data_sample.position_data[node_id]

      curve_points << position

      first_adjacent_position = current_data_sample.position_data[adjacent_node_ids[0].to_s]
      second_adjacent_position = current_data_sample.position_data[adjacent_node_ids[1].to_s]

      vector_one = Geom::Vector3d.new(first_adjacent_position - position).normalize!
      vector_two = Geom::Vector3d.new(second_adjacent_position - position).normalize!

      rotation = Geometry.rotation_to_local_coordinate_system(vector_one, vector_two)
      inverse_starting_rotation = rotation.inverse if inverse_starting_rotation.nil?
      offset_vector = @visualization_offset.clone
      offset_vector.length = @visualization_offset.length + bar_index * BAR_HEIGHT
      offset = rotation * inverse_starting_rotation * offset_vector

      # offset_vector2 = @visualization_offset.clone
      # offset_vector2.length = @visualization_offset.length + BAR_HEIGHT
      # offset2 = rotation * inverse_starting_rotation * offset_vector2
      #
      # offset_vector3 = @visualization_offset.clone
      # offset_vector3.length = @visualization_offset.length + 2 * BAR_HEIGHT
      # offset3 = rotation * inverse_starting_rotation * offset_vector3

      offsetted_position = position + offset
      offsetted_curve_points << offsetted_position

      # offseted_position2 = position + offset2
      # offsetted_curve_points2 << offseted_position2
      #
      # offseted_position3 = position + offset3
      # offsetted_curve_points3 << offseted_position3
      # only plot dots within the largest amplitude, after that only draw the curve line
      next unless index >= start_index && index <= end_index

      # # distance to last point basically representing the speed (since time interval between data samples is fixed)
      # distance_to_last = position.distance(last_position)
      # # max_distance can be zero for non moving nodes
      # distance_ratio = (distance_to_last / max_distance)
      # distance_ratio = 0 if distance_ratio.nan? || distance_ratio.infinite?
      #
      # # invert distance ratio since high distance should plot a small and lightly colored dot
      # ratio = 1 - distance_ratio
      # ratio = Geometry.clamp(ratio, 0.0, 1.0)
      #
      # if (current_acceleration_is_max = max_acceleration_index == index)
      #   puts "maximum acceleration index: #{index}"
      #   add_label(offsetted_position, position.offset(Geom::Vector3d.new(0, 10.cm, 0)),"#{max_acceleration.round(3)}m/s^2 ")
      # end
      #
      # racceleration = stats["time_acceleration"][index]
      # acceleration = Geom::Vector3d.new(racceleration["x"].mm, racceleration["y"].mm, racceleration["z"].mm)
      # # puts "acceleration_length #{acceleration.length}"
      #
      # viz = DataSampleVisualization.new(offsetted_position, node_id, circle_definition, ratio,
      #                                   current_acceleration_is_max, acceleration.length, circle_definition)
      # @group = Sketchup.active_model.entities.add_group if @group.deleted?
      # @annotations_group = Sketchup.active_model.entities.add_group if @annotations_group.deleted?
      # @annotations_group.layer = Configuration::MAXIMUM_ACCELERATION_VELOCITY_VIEW
      # viz.add_dot_to_group(@group)
      #
      # raw_velocity = stats["time_velocity"][index]
      # velocity = Geom::Vector3d.new(raw_velocity["x"].mm, raw_velocity["y"].mm, raw_velocity["z"].mm)
      # viz.add_velocity_to_group(@annotations_group, velocity)
      #
      # raw_acceleration = stats["time_acceleration"][index]
      # acceleration = Geom::Vector3d.new(raw_acceleration["x"].mm, raw_acceleration["y"].mm, raw_acceleration["z"].mm)
      # viz.add_acceleration_to_group(@annotations_group, acceleration) #if current_acceleration_is_max
      #
      # @visualizations << viz
      #
      # last_position = position

    end

    # plot curve connecting all data points
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    entities = @group.entities
    entities.add_curve(offsetted_curve_points)
    entities.each do |entity|
      entity.layer = circle_trace_layer
    end
    # TODO somehow the edges of the interval are off
    draw_swipe entities, offsetted_curve_points[start_index + 2..end_index - 2], BAR_COLORS[bar_index % BAR_COLORS.count] , age_text

    add_handles(offsetted_curve_points[start_index..end_index], node_id.to_i)
  end

  def draw_swipe(group_entities, curve, color, text)
    curve_plane =  Geom.fit_plane_to_points(curve)
    curve_plane = Geometry.normalize_plane(curve_plane) if curve_plane.count == 4
    curve_plane_normal = curve_plane[1].normalize

    bar_definition = Sketchup.active_model.definitions.add "Circle Trace Visualization"
    entities = bar_definition.entities
    # TODO duplicate
    depth = BAR_HEIGHT * 2
    width = BAR_HEIGHT
    pts = []
    pts[0] = Geom::Point3d.new(-depth / 2, 0, -width / 2)
    pts[1] = Geom::Point3d.new(-depth / 2, 0, width / 2)
    pts[2] = Geom::Point3d.new(depth / 2, 0, width / 2)
    pts[3] = Geom::Point3d.new(depth / 2, 0, -width / 2)

    profile_normal = (curve[1] - curve[0]).normalize
    translation_vector = curve[0]
    # mapping x axis to the curve plane normal and y axis to profile normal
    rotation = Geometry.rotation_to_local_coordinate_system(curve_plane_normal, profile_normal)
    translation = Geom::Transformation.translation(translation_vector)
    transform = translation * rotation

    pts = pts.map{|pt|  pt.transform(transform)}

    face = entities.add_face(pts)

    edges = entities.add_curve(curve)
    face.followme(edges)

    bar_instance = group_entities.add_instance(bar_definition, Geom::Transformation.new)

    material = Sketchup.active_model.materials.add("VisualizationColor ")
    material.color = color
    material.alpha = 0.8

    bar_instance.material = material

    letter_definition = Sketchup.active_model.definitions.add "Letter"
    success = letter_definition.entities.add_3d_text(text, TextAlignLeft, "Arial",true, false, BAR_HEIGHT, 0.0, 0, true, 0.1)
    end_normal_vector = curve[curve.count - 1] - curve[curve.count - 2]
    # positions the letter nicely centered along the curve
    letter_spacing_translation = Geom::Transformation.translation(Geom::Vector3d.new(LETTER_OFFSET, -BAR_HEIGHT / 2, 0))
    # rotates the letter correclty so we can map it using rotation_to_local_coordinate_system (must be in XY plane)
    rotationXZ = Geometry.rotation_transformation(Geom::Vector3d.new(1, 0, 0), Geom::Vector3d.new(0, 0, 1), Geom::Point3d.new(0, 0, 0))
    # rotates the letter to point along the bar surface
    rotation = Geometry.rotation_to_local_coordinate_system(curve_plane_normal, Geom::Vector3d.new(0, 0, 1))
    translation = Geom::Transformation.translation(curve[curve.count - 1])
    transform = Geom::Transformation.new translation * rotation * rotationXZ * letter_spacing_translation

    letter_instance = group_entities.add_instance(letter_definition, transform)
    letter_instance.material = material

  end

  # analyzes the simulation data for certain criterions
  def analyze_trace(node_id, start_index, end_index, simulation_data)
    last_position = simulation_data[start_index].position_data[node_id]
    max_distance = 0
    is_planar = true
    plane = Geom.fit_plane_to_points([last_position, simulation_data[1].position_data[node_id],
                                      simulation_data[2].position_data[node_id]])
    (start_index..end_index).each do | index |
      current_data_sample = simulation_data[index]
      position = current_data_sample.position_data[node_id]
      distance_to_last = position.distance(last_position)
      max_distance = distance_to_last if distance_to_last > max_distance
      is_planar = position.distance_to_plane(plane) < Configuration::DISTANCE_TO_PLANE_THRESHOLD
      last_position = position
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
