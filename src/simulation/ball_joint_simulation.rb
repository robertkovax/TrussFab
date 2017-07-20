require 'src/simulation/simulation'

class BallJointSimulation < Simulation

  attr_accessor :edge

  def initialize
    super
    @edge = nil
  end

  def setup
    @world = MSPhysics::World.new
    # @world.solver_model = 0
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
    @actuators = Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
    puts(@actuators)
    @pistons = @actuators.map(&:thingy).map { |thingy| [thingy.id, thingy.piston] }.to_h
    # piston_dialog unless @pistons.empty?

    @piston_expansion = 0
    @max_expansion = 0.15
    @schedule_a = ['a', [ 1,  1, -1, -1, ]]
    @schedule_b = ['b', [ 1, -1, -1,  1, ]]

    @schedule_c = ['c', [-1, -1,  1,  1, ]]
    @schedule_d = ['d', [-1,  1,  1, -1, ]]
    # @schedule_a = ['a', [ 1,  1,  1, -1, -1, -1, -1]]
    # @schedule_b = ['b', [ 1,  1, -1, -1, -1,  1,  1]]

    # @schedule_c = ['c', [-1, -1, -1, -1,  1,  1,  1]]
    # @schedule_d = ['d', [-1,  1,  1,  1,  1, -1, -1]]
    @piston_step = 100
    # @piston = @edge.thingy.piston0
    # @piston.controller = Random.rand(0.8) - 0.4
  end

  def schedule_pistons()
    unless @actuators.nil? 
      size = @schedule_a[1].size
      current_idx = (@piston_expansion / @piston_step) % size 
      next_idx = (@piston_expansion / @piston_step + 1) % size
      step_progress = ((@piston_expansion % @piston_step )/ (1.0 * @piston_step))
      [@schedule_a, @schedule_b, @schedule_c, @schedule_d].each do |schedule|
        dist = schedule[1][current_idx] - schedule[1][next_idx]
        absoulute = schedule[1][current_idx] - dist * step_progress
        # puts("#{current_idx}>>>>> a: #{a}, b: #{b}")
        schedule[0] = absoulute * @max_expansion
      end
      @actuators.each do |actuator|
        case actuator.thingy.piston_group
          when 'a' then actuator.thingy.piston.controller = @schedule_a[0]
          when 'b' then actuator.thingy.piston.controller = @schedule_b[0]
          when 'c' then actuator.thingy.piston.controller = @schedule_c[0]
          when 'd' then actuator.thingy.piston.controller = @schedule_d[0]
        end
      end
      @piston_expansion = @piston_expansion + 1
    end
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
    face.pushpull(-10)
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
    Sketchup.active_model.start_operation('schedule', true)
    schedule_pistons
    view.invalidate
    super(view)
    Sketchup.active_model.commit_operation
  end
end