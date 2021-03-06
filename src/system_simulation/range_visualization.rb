require_relative './data_sample_visualization.rb'
require 'src/sketchup_objects/amplitude_handle'

# Show the maximum amplitude of the visualization
class RangeVisualization
  attr_accessor :handles

  def initialize
    # Simulation data to visualize
    @simulation_data = nil

    # Sketchup group to contain the line
    @group = nil

    @handles = []

  end

  def add_trace(node_ids, sampling_rate, data, user_stats)
    reset_trace
    @simulation_data = data
    node_ids.each do |node_id|
      stats = user_stats[node_id.to_i]
      max_node_indices = stats['max_node_indices']
      # TODO: Currently mocked
      max_node_indices ||= [200, 250]
      curve = calculate_offsetted_curve(node_id, sampling_rate, max_node_indices)

      add_range_trace(curve)
      add_handles(curve, max_node_indices)
    end
  end

  def reset_trace
    Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a) if @group && !@group.deleted?
    @handles.each(&:delete)
  end

  private

  def add_handles(curve, max_node_ids)
    add_handle curve[0]
    add_handle curve[-1]
  end

  def add_handle(position)
    puts "Add handle: #{position}"
    handle = AmplitudeHandle.new position
    @handles << handle
  end


  def calculate_offsetted_curve(node_id, _sampling_rate, max_node_indices)
    visualization_offset = Geom::Vector3d.new(0, 0, 30)

    # TODO: This conversation should be way earlier
    node_id = node_id.to_i
    node = Graph.instance.nodes[node_id]
    adjacent_node_ids = node.adjacent_nodes[0..1].map(&:id)

    inverse_starting_rotation = nil

    @curve_points_with_offset = (max_node_indices[0]..max_node_indices[1]).map do |index|
      # puts "Current index: #{index}"
      node_position = @simulation_data[index].position_data[node_id.to_s]
      first_adjacent_position = @simulation_data[index].position_data[adjacent_node_ids[0].to_s]
      second_adjacent_position = @simulation_data[index].position_data[adjacent_node_ids[1].to_s]

      vector_one = Geom::Vector3d.new(first_adjacent_position - node_position).normalize!
      vector_two = Geom::Vector3d.new(second_adjacent_position - node_position).normalize!

      rotation = Geometry.rotation_to_local_coordinate_system(vector_one, vector_two)
      inverse_starting_rotation = rotation.inverse if inverse_starting_rotation.nil?
      offset = rotation * inverse_starting_rotation * visualization_offset

      node_position + offset
    end

  end

  def add_range_trace(curve)
    # plot curve connecting all data points
    @group = Sketchup.active_model.entities.add_group if !@group || @group.deleted?
    entities = @group.entities
    entities.add_curve(curve)
    # TODO: Might want to put this to another layer
    # entities.each do |entity|
    #   entity.layer = circle_trace_layer
    # end
  end
end
