# Simulate data samples of a system simulation by plotting a trace consisting of transparent circles into the scene.
class TraceVisualization
  def initialize(data)
    # Simulation data to visualize
    @simulation_data = data

    # Group containing trace circles.
    @group = Sketchup.active_model.active_entities.add_group

    # List of trace circles.
    @trace_points = []
  end

  def add_trace(node_ids, sparce_factor)
    add_circle_trace(node_ids, sparce_factor)
  end

  def reset_trace()
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a)
    if @trace_points.count > 0
      Sketchup.active_model.active_entities.erase_entities(@trace_points)
    end
    @trace_points = []
  end

  private

  def add_circle_trace(node_ids, sparse_factor)
    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      next unless index % sparse_factor == 0

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      entities = @group.entities

      color = Sketchup::Color.new(72,209,204)
      materialToSet = Sketchup.active_model.materials.add("MyColor_1")
      materialToSet.color = color
      materialToSet.alpha = 0.4

      edgearray = entities.add_circle(current_data_sample.position_data[node_ids[0]], Geom::Vector3d.new(1,0,0), 1, 10)
      edgearray.each{|e| e.hidden=true }
      first_edge = edgearray[0]
      arccurve = first_edge.curve
      face = entities.add_face(arccurve)
      face.material = materialToSet unless face == nil

      edgearray = entities.add_circle(current_data_sample.position_data[node_ids[1]], Geom::Vector3d.new(1,0,0), 1, 10)
      edgearray.each{|e| e.hidden=true }
      first_edge = edgearray[1]
      arccurve = first_edge.curve
      face = entities.add_face(arccurve)
      face.material = materialToSet unless face == nil

      #    entities.grep(Sketchup::Edge).each{|e| e.hidden=true }
    end
  end

  ### Currently unused trace visualizations:

  # Visualize trace using spheres.
  def add_sphere_trace(node_ids, sparse_factor)
    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      next unless index % sparse_factor == 0

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      entities = @group.entities

      color = Sketchup::Color.new(72,209,204)
      materialToSet = Sketchup.active_model.materials.add("MyColor_1")
      materialToSet.color = color
      materialToSet.alpha = 0.2

      radius = 1
      num_segments = 20
      circle = entities.add_circle(current_data_sample.position_data[node_ids[0]], Geom::Vector3d.new(1,0,0), radius, num_segments)
      face = entities.add_face(circle)
      face.material = materialToSet unless face.deleted?
      face.back_material = materialToSet unless face.deleted?
      face.reverse!
      # Create a temporary path for follow me to use to perform the revolve.
      # This path should not touch the face.
      path = entities.add_circle(current_data_sample.position_data[node_ids[0]], Geom::Vector3d.new(0,0,1), radius * 2, num_segments)
      # This creates the sphere.
      face.followme(path)

      entities.erase_entities(path)


      circle = entities.add_circle(current_data_sample.position_data[node_ids[1]], Geom::Vector3d.new(1,0,0), radius, num_segments)
      face = entities.add_face(circle)
      face.material = materialToSet unless face.deleted?
      face.back_material = materialToSet unless face.deleted?
      face.reverse!
      # Create a temporary path for follow me to use to perform the revolve.
      # This path should not touch the face.
      path = entities.add_circle(current_data_sample.position_data[node_ids[1]], Geom::Vector3d.new(0,0,1), radius * 2, num_segments)
      # This creates the sphere.
      face.followme(path)

      entities.erase_entities(path)

      #    entities.grep(Sketchup::Edge).each{|e| e.hidden=true }
    end
  end


  # Visualize trace using construction points.
  def add_point_trace(node_ids, sparse_factor)
    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      next unless index % sparse_factor == 0

      model = Sketchup.active_model
      entities = model.active_entities
      @trace_points << entities.add_cpoint(current_data_sample.position_data[node_ids[0]])
      @trace_points << entities.add_cpoint(current_data_sample.position_data[node_ids[1]])
      #puts(current_data_sample.time_stamp)
    end
  end
end
