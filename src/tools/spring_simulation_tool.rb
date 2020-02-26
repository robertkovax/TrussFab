require_relative 'tool.rb'
class SpringSimulationTool < Tool
  def initialize(ui)
    super(ui)

    # TODO replace by map edgeID => springConstant to support multiple springs
    # Spring constant
    @constant = 20000

    # Array of AnimationDataSamples, each containing geometry information for hubs for a certain point in time.
    @simulation_data = nil

    # Instance of the simulation runner used as an interface to the system simulation.
    @simulation_runner = nil

    # All spring links in the scene right now
    @spring_links = []

  end

  def activate
    # Instantiates SimulationRunner and compiles model.
    @simulation_runner ||= SimulationRunner.instance
  end


  private

  def simulate
    @simulation_data = @simulation_runner.get_hub_time_series
  end

  def set_graph_to_data_sample(index)
    current_data_sample = @simulation_data[index]

    Graph.instance.nodes.each do | node_id, node|
      node.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_user_indicator()
    end

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
  end

end
