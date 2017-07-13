require 'src/simulation/simulation'

class BallJointSimulation < Simulation

  attr_accessor :edge

  def initialize
    super
    @edge = nil
  end

  def setup
    @world = MSPhysics::World.new
    @ground_body = add_ground
    # @world.set_gravity(0, 0, 0)

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
    actuators = Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
    @pistons = actuators.map(&:thingy).map { |thingy| [thingy.id, thingy.piston] }.to_h
    piston_dialog unless @pistons.empty?
    
    # @piston = @edge.thingy.piston
    # @piston.controller = Random.rand(0.8) - 0.4
  end

  def add_ground
    group = Sketchup.active_model.entities.add_group()
    x = y = 10_000
    z = -1
    pts = []
    pts[0] = [-x, -y, z]
    pts[1] = [x, -y, z]
    pts[2] = [x, y, z]
    pts[3] = [-x, y, z]
    face = group.entities.add_face(pts)
    face.pushpull(-1)
    face.visible = false
    body = MSPhysics::Body.new(@world, group, :convex_hull)
    body.static = true
    body
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
    # @world.bodies.each do |body|
    #   puts body.get_force
    #   puts body.get_velocity
    # end
    super(view)
  end
end