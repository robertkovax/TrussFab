require 'lib/MSPhysics/main.rb'
require 'src/utility/scheduler'
require 'erb'

class Simulation

  attr_accessor :pistons, :static_schedule_state

  # masses in kg
  ELONGATION_MASS = 0.1
  LINK_MASS = 0.5
  PISTON_MASS = 1
  HUB_MASS = 0.1
  POD_MASS = 0.1

  DEFAULT_STIFFNESS = 0.999
  DEFAULT_FRICTION = 1.0
  DEFAULT_BREAKING_FORCE = 1_000_000

  # velocity in change of length in m/s
  PISTON_RATE = 0.4

  MSPHYSICS_TIME_STEP = 1.0 / 200
  MSPHYSICS_N_STEPS = ((1.0 / 60) / MSPHYSICS_TIME_STEP).to_i

  DEFAULT_SOLVER_MODEL = 2

  COLLISION_TYPE_TO_COLLISION_ID = {
    null: 0,
    box: 1,
    sphere: 2,
    cone: 3,
    cylinder: 4,
    chamfer_cylinder: 5,
    capsule: 6,
    convex_hull: 7,
    compound: 8,
    static_mesh: 9
  }.freeze

  class << self
    def create_body(world, entity, collision_type: :box, dynamic: true)
      # initialize(world, entity, shape_id, offset_tra, type_id)
      # collision_id: 7 - convex hull, 2 - sphere
      # offset_tra nil: no offset transformation
      # type_id Body type: 0 -> dynamic; 1 -> kinematic.
      collision_id = COLLISION_TYPE_TO_COLLISION_ID[collision_type]
      type_id = dynamic ? 0 : 1
      MSPhysics::Body.new(world, entity, collision_id, nil, type_id)
    end

    def body_for(world, dynamic, collision_type, *thingies)
      entities = thingies.flat_map(&:all_entities)
      group = Sketchup.active_model.entities.add_group(entities)
      create_body(world, group, collision_type: collision_type, dynamic: dynamic)
    end

    def joint_between(world, klass, parent_body, child_body, matrix, solver_model = DEFAULT_SOLVER_MODEL, group = nil)
      joint = klass.new(world, parent_body, matrix, group)
      joint.stiffness = DEFAULT_STIFFNESS
      joint.breaking_force = DEFAULT_BREAKING_FORCE
      if joint.respond_to? :friction=
        joint.friction = DEFAULT_FRICTION
      end
      joint.solver_model = solver_model
      joint.connect(child_body)
      joint
    end

    def create_piston(world, parent_body, child_body, matrix)
      piston = joint_between(world, MSPhysics::Piston, parent_body, child_body, matrix)
      piston.rate = PISTON_RATE
      piston
    end
  end

  def initialize
    @world = nil
    @last_frame_time = nil
    @last_frame = 0
    @last_time = 0
    @running = false
    @frame = 0
    @static_schedule_state = nil
    @reset_positions_on_end = true
    @saved_transformations = {}
    @stopped = false
    @paused = false
    @triangles_hidden = false
    @ground_group = nil
    @pistons = {}
  end

  #
  # Getter and Setter
  #

  def reset_positions_on_end?
    @reset_positions_on_end
  end

  def reset_positions_on_end=(state)
    @reset_positions_on_end = state
  end

  def paused?
    @paused
  end

  #
  # Setup and resetting of the world
  #

  def save_transformations
    MSPhysics::Body.all_bodies.each do |body|
      @saved_transformations[body] = body.get_matrix
    end
  end

  def enable_gravity
    return if @world.nil?
    @world.set_gravity([0.0, 0.0, -9.800000190734863])
  end

  def disable_gravity
    return if @world.nil?
    @world.set_gravity([0.0, 0.0, 0.0])
  end

  def setup
    @world = MSPhysics::World.new

    # create bodies for nodes and edges
    Graph.instance.nodes_and_edges.each do |obj|
      obj.thingy.create_body(@world)
    end

    # save transformation of current bodies for resetting
    save_transformations

    # create joints for each edge
    create_joints

    # get all pistons from actuator edges
    actuators = Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
    @pistons = actuators.map(&:thingy).map { |thingy| [thingy.id, thingy.piston] }.to_h
  end

  def create_joints
    Graph.instance.edges.values.each do |edge|
      edge.create_joints(@world)
    end
  end

  def reset_bodies_and_joints
    Graph.instance.nodes_and_edges.each do |obj|
      obj.thingy.reset_physics
    end
  end

  def destroy_world
    return if @world.nil?
    @world.destroy_all_bodies
    reset_bodies_and_joints
    @ground_group.erase! unless @ground_group.nil?
    @world.destroy
    @world = nil
  end

  def add_ground
    @ground_group = Sketchup.active_model.entities.add_group
    x = y = 10_000
    z = -10
    pts = []
    pts[0] = [-x, -y, z]
    pts[1] = [x, -y, z]
    pts[2] = [x, y, z]
    pts[3] = [-x, y, z]
    face = @ground_group.entities.add_face(pts)
    face.pushpull(-100)
    # face.visible = false
    body = Simulation.create_body(@world, @ground_group)
    body.static = true
    body.collidable = true
    body
  end

  def hide_triangle_surfaces
    Graph.instance.surfaces.each do |_, surface|
      surface.thingy.entity.hidden = true unless surface.thingy.entity.deleted?
    end
    @triangles_hidden = true
  end

  def show_triangle_surfaces
    Graph.instance.surfaces.each do |_, surface|
      surface.thingy.entity.hidden = false unless surface.thingy.entity.deleted?
    end
    @triangles_hidden = false
  end

  #
  # Animation methods
  #

  def start
    hide_triangle_surfaces
    @running = true
    @paused = false
    @last_frame_time = Time.now
  end

  def pause
    @paused = true
  end

  def resume
    @paused = false
  end

  def stop
    return if @stopped
    @stopped = true
    @paused = false
    pause
    reset_positions if reset_positions_on_end?
    show_triangle_surfaces if @triangles_hidden
    destroy_world
  end

  def reset_positions
    @saved_transformations.each do |body, transformation|
      body.group.move!(transformation) if body.group.valid?
    end
    @saved_transformations.clear
  end

  def update_world_by(time_step)
    steps = (time_step.to_f / MSPHYSICS_TIME_STEP).to_i
    steps.times do
      @world.update(MSPHYSICS_TIME_STEP)
    end
  end

  def update_world
    now = Time.now
    @delta = now - @last_frame_time
    @last_frame_time = now
    MSPHYSICS_N_STEPS.times do
      @world.update(MSPHYSICS_TIME_STEP)
    end
  end

  def update_entities
    @world.bodies.each do |body|
      if body.matrix_changed? && body.group.valid?
        body.group.move!(body.get_matrix)
      end
    end
  end

  def nextFrame(view)
    return false unless @running
    return @running if @paused
    Scheduler.instance.schedule_groups(@frame, @static_schedule_state)
    update_world
    update_entities
    @frame += 1
    if @frame % 20 == 0
      set_status_text
    end

    view.show_frame
    @running
  end

  def set_status_text
    delta_frame = @frame - @last_frame
    now = Time.now.to_f
    delta_time = now - @last_time
    @fps = (delta_frame / delta_time).to_i
    Sketchup.status_text = "Frame: #{@frame}   Time: #{sprintf("%.2f", @world.time)} s   FPS: #{@fps}"
    @last_frame = @frame
    @last_time = now
  end

  def show_forces(view)
    @world.bodies.each do |body|
      show_force(body, view)
    end
  end

  def show_force(body, view)
    force = Geom::Vector3d.new(*body.get_force)
    return if force.length.zero?
    position = body.get_position(1)
    force.length = force.length * 100
    second_position = position.offset(force)
    view.drawing_color = 'black'
    view.draw_lines(position, second_position)
  end
end

