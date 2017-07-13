require 'src/simulation/simulation'

class BallJointSimulation < Simulation

  attr_accessor :edge

  def initialize
    super
    @edge = nil
  end

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

    @piston = @edge.thingy.piston
    @piston.controller = Random.rand(0.8) - 0.4
  end

  def move_piston
    puts @piston.controller
    puts @piston.cur_position
    return unless @piston.controller.nil? && @piston.cur_position == @piston.controller
    @piston.controller = Random.rand(0.8) - 0.4
  end

  def random_force
    Geom::Vector3d.new(Array.new(3) { Random.rand(10.0) })
  end

  def apply_random_forces
    Graph.instance.nodes.each_value do |node|
      node.thingy.body.add_force(random_force)
    end
  end

  def nextFrame(view)
    # move_piston
    super(view)
  end
end