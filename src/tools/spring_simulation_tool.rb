require_relative 'tool.rb'
# A tool that modifies the scene according to results from system simulations.
class SpringSimulationTool < Tool
  def initialize(ui)
    super(ui)

    # TODO replace by map edgeID => springConstant to support multiple springs
    # Spring constant
    @constant = 20_000

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
    @spring_links = Graph.instance.edges.values.select { |edge| edge.link_type == 'spring' }.map(&:link)
  end


  private

  def simulate
    @simulation_data = @simulation_runner.get_hub_time_series(nil, 0, 0, @constant.to_i)
  end

  def set_graph_to_data_sample(index)
    current_data_sample = @simulation_data[index]

    Graph.instance.nodes.each do |node_id, node|
      node.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_position(current_data_sample.position_data[node_id.to_s])
      node.hub.update_user_indicator
    end

    Graph.instance.edges.each { |_, edge| edge.link.update_link_transformations }

  end

end
