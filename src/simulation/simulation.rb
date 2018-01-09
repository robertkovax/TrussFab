require 'lib/MSPhysics/main.rb'

require 'src/utility/force_to_color_converter.rb'
require 'src/ui/force_chart.rb'
require 'erb'

class Simulation

  # masses in kg
  ELONGATION_MASS = 0.0
  LINK_MASS = 0.2
  PISTON_MASS = 0.1
  HUB_MASS = 0.1
  POD_MASS = 0.1

  # if this is 1.0, for some reason, there is no "damping" in movement, but
  # all movement is accumulated until the whole structure breaks
  # 0.9993 was the "stiffest" value that didn't break the object
  DEFAULT_STIFFNESS = 0.9993
  DEFAULT_FRICTION = 0.0
  DEFAULT_BREAKING_FORCE = 1_000_000

  # velocity in change of length in m/s
  PISTON_RATE = 1.0

  MSPHYSICS_TIME_STEP = 1.0 / 200
  MSPHYSICS_N_STEPS = ((1.0 / 60) / MSPHYSICS_TIME_STEP).to_i

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

    def joint_between(world, klass, parent_body, child_body, matrix, solver_model = 2, group = nil)
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

    def create_piston(world, parent_body, child_body, matrix, damping, rate, power, min, max)
      piston = joint_between(world, MSPhysics::Piston, parent_body, child_body, matrix)
      piston.reduction_ratio = damping
      piston.rate = rate
      piston.power = power
      piston.min = min
      piston.max = max
      piston
    end
  end

  def initialize
    # general
    @chart = nil
    @color_converter = ColorConverter.new(@breaking_force)
    @ground_group = nil
    @root_dir = File.join(__dir__, '..')
    @world = nil

    # collections
    @edges = []
    @force_labels = {}
    @moving_pistons = []
    @saved_transformations = {}
    @sensors = []

    # time keeping
    @frame = 0
    @last_frame = 0
    @last_frame_time = nil
    @last_time = 0
    @piston_time = 0
    @piston_world_time = 0

    # simulation state
    @paused = false
    @reset_positions_on_end = true
    @running = false
    @stopped = false
    @triangles_hidden = false

    # physics variables
    @breaking_force = 1500
    @max_speed = 0
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
    z = -2
    pts = []
    pts[0] = [-x, -y, z]
    pts[1] = [x, -y, z]
    pts[2] = [x, y, z]
    pts[3] = [-x, y, z]
    face = @ground_group.entities.add_face(pts)
    face.material = Sketchup::Color.new(240, 240, 240)
    face.material.alpha = 0.2
    face.back_material = nil
    face.pushpull(-1)
    face.visible = false
    body = Simulation.create_body(@world, @ground_group)
    body.static = true
    body.collidable = true
    body
  end

  def chart_dialog
    return if @pistons.empty?
    @chart = ForceChart.new()
    @chart.open_dialog
  end

  def close_chart
    return if @chart.nil?
    @chart.close
  end

  def piston_dialog
    # get all pistons from actuator edges
    actuators = Graph.instance.edges.values.select { |edge| edge.link_type == 'actuator' }
    @pistons = actuators.map(&:thingy).map { |thingy| [thingy.id, thingy.piston] }.to_h
    return if @pistons.empty?

    @dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__), '../ui/html/piston_slider.erb'))
    template = ERB.new(file_content)
    @dialog.set_html(template.result(binding))
    @dialog.set_size(300, Configuration::UI_HEIGHT)
    @dialog.show

    # Callbacks
    @dialog.add_action_callback('change_piston') do |_context, id, value|
      value = value.to_f
      id = id.to_i
      piston = @pistons[id]
      @pistons[id].controller = piston.min + value * (piston.max - piston.min)
    end

    @dialog.add_action_callback('test_piston') do |_context, id|
      @moving_pistons.push({:id=>id.to_i, :expanding=>true, :speed=>0.2})
    end

    @dialog.add_action_callback('set_breaking_force') do |_context, param|
      value = param.to_f
      Sketchup.active_model.start_operation("Set Simulation Breaking Force", true)
      @breaking_force = value
      @color_converter.update_max_force(@breaking_force)
      Sketchup.active_model.commit_operation
    end

    @dialog.add_action_callback('set_max_speed') do |_context, param|
      value = param.to_f
      Sketchup.active_model.start_operation("Set Simulation Breaking Force", true)
      @max_speed = value
      Sketchup.active_model.commit_operation
    end

    @dialog.add_action_callback('play_pause_simulation') do |_context|
      if @paused
        reset_force_labels
        start
      else
        update_force_labels
        @paused = true
      end
    end
  end

  def close_piston_dialog
    #close old window
    unless @dialog.nil?
      if @dialog.visible?
        @dialog.close
      end
    end
  end

  def test_pistons
    return if @moving_pistons.nil?
    @moving_pistons.map! { |hash|
      piston = @pistons[hash[:id]]

      piston.rate = hash[:speed]
      piston.controller = (hash[:expanding] ? piston.max : piston.min)
      if (piston.cur_position - piston.max).abs < 0.005 && hash[:expanding]
        #
        @piston_world_time = @world.time
        @piston_time = Time.now
        hash[:expanding] = false
      elsif (piston.cur_position - piston.min).abs < 0.005 && !hash[:expanding]
        # increase speed everytime the piston reaches its minimum value
        hash[:speed] += 0.05 unless (hash[:speed] >= @max_speed && @max_speed != 0)
        hash[:expanding] = true
        # add the piston frequency as a label in the chart (every value between
        # two frequencies has the same frequency)
        add_chart_label((1 / (@world.time - @piston_world_time).to_f).round(2))
      end
      hash
    }
  end

  def print_piston_stats
    @moving_pistons.each do |hash|
      p "PISTON #{hash[:id]}"
      p "Speed: #{hash[:speed]}"
    end
  end

  def show_triangle_surfaces
    Graph.instance.surfaces.each do |_, surface|
      unless surface.thingy.entity.deleted?
        surface.thingy.entity.hidden = false
        # workaround to properly reset surface color
        surface.un_highlight
      end
    end
    @triangles_hidden = false
  end

  def hide_triangle_surfaces
    Graph.instance.surfaces.each do |_, surface|
      surface.thingy.entity.hidden = true unless surface.thingy.entity.deleted?
    end
    @triangles_hidden = true
  end

  def hide_force_arrows
    Graph.instance.nodes.values.each do |node|
      node.thingy.arrow.erase! unless node.thingy.arrow.nil?
      node.thingy.arrow = nil
    end
  end

  #
  # Animation methods
  #

  def start
    hide_triangle_surfaces
    hide_force_arrows
    collect_sensors
    @running = true
    @paused = false
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
    show_triangle_surfaces if @triangles_hidden
    reset_force_color
    reset_force_labels
    close_piston_dialog
    close_chart
    @moving_pistons.clear
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
    return @running unless (@running && !@paused)
    update_world
    update_entities

    @frame += 1
    @total_force = 0
    if @frame % 20 == 0
      set_status_text
    end

    show_forces(view)
    if @frame % 5 == 0 # do this every 5 frames to increase fps
      send_force_to_chart
    end
    test_pistons

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

  #
  # Sensor Related Methods
  #

  def collect_sensors
    Graph.instance.nodes.values.each do |node|
      # if node.thingy.is_sensor?
      #   @sensors.push(node.thingy)
      # end
    end
  end

  def get_sensor_speed
    @sensors.each do |sensor|
      p "Test"#sensor.get_velocity
    end
  end

  #
  # Force Related Methods
  #

  # visualizes force for every edge in the graph
  def show_forces(view)
    Sketchup.active_model.start_operation('Change Materials', true)
    Graph.instance.edges.values.each do |edge|
      show_force(edge.thingy, view)
    end
    Sketchup.active_model.commit_operation
  end

  # returns the force and position for a link
  # note: this also visualizes the force if the link has cylinders (i.e. a piston)
  # => we might want to think about returning an array to pass multiple value pairs
  def get_force_from_link(link)
    lin_force = nil
    position = nil
    if !link.body.nil?
      lin_force, position = get_force_from_body(link, link.body)
    elsif (!link.first_cylinder_body.nil? && !link.second_cylinder_body.nil?)
      [link.first_cylinder_body, link.second_cylinder_body].each do |body|
        lin_force, position = get_force_from_body(link, body)
        visualize_force(link, lin_force)
        @total_force += lin_force.abs
      end
    else
      return
    end

    [lin_force, position]
  end

  # returns the joint tension force from an MSPhysics::Body
  def get_force_from_body(link, body)
    return if body.nil?
    body_orientation = body.get_matrix
    glob_up_vec = link.loc_up_vec.transform(body_orientation)

    f1 = link.first_joint.joint.get_tension1
    f2 = link.second_joint.joint.get_tension1
    lin_force = (f2 - f1).dot(glob_up_vec)
    position = body.get_position(1)
    [lin_force, position]
  end

  # sends @total_force to the force graph
  def send_force_to_chart
    return if @chart.nil?
    @chart.addData(' ', @total_force)
  end

  # sends @total_force to the force graph and adds a label
  def add_chart_label(label)
    return if @chart.nil?
    @chart.addData(label, @total_force)
  end

  # retrieves force for a link and visualizes the according edge
  # => if the force exceeds @breaking_force, this pauses the simulation and prints
  # => the force labels
  def show_force(link, view)
    lin_force, position = get_force_from_link(link)

    return if lin_force.nil?
    visualize_force(link, lin_force)

    if lin_force.abs > @breaking_force
      update_force_label(link, lin_force, position)
      print_piston_stats
      @paused = true
    end
    # \note(tim): this has a huge performance impact. We may have to think about
    # only showing the highest force or omit some values that are uninteresting
    # Commented out for now in order to keep the simulation running quickly.
    # update_force_label(link, lin_force, position)
  end

  # colors a given link based on a given force
  def visualize_force(link, force)
    color = @color_converter.get_color_for_force(force)
    link.change_color(color)
  end

  # adds a label with the force value for each edge in the graph
  def update_force_labels
    Sketchup.active_model.start_operation('Change Materials', true)
    Graph.instance.edges.values.each do |edge|
      lin_force, position = get_force_from_link(edge.thingy)
      update_force_label(edge.thingy, lin_force, position)
    end
    Sketchup.active_model.commit_operation
  end

  # adds a label with the force value for a single edge
  def update_force_label(link, force, position)
    if @force_labels[link.body].nil?
      model = Sketchup.active_model
      force_label = model.entities.add_text("--------------- #{force.round(1)}", position)

      force_label.layer = model.layers[Configuration::FORCE_LABEL_VIEW]
      @force_labels[link.body] = force_label
    else
      @force_labels[link.body].text = "--------------- #{force.round(1)}"
      @force_labels[link.body].point = position
    end
  end

  # resets the color of all edges to its default value
  def reset_force_color
    Graph.instance.edges.values.each do |edge|
      edge.thingy.un_highlight
    end
  end

  # removes force labels
  def reset_force_labels
    @force_labels.each {|body, label| label.text = "" }
  end
end
