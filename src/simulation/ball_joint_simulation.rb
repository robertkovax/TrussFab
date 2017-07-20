require 'src/simulation/simulation'

class BallJointSimulation < Simulation
  def create_joints
    Graph.instance.edges.values.each do |edge|
      edge.create_ball_joints(@world)
    end
  end
end