require 'src/system_simulation/ragdoll.rb'

class GeometryAnimation
  attr_accessor :factor, :running
  def initialize(data, index = 0)
    @data = data
    @index = index
    @running = true
    @factor = 1

    @ragdoll = Ragdoll.new
  end

  def toggle_running
    @running = !@running

    @ragdoll.clear
    @ragdoll = Ragdoll.new
    puts "new ragdoll"
  end

  def nextFrame(view)
    Sketchup.active_model.start_operation('visualize export result', true)
    unless (@running)
      # last frame before animation stops – so we set value to last data sample and reset index to reset animation
      @index = 0
    end
    # @index = 8 # Disables animation to debug ragdoll
    current_data_sample = @data[@index]

    Graph.instance.nodes.each do |node_id, node|
      node.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_user_indicator
    end

    @ragdoll.position = Graph.instance.nodes.values[0].position
    @ragdoll.advance

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
    puts(current_data_sample.time_stamp)

    ## new_position = Geom::Point3d.new(value[1].to_f().mm * 1000, value[2].to_f().mm * 1000, value[3].to_f().mm * 1000)
    #new_position = Geom::Point3d.new(value[1], value[2], value[3])
    #
    #scaled_second_vector = @second_vector.clone
    #scaled_second_vector.length = ((@second_vector.length * 2) * (1.0 + value[1].to_f) * @factor) - @second_vector.length
    #
    #@edge.second_node.update_position(new_position)
    #@edge.second_node.hub.update_position(@edge.second_node.hub.position)
    #
    #Graph.instance.edges.each do |_, edge|
    #  link = edge.link
    #  link.update_link_transformations
    #end
    Sketchup.active_model.commit_operation
    view.refresh
    @index = @index + @factor
    if @index + @factor >= @data.length
      @index = 0
      sleep(1)
    end

    @running
  end
end
