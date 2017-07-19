require 'src/simulation/simulation'

class BallJointSimulation < Simulation
  def setup
    @world = MSPhysics::World.new
    @world.set_gravity(0, 0, 0)

    # create bodies for nodes and edges
    Graph.instance.nodes_and_edges.each do |obj|
      obj.thingy.create_body(@world)
    end

    # save transformation of current bodies for resetting
    save_transformations

    # create joints for each edge
    Graph.instance.edges.values.each do |edge|
      edge.create_ball_joints(@world)
    end
  end
end