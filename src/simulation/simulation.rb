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
  DEFAULT_STIFFNESS = 0.0
  DEFAULT_FRICTION = 0.0
  DEFAULT_BREAKING_FORCE = 1_000_000

  # velocity in change of length in m/s
  PISTON_RATE = 1.0

  MSPHYSICS_TIME_STEP = 1.0 / 200
  MSPHYSICS_N_STEPS = ((1.0 / 60) / MSPHYSICS_TIME_STEP).to_i


  TENSION_COLORS = [
    Sketchup::Color.new(0,255,255),
    Sketchup::Color.new(0,0,255),
    Sketchup::Color.new(0,255,255),
    Sketchup::Color.new(0,255,0),
    Sketchup::Color.new(255,255,0),
    Sketchup::Color.new(255,0,0)
  ]
  TENSION_RANGE = 20.0
  TENSION_RANGE_INVH = 1.0 / (TENSION_RANGE * 2.0)

  class << self

    def create_body(world, entity, collision_type: :box)
      tr = entity.transformation
      df = AMS::Group.get_definition(entity)
      bb = df.bounds
      cn = bb.center
      ms = AMS::Geometry.get_matrix_scale(tr)
      bd = Geom::Vector3d.new(bb.width, bb.height, bb.depth)
      ss = AMS::Geometry.product_vectors(bd, ms)
      if AMS::Geometry.is_matrix_flipped?(tr)
        cn.x = -cn.x
      end
      om = Geom::Transformation.new(AMS::Geometry.product_vectors(cn, ms))
      col = case collision_type
        when :box
          world.create_box_collision(ss.x, ss.y, ss.z, om)
        when :sphere
          world.create_scaled_sphere_collision(ss.x, ss.y, ss.z, om)
      else
        raise TypeError, "Invalid collision type '#{collision_type}'"
      end
      body = MSPhysics::Body.new(world, col, tr, entity)
      world.destroy_collision(col)
      body
    end

  end

  def initialize
    # general
    @chart = nil
    @ground_group = nil
    @root_dir = File.join(__dir__, '..')
    @world = nil

    # collections
    @edges = []
    @force_labels = {}
    @moving_pistons = []
    @saved_transformations = {}
    @sensors = []
    @last_sensor_speed = {}
    @pistons = {}
    @bottle_dat = {}

    # time keeping
    @frame = 0
    @last_frame = 0
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
    @color_converter = ColorConverter.new(@breaking_force)
    @highest_force_mode = false
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
    Graph.instance.nodes.each_value do |obj|
      e = obj.thingy.entity
      @saved_transformations[e] = e.transformation
      obj.thingy.sub_thingies.each { |sub_obj|
        e2 = sub_obj.entity
        @saved_transformations[e2] = e2.transformation
      }
    end
    Graph.instance.edges.each_value do |obj|
      obj.thingy.sub_thingies.each { |sub_obj|
        e2 = sub_obj.entity
        @saved_transformations[e2] = e2.transformation
      }
    end
  end

  def enable_gravity
    return if @world.nil?
    @world.set_gravity(0.0, 0.0, -9.800000190734863)
  end

  def disable_gravity
    return if @world.nil?
    @world.set_gravity(0.0, 0.0, 0.0)
  end

  # Called when activates
  def setup
    @world = MSPhysics::World.new
    @world.update_timestep = MSPHYSICS_TIME_STEP

    # This removes all deleted nodes and edges from storage
    Graph.instance.cleanup

    # create bodies for nodes (all edges will not have physics components to them)
    Graph.instance.nodes.each_value do |obj|
      obj.thingy.create_body(@world)
    end

    # save transformation of current bodies for resetting
    save_transformations

    # create joints for each edge
    create_joints

    # Setup stuff
    model = Sketchup.active_model
    model.start_operation('Starting Simulation', true)
    begin
      hide_triangle_surfaces
      hide_force_arrows
      add_ground
      assign_unique_materials
    rescue Exception => err
      model.abort_operation
      raise err
    end
    model.commit_operation

    start
  end

  # Called when deactivates
  def reset(view)
    view.animation = nil

    model = view.model

    destroy_world

    model.start_operation('Reseting Simulation', true)
    begin
      @ground_group.erase! if @ground_group && @ground_group.valid?
      reset_positions if reset_positions_on_end?
      reset_materials
      show_triangle_surfaces if @triangles_hidden
      reset_force_color
      reset_force_labels
    rescue Exception => err
      model.abort_operation
      raise err
    end
    model.commit_operation

    @ground_group = nil
    @moving_pistons.clear

    view.invalidate
  end

  def create_joints
    Graph.instance.edges.each_value do |edge|
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
    reset_bodies_and_joints
    @world.destroy
    @world = nil
  end

  # Note: this must be wrapped in operation
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

  # Note: this must be wrapped in operation
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

  # Note: this must be wrapped in operation
  def hide_triangle_surfaces
    Graph.instance.surfaces.each do |_, surface|
      surface.thingy.entity.hidden = true unless surface.thingy.entity.deleted?
    end
    @triangles_hidden = true
  end

  # Note: this must be wrapped in operation
  def hide_force_arrows
    Graph.instance.nodes.each do |id, node|
      node.thingy.arrow.erase! unless node.thingy.arrow.nil?
      node.thingy.arrow = nil
    end
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

  #
  # Piston Related Methods
  #

  def get_all_pistons
    # get all pistons from actuator edges
    @pistons.clear
    Graph.instance.edges.each { |id, edge|
      @pistons[id] = edge.thingy if edge.thingy.is_a?(ActuatorLink)
    }
  end

  def piston_dialog
    get_all_pistons
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
      @pistons[id].joint.controller = (value - 0.5) * (piston.max - piston.min)
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

    @dialog.add_action_callback('change_highest_force_mode') do |_context, param|
      @highest_force_mode = param
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

  def schedule_piston_for_testing(edge)
    @moving_pistons.push({:id=>edge.id.to_i, :expanding=>true, :speed=>0.4})
  end

  def reset_tested_pistons
    @moving_pistons.clear
  end

  def get_closest_node_to_point(point)
    closest_distance = Float::INFINITY
    Graph.instance.nodes.values.each do |node|
      if node.thingy.body.get_position.distance(point) < closest_distance
        closest_node = node
        closest_distance = node.thingy.body.get_position.distance(point)
      end
    end
    closest_distance
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

  def test_piston_for_hub_movement(node, point)
    test_pistons
    update_entities
    node.thingy.body.get_position.distance(point)
  end

  # this automatically uses the test function on all the pistons in the scene
  # => and tries to find the piston whose movement brings a given node closest
  # => to a given point
  def test_pistons_for(seconds, node, point)
    closest_distance = Float::INFINITY
    get_all_pistons
    steps = (seconds.to_f / MSPHYSICS_TIME_STEP).to_i
    steps.times do
      @world.update(MSPHYSICS_TIME_STEP)
      distance = test_piston_for_hub_movement(node, point)
      if distance < closest_distance
        closest_distance = distance
      end
    end
    reset_tested_pistons
    closest_distance
  end

  def print_piston_stats
    @moving_pistons.each do |hash|
      p "PISTON #{hash[:id]}"
      p "Speed: #{hash[:speed]}"
    end
  end

  #
  # Animation methods
  #

  def start
    @running = true
    @paused = false
    @stopped = false
  end

  def halt
    @running = false
  end

  def stop
    return if @stopped
    @stopped = true
    halt
  end

  def reset_positions
    @saved_transformations.each do |entity, transformation|
      entity.move!(transformation) if entity.valid?
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
    MSPHYSICS_N_STEPS.times do
      @world.advance
    end
  end

  def update_entities
    @world.update_group_transformations
    Graph.instance.edges.each do |id, edge|
      link = edge.thingy
      link.update_link_transformations if link.is_a?(Link)
    end
  end

  def nextFrame(view)
    model = view.model
    return @running unless (@running && !@paused)

    update_world

    model.start_operation('NextFrame', true)

    update_entities
    visualize_tensions

    model.commit_operation

    @frame += 1

    update_status_text

    view.show_frame
    @running
  end

  def update_status_text
    delta_frame = @frame - @last_frame
    now = Time.now.to_f
    delta_time = now - @last_time
    @fps = (delta_frame / delta_time).to_i
    Sketchup.set_status_text("Frame: #{@frame}   Time: #{sprintf("%.2f", @world.elapsed_time)} s   FPS: #{@fps}   Threads: #{@world.cur_threads_count}", SB_PROMPT)
    @last_frame = @frame
    @last_time = now
  end

  #
  # Sensor Related Methods
  #

  def open_sensor_dialog
    collect_sensors
    return if @sensors.empty?
    @sensor_dialog = UI::HtmlDialog.new(Configuration::HTML_DIALOG)
    file_content = File.read(File.join(File.dirname(__FILE__), '../ui/erb/sensor_overview.erb'))
    template = ERB.new(file_content)
    @sensor_dialog.set_html(template.result(binding))
    @sensor_dialog.set_size(300, Configuration::UI_HEIGHT)
    @sensor_dialog.show
  end

  def close_sensor_dialog
    unless @sensor_dialog.nil?
      if @sensor_dialog.visible?
        @sensor_dialog.close
      end
    end
  end

  def collect_sensors
    Graph.instance.nodes.values.each do |node|
      if node.thingy.is_sensor?
        @sensors.push(node.thingy)
      end
    end
  end

  def send_sensor_speed_to_dialog
    return if @sensor_dialog.nil?
    @sensors.each do |sensor|
      @sensor_dialog.execute_script("updateSpeed('#{sensor.id}', '#{sensor.body.get_velocity.length.round(2)}')")
      @last_sensor_speed[sensor.id] = [sensor.body.get_velocity.length, Time.now]
    end
  end

  def get_sensor_acceleration(sensor)
    return 0 if @last_sensor_speed[sensor.id].nil?
    last_speed = @last_sensor_speed[sensor.id][0]
    last_time = @last_sensor_speed[sensor.id][1]
    curr_speed = sensor.body.get_velocity.length
    curr_acceleration = (curr_speed - last_speed)/(Time.now - last_time)
    curr_acceleration
  end

  def send_sensor_acceleration_to_dialog
    return if @sensor_dialog.nil?
    @sensors.each do |sensor|
      @sensor_dialog.execute_script("updateAcceleration('#{sensor.id}', '#{get_sensor_acceleration(sensor).round(2)}')")
    end
  end

  #
  # Force Related Methods
  #

  # This is called when simulation starts, and assigns unique materials to bottles
  def assign_unique_materials
    mats = Sketchup.active_model.materials
    # First, store current mats of bottles and sub-bottles
    Graph.instance.edges.each_value { |edge|
      link = edge.thingy
      # Make sure we're dealing with a bottle link and not an actuator
      next if link.is_a?(ActuatorLink)
      # Get the bottle of the link
      bottle = link.sub_thingies[1].entity
      bottle_ents = AMS::Group.get_entities(bottle)
      sub_mats = {}
      bottle_ents.each { |e|
        if e.is_a?(::Sketchup::Group) || e.is_a?(::Sketchup::ComponentInstance)
          sub_mats[e] = e.material
        end
      }
      @bottle_dat[link] = [bottle, bottle.material, sub_mats, nil]
    }
    # Now, create new materials
    @bottle_dat.each { |link, dat|
      umat = mats.add('TFX')
      umat.color = dat[1].color if dat[1]
      dat[3] = umat
      dat[0].material = umat
      dat[2].each { |e, m| e.material = nil }
    }
  end

  # This is called when simulation ends and restores original materials, deleting the created ones.
  def reset_materials
    mats = Sketchup.active_model.materials
    @bottle_dat.each { |link, dat|
      if dat[0].valid?
        dat[0].material = (dat[1] && dat[1].valid?) ? dat[1] : nil
        dat[2].each { |e, m|
          next unless e.valid?
          e.material = (m && m.valid?) ? m : nil
        }
      end
      # Note this works in SU2014+, use material.purge_unused at end for compatibility with prior SU versions
      mats.remove(dat[3]) if dat[3] && dat[3].valid?
    }
    @bottle_dat.clear
  end

  # The way this works is that before simulation starts,
  #   all bottles are assigned their own materials
  # During simulation, we update the colors of the materials,
  #   thus new materials are not created.
  def visualize_tensions
    @bottle_dat.each { |link, dat|
      mat = dat[3]
      if mat && mat.valid?
        tension = link.joint.get_linear_tension.length.to_f
        r = (TENSION_RANGE + tension) * TENSION_RANGE_INVH
        mat.color = AMS::Geometry.blend_colors(TENSION_COLORS, r)
      end
    }
  end

  # visualizes force for every edge in the graph
  def show_forces(view)
    model = view.model
    model.start_operation('Change Materials', true)
    Graph.instance.edges.each_value do |edge|
      show_force(edge.thingy, view)
    end
    model.commit_operation
  end

  # only visualizes the bottles with the highest tension and contraction force
  def show_highest_forces(view)
    Sketchup.active_model.start_operation('Change Materials (Highest Only)', true)
    # tupel of link and force
    lowest_force_tuple = [nil, Float::INFINITY]
    highest_force_tuple = [nil, -Float::INFINITY]
    Graph.instance.edges.values.each do |edge|
      force = get_force_from_link(edge.thingy)[0]
      if force < lowest_force_tuple[1]
        lowest_force_tuple = [edge, force]
      elsif force > highest_force_tuple[1]
        highest_force_tuple = [edge, force]
      end
    end
    whiten_all_bottles
    visualize_highest_force(lowest_force_tuple[0].thingy, lowest_force_tuple[1])
    visualize_highest_force(highest_force_tuple[0].thingy, highest_force_tuple[1])
    Sketchup.active_model.commit_operation
  end

  # returns the force and position for a link
  # note: this also visualizes the force if the link has cylinders (i.e. a piston)
  # => we might want to think about returning an array to pass multiple value pairs
  def get_force_from_link(link)
    # Links no longer have bodies
    # Instead, you can obtain force from their linked nodes and compute the tension
    pt1 = link.first_node.thingy.entity.bounds.center
    pt2 = link.second_node.thingy.entity.bounds.center

    position = Geom.linear_combination(0.5, pt1, 0.5, pt2)
    tension = link.joint.get_linear_tension.length
    [tension, position]
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

  # colors a given link based on a given force
  # => in order to properly identify bottles with highest force, the saturation
  # => for the highest force mode is at least @breaking_force/2
    def visualize_highest_force(link, force)
      if force < (@breaking_force/2.0)
        force = sign(force) * @breaking_force/2.0
      end
      visualize_force(link, force)
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
      if @force_labels[link].nil?
        model = Sketchup.active_model
        force_label = model.entities.add_text("--------------- #{force.round(1)}", position)

        force_label.layer = model.layers[Configuration::FORCE_LABEL_VIEW]
        @force_labels[link] = force_label
      else
        @force_labels[link].text = "--------------- #{force.round(1)}"
        @force_labels[link].point = position
      end
    end

    # resets the color of all edges to its default value
    def reset_force_color
      Graph.instance.edges.values.each do |edge|
        edge.thingy.un_highlight
      end
    end

    def whiten_all_bottles
      Graph.instance.edges.values.each do |edge|
        edge.thingy.highlight
      end
    end

    # removes force labels
    def reset_force_labels
      @force_labels.each { |link, label| label.text = "" }
    end

    #
    # Helper functions
    #

    def sign(n)
      n == 0 ? 1 : n.abs / n
    end
  end
