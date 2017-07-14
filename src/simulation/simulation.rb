require 'lib/MSPhysics/main.rb'

class Simulation

  # masses in kg
  ELONGATION_MASS = 0.1
  LINK_MASS = 0.5
  PISTON_MASS = 0.7
  HUB_MASS = 0.2
  POD_MASS = 0.1

  DEFAULT_STIFFNESS = 1.0
  DEFAULT_FRICTION = 1.0
  DEFAULT_BREAKING_FORCE = 1_000_000

  # velocity in change of length in m/s
  PISTON_RATE = 0.2

  MSPHYSICS_TIME_STEP = 1.0 / 100

  class << self
    def body_for(world, *thingies)
      entities = thingies.flat_map(&:all_entities)
      group = Sketchup.active_model.entities.add_group(entities)
      MSPhysics::Body.new(world, group, :convex_hull)
    end

    def joint_between(world, klass, parent_body, child_body, matrix, group = nil)
      joint = klass.new(world, parent_body, matrix, group)
      joint.stiffness = DEFAULT_STIFFNESS
      joint.breaking_force = DEFAULT_BREAKING_FORCE
      joint.friction = DEFAULT_FRICTION if klass == MSPhysics::Hinge
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
    @reset_positions_on_end = true
    @saved_transformations = {}
    @stopped = false
  end

  #
  # Getter and Setter
  #

  def reset_positions_on_end?
    @reset_positions_on_end
  end

  def reset_positions_on_end=(value)
    @reset_positions_on_end = value
  end

  #
  # Setup of the world
  #

  def save_transformations
    MSPhysics::Body.all_bodies.each do |body|
      @saved_transformations[body] = body.get_matrix
    end
  end

  def setup
    @world = MSPhysics::World.new
    @world.set_gravity(0, 0, 0)
    @world.solver_model = 0

    # create bodies for nodes and edges
    Graph.instance.nodes_and_edges.each do |obj|
      obj.thingy.create_body(@world)
    end

    # save transformation of current bodies for resetting
    save_transformations

    # create joints for each edge
    Graph.instance.edges.values.each do |edge|
      edge.create_joints(@world)
    end

    # get all pistons from actuator edges
    actuators = Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
    @pistons = actuators.map(&:thingy).map { |thingy| [thingy.id, thingy.piston] }.to_h
    piston_dialog unless @pistons.empty?
  end

  def add_ground
    group = Sketchup.active_model.entities.add_group
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
    body = create_body(group)
    body.static = true
    body.collidable = true
    body
  end

  def piston_dialog
    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__), '../ui/html/piston_slider.erb'))
    template = ERB.new(file_content)
    @dialog.set_html(template.result(binding))
    @dialog.show
    @dialog.add_action_callback('change_piston') do |_context, id, value|
      value = value.to_f
      id = id.to_i
      @pistons[id].controller = value
    end
  end

  def hide_triangle_surfaces
    Graph.instance.surfaces.each do |_, surface|
      surface.thingy.entity.hidden = true unless surface.thingy.entity.deleted?
    end
  end

  def show_triangle_surfaces
    Graph.instance.surfaces.each do |_, surface|
      surface.thingy.entity.hidden = false unless surface.thingy.entity.deleted?
    end
  end

  #
  # Animation methods
  #

  def start
    hide_triangle_surfaces
    @running = true
    @last_frame_time = Time.now
  end

  def halt
    @running = false
  end

  def stop
    return if @stopped
    @stopped = true
    halt
    reset_positions if reset_positions_on_end?
    show_triangle_surfaces
    @world.destroy_all_bodies
    @world = nil
  end

  def reset_positions
    @saved_transformations.each do |body, transformation|
      body.group.move!(transformation) if body.group.valid?
    end
    @saved_transformations.clear
  end

  def update_world_by(time_step)
    @world.update(time_step)
    # (time_step.to_f / MSPHYSICS_TIME_STEP).to_i.times do
    #   @world.update(MSPHYSICS_TIME_STEP)
    # end
  end

  def update_world
    now = Time.now
    @delta = now - @last_frame_time
    @last_frame_time = now
    update_world_by(@delta)
  end

  def update_entities
    MSPhysics::Body.all_bodies.each do |body|
      body.group.move!(body.get_matrix) if body.matrix_changed?
    end
  end

  def nextFrame(view)
    return @running unless @running
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
    MSPhysics::Body.all_bodies.each do |body|
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

