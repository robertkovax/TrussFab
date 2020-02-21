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
    @color = Sketchup::Color.new(72,209,204)
    @alpha = 0.4
  end

  def add_trace(node_ids, sampling_rate, data)
    @simulation_data = data
    node_ids.each do |node_id|
      add_circle_trace(node_id, sampling_rate)
    end
  end

  def reset_trace
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a)
    if @trace_points.count > 0
      Sketchup.active_model.active_entities.erase_entities(@trace_points)
    end
    @trace_points = []
  end

  private

  def add_circle_trace(node_id, sampling_rate)
    @simulation_data.each_with_index do |current_data_sample, index|
      # thin out points in trace
      next unless index % sampling_rate == 0

      @group = Sketchup.active_model.entities.add_group if @group.deleted?
      entities = @group.entities

      materialToSet = Sketchup.active_model.materials.add("VisualizationColor")
      materialToSet.color = @color
      materialToSet.alpha = @alpha

      edgearray = entities.add_circle(current_data_sample.position_data[node_id], Geom::Vector3d.new(1,0,0), 1, 10)
      edgearray.each{|e| e.hidden=true }
      first_edge = edgearray[0]
      arccurve = first_edge.curve
      face = entities.add_face(arccurve)
      face.material = materialToSet unless face == nil
    end
  end
end
