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
    @colors = [Sketchup::Color.new(255,0,0), Sketchup::Color.new(255,255,0), Sketchup::Color.new(0,255,0)]
    @alpha = 0.6
  end

  def add_trace(node_ids, sampling_rate, data)
    reset_trace
    @simulation_data = data
    node_ids.each do |node_id|
      add_circle_trace(node_id, sampling_rate)
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
  end

  private

  def add_circle_trace(node_id, sampling_rate)
    materials = @colors.map do |color, index|
      materialToSet = Sketchup.active_model.materials.add("VisualizationColor #{index}")
      materialToSet.color = color
      materialToSet.alpha = 0.6
      materialToSet
    end

    start_position = @simulation_data[0].position_data[node_id]
    last_position = @simulation_data[0].position_data[node_id]
    last_distance = 0
    distance_to_start = 0
    curve_points = []

    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      #next unless index % sampling_rate == 0

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      entities = @group.entities
      position = current_data_sample.position_data[node_id]

      distance_to_last = position.distance(last_position)
      distance_to_start = position.distance(start_position)
      p distance_to_last

      edgearray = entities.add_circle(position, Geom::Vector3d.new(1,0,0), 1, 10)
      edgearray.each{|e| e.hidden=true }
      first_edge = edgearray[0]
      arccurve = first_edge.curve
      face = entities.add_face(arccurve)


      mocked_ratio = (distance_to_last / 0.7)

      face.material = material_from_hsv((1 - mocked_ratio) * 130, 100, 100)

      curve_points << position
      # detect turing point of oscillation
      break if last_distance > distance_to_start

      last_distance = distance_to_start
      last_position = position
    end

    # connect points with curve
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    entities = @group.entities
    entities.add_curve(curve_points)

  end

  def material_from_hsv(h,s,v)
    material = Sketchup.active_model.materials.add("VisualizationColor #{v}")
    material.color = hsv_to_rgb(h, s, v)
    material.alpha = 0.6
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
end
