require 'src/tools/tool'

class StaticForceAnalyserTool < Tool
  def activate
    @states = []
    for length in (0.0..1.0).step(1.0 / Configuration::STATIC_FORCE_ANALYSIS_STEPS)
      @states.push(length)
    end
    static_force_analysis
  end

  def static_force_analysis
    @transformed_pid_edges = {}
    Graph.instance.edges.each do |id, edge|
      if edge.link_type == 'pid_controller'
        Graph.instance.edges[id].link_type = 'actuator'
        @transformed_pid_edges[id] = Graph.instance.edges[id]
      end
    end
    # TODO: make max/min length of pid controller fit to actuator length
    Sketchup.active_model.active_view.invalidate
    @combinations =
      @states.repeated_permutation(@transformed_pid_edges.length).map do |values|
        @transformed_pid_edges.map {|piston| piston[0]}.zip(values).to_h
      end
    @simulation = Simulation.new
    @simulation.setup
    @combinations_with_force = []
    @combinations.each do |positions|
      forces = @simulation.analyse_pose(positions)
      merged = forces.merge(positions) {|id, force, position| [position, force]}
      @combinations_with_force.push(merged)

    end
    puts @combinations_with_force
    @simulation.stop
    @simulation.reset
    remake_to_pid_controllers
    save_force_values
  end

  def remake_to_pid_controllers
    @transformed_pid_edges.each do |id, _|
      Graph.instance.edges[id].link_type = 'pid_controller'
    end
    # TODO: restore controller values the controllers had before
  end

  def save_force_values
    if @transformed_pid_edges.length > 1
      puts "Right now it is not possible to store the forces for more than one controller"
      return
    end
    @transformed_pid_edges.each do |id, _|
      thingy = Graph.instance.edges[id].thingy
      force_array = []
      @combinations_with_force.each do |id, force|
        force_array.push(force)
      end
      puts force_array
      thingy.static_forces_lookup = force_array
    end
  end
end
