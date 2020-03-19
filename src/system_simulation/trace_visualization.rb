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
    @alpha = 0.2
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
      materialToSet.alpha = @alpha
      materialToSet
    end

    start_position = @simulation_data[0].position_data[node_id]
    last_position = @simulation_data[0].position_data[node_id]
    last_distance = 0

    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      #next unless index % sampling_rate == 0

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      entities = @group.entities
      position = current_data_sample.position_data[node_id]

      distance = position.distance(last_position)
      p distance

      edgearray = entities.add_circle(position, Geom::Vector3d.new(1,0,0), 1, 10)
      edgearray.each{|e| e.hidden=true }
      first_edge = edgearray[0]
      arccurve = first_edge.curve
      face = entities.add_face(arccurve)

      case distance
      when 0.0..0.5
        face.material = materials[2] unless face == nil
        p "green"
      when 0.5..5
        face.material = materials[1] unless face == nil
        p "orange"
      else
        face.material = materials[0] unless face == nil
        p "red"
      end
      last_position = position
      break if last_distance > distance

      last_distance = distance
    end
  end
end
