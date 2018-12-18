require 'src/utility/geometry.rb'
require 'src/ui/dialogs/force_chart.rb'
require 'erb'

# Simulation, using MSPhysics
class Simulation
  attr_reader :pistons, :moving_pistons, :bottle_dat, :stiffness,
              :breaking_force
  attr_accessor :max_speed, :highest_force_mode, :peak_force_mode,
                :auto_piston_group, :reset_positions_on_end
                
  @timesteps = Configuration::WORLD_TIMESTEP_SPRING

  class << self
    def create_body(world, entity, collision_type = :box, points = [])
      tr = entity.transformation
      df = if entity.respond_to?(:definition)
             entity.definition
           else
             entity.entities.parent
           end
      bb = df.bounds
      cn = bb.center
      sx = X_AXIS.transform(tr).length.to_f
      sy = Y_AXIS.transform(tr).length.to_f
      sz = Z_AXIS.transform(tr).length.to_f
      sbx = sx * bb.width
      sby = sy * bb.height
      sbz = sz * bb.depth
      cn.x *= sx
      cn.y *= sy
      cn.z *= sz
      cn.x = -cn.x if tr.xaxis.cross(tr.yaxis).dot(tr.zaxis).to_f < 0.0
      om = Geom::Transformation.new(cn)
      col = case collision_type
            when :box
              world.create_box_collision(sbx, sby, sbz, om)
            when :sphere
              world.create_scaled_sphere_collision(sbx, sby, sbz, om)
            when :convex_hull
              world.create_convex_hull_collision(points, points.count, tr)
            else
              raise TypeError, "Invalid collision type '#{collision_type}'"
            end
      body = TrussFab::Body.new(world, col, tr, entity)
      world.destroy_collision(col)
      body
    end
  end

  def initialize(ui = nil)  
    # general
    @chart = nil
    @ground_group = nil
    @root_dir = File.join(__dir__, '..')
    @world = nil
	#setup
    @show_edges = true
    @show_profiles = true
    @ui = ui

    # collections
    @edges = []
    @force_labels = {}
    @moving_pistons = []
    @saved_transformations = {}
    @sensors = []
    @pistons = {}
    @generic_links = {}
    @bottle_dat = {}
    @charts = {}
    @auto_piston_group = []

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
    @breaking_force = Configuration::JOINT_BREAKING_FORCE
    @breaking_force_invh =
      @breaking_force > 1.0e-6 ? 0.5.fdiv(@breaking_force) : 0.0
    @stiffness = Configuration::JOINT_STIFFNESS

    @max_actuator_tensions = {}
    @max_link_tensions = {}
    @max_speed = 0
    @highest_force_mode = false
    @peak_force_mode = false

    @disable_coloring = false
    @display_values = false

    hinge_layer = Sketchup.active_model.layers.at(Configuration::HINGE_VIEW)
    hinge_layer.visible = false unless hinge_layer.nil?

    @sensor_output_csv = nil

    Graph.instance.edges.each_value do |edge|
      edge.link.connect_to_hub
    end
  end

  #
  # Getter and Setter
  #

  def breaking_force=(breaking_force)
    @breaking_force = breaking_force.to_f
    @breaking_force_invh =
      @breaking_force > 1.0e-6 ? 0.5.fdiv(@breaking_force) : 0.0
    Graph.instance.edges.each_value do |edge|
      link = edge.link
      if link.is_a?(Link) && link.joint && link.joint.valid?
        link.joint.breaking_force = @breaking_force
      end
    end
  end

  def stiffness=(stiffness)
    @stiffness = stiffness
    Graph.instance.edges.each_value do |edge|
      next if edge.link.joint.nil? || !edge.link.joint.valid?
      edge.link.joint.stiffness =
        edge.link.is_a?(ActuatorLink) ? 0.99 : stiffness
    end
  end

  def display_values
    @display_values
  end

  def display_values=(param)
    @display_values = param
    unless param
      reset_force_labels
    end
  end

  def timesteps=(value)
    @timesteps=value
	@world.update_timestep = @timesteps
  end			
  
  #
  # Setup and resetting of the world
  #

  def save_transformations
    Graph.instance.nodes.each_value do |obj|
      obj.original_position = obj.position
      e = obj.hub.entity
      @saved_transformations[e] = e.transformation
      obj.hub.children.each do |sub_obj|
        e2 = sub_obj.entity
        @saved_transformations[e2] = e2.transformation
      end
    end
    Graph.instance.edges.each_value do |obj|
      obj.link.children.each do |sub_obj|
        e2 = sub_obj.entity
        @saved_transformations[e2] = e2.transformation
      end
    end
    Graph.instance.triangles.each_value do |obj|
      if obj.cover
        e2 = obj.cover.entity
        @saved_transformations[e2] = e2.transformation
      end
    end
  end

  def enable_gravity
    return if @world.nil?
    @world.set_gravity(0.0, 0.0, Configuration::WORLD_GRAVITY)
  end

  def disable_gravity
    return if @world.nil?
    @world.set_gravity(0.0, 0.0, 0.0)
  end

  def disable_coloring
    @disable_coloring = true
  end

  # Called when activates
  def setup
    @world = TrussFab::World.new
    @world.solver_model = Configuration::WORLD_SOLVER_MODEL

    if TrussFab.store_sensor_output?
      @sensor_output_csv =
        File.new("#{File.expand_path('~')}/sensor_output.log", 'w')
    end

    # create bodies for node
    # (all edges will not have physics components to them)
    Graph.instance.nodes.each_value do |obj|
      obj.hub.create_body(@world)
    end

    # create bodies for covers
    #
    Graph.instance.triangles.each_value do |obj|
      if obj.cover
        obj.cover.create_body(@world)
      end
    end
    
    # save transformation of current bodies for resetting
    save_transformations

    # create joints for each edge
    create_joints
    collect_all_pistons
    collect_all_generic_links
    collect_piston_groups

    # Setup stuff
    model = Sketchup.active_model
    rendering_options = model.rendering_options
    begin
      hide_triangle_surfaces
      hide_pods_of_covers
      add_ground
      assign_unique_materials unless @disable_coloring
      @show_edges = rendering_options['EdgeDisplayMode']
      @show_profiles = rendering_options['DrawSilhouettes']
    rescue StandardError => err
      model.abort_operation
      raise err
    end
  end

  # Called when deactivates
  def reset
    model = Sketchup.active_model
    rendering_options = model.rendering_options

    destroy_world

    @sensor_output_csv.close if TrussFab.store_sensor_output?

    begin
      remove_ground
      reset_positions if @reset_positions_on_end
      reset_materials
      show_triangle_surfaces if @triangles_hidden
      show_pods_of_covers
      reset_force_labels
      reset_force_arrows
      reset_sensor_symbols
      reset_generic_links
      reset_pid_controllers
      rendering_options['EdgeDisplayMode'] = @show_edges
      rendering_options['DrawSilhouettes'] = @show_profiles
    rescue StandardError => err
      model.abort_operation
      raise err
    end

    reset_tested_pistons
  end

  def create_joints
    Graph.instance.edges.each_value do |edge|
      edge.create_joints(@world, @breaking_force)
    end

    Graph.instance.triangles.each_value do |triangle|
      if triangle.cover
        triangle.create_joints(@world, @breaking_force)
      end
    end
  end

  def reset_bodies_and_joints
    Graph.instance.nodes.values.each do |node|
      node.hub.reset_physics
    end
    Graph.instance.edges.values.each do |edge|
      edge.link.reset_physics
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
    model = Sketchup.active_model
    @ground_group = model.entities.add_group
    mat = model.materials.add('TFG')
    mat.color = Configuration::GROUND_COLOR
    mat.alpha = Configuration::GROUND_ALPHA
    @ground_group.material = mat
    x = y = Configuration::GROUND_SIZE
    z = Configuration::GROUND_HEIGHT
    pts = [
      [-x, -y, z],
      [x, -y, z],
      [x, y, z],
      [-x, y, z]
    ]
    face = @ground_group.entities.add_face(pts)
    face.pushpull(-Configuration::GROUND_THICKNESS)
    @ground_group.entities.each do |e|
      e.visible = false if e.is_a?(::Sketchup::Edge)
    end
    body = Simulation.create_body(@world, @ground_group, :box)
    body.static = true
    body.collidable = true
    body
  end

  # Note: this must be wrapped in operation
  def remove_ground
    if @ground_group && @ground_group.valid?
      mat = @ground_group.material
      if mat && mat.valid?
        @ground_group.material = nil
        @ground_group.model.materials.remove(mat)
      end
      @ground_group.erase!
    end
    @ground_group = nil
  end

  # Note: this must be wrapped in operation
  def show_triangle_surfaces
    Graph.instance.triangles.each do |_, triangle|
      triangle.surface.show
      # workaround to properly reset surface color
      triangle.surface.un_highlight
    end
    @triangles_hidden = false
  end

  # Note: this must be wrapped in operation
  def hide_triangle_surfaces
    Graph.instance.triangles.each do |_, triangle|
      triangle.surface.hide_parent # do not hide children so that covers are shown in simulation
    end
    @triangles_hidden = true
  end

  # Note: this must be wrapped in operation
  def hide_force_arrows
    Graph.instance.nodes.each do |_, node|
      node.hub.arrow.erase! unless node.hub.arrow.nil?
      node.hub.arrow = nil
    end
  end

  # Note: this must be wrapped in operation
  def hide_pods_of_covers
    Graph.instance.triangles.each do |_, triangle|
      if triangle.cover?
        triangle.cover.pods.each do |pod|
          pod.hide
        end
      end
    end
  end

  # Note: this must be wrapped in operation
  def show_pods_of_covers
    Graph.instance.triangles.each do |_, triangle|
      if triangle.cover?
        triangle.cover.pods.each do |pod|
          pod.show
        end
      end
    end
  end

  #
  # Piston Related Methods
  #

  def collect_all_pistons
    # get all pistons from actuator edges
    @pistons.clear
    Graph.instance.edges.each do |id, edge|
      @pistons[id] = edge.link if edge.link.is_a?(ActuatorLink)
    end
  end

  def collect_all_generic_links
    # get all generic links from actuator edges
    @generic_links.clear
    Graph.instance.edges.each do |id, edge|
      @generic_links[id] = edge.link if edge.link.is_a?(GenericLink)
    end
  end

  def collect_piston_groups
    @auto_piston_group.clear
    Graph.instance.edges.each_value do |edge|
      group = edge.link.piston_group
      next if group < 0
      @auto_piston_group[group] = [] if @auto_piston_group[group].nil?
      @auto_piston_group[group].push(edge)
    end
  end

  def schedule_piston_for_testing(edge, speed = 0.4)
    @moving_pistons.push(id: edge.id.to_i, expanding: true, speed: speed)
  end

  def unschedule_piston_for_testing(edge, speed = 0.4)
    @moving_pistons.delete(id: edge.id.to_i, expanding: true, speed: speed)
  end

  def reset_tested_pistons
    @moving_pistons.clear
  end

  def reset_generic_links
    @generic_links.each_value do |generic_link|
      generic_link.force = generic_link.initial_force
	  if generic_link.is_a?(DamperLink) or generic_link.is_a?(SpringDamperLink)
		generic_link.last_length = generic_link.length_current
	  end
    end
  end

  def reset_pid_controllers
    Graph.instance.edges.each do |_, edge|
      edge.link.reset_errors if edge.link.is_a?(PidController)
    end
  end

  def get_closest_node_to_point(point)
    closest_distance = Float::INFINITY
    Graph.instance.nodes.values.each do |node|
      if node.hub.body.get_position(1).distance(point) < closest_distance
        closest_distance = node.hub.body.get_position(1).distance(point)
      end
    end
    closest_distance
  end

  def test_pistons
    @moving_pistons.map! do |hash|
      link = @pistons[hash[:id]]
      joint = link.joint

      if joint && joint.valid?
        joint.rate = hash[:speed]
        joint.controller = (hash[:expanding] ? link.max : link.min)
        cur_disp = joint.cur_distance - joint.start_distance
      else
        cur_disp = 0.0
      end

      if (cur_disp - link.max).abs < 0.005 && hash[:expanding]
        @piston_world_time = @world.elapsed_time
        @piston_time = Time.now
        hash[:expanding] = false
      elsif (cur_disp - link.min).abs < 0.005 && !hash[:expanding]
        # increase speed everytime the piston reaches its minimum value
        unless hash[:speed] >= @max_speed && @max_speed != 0
          hash[:speed] += 0.05
        end
        hash[:expanding] = true
        # add the piston frequency as a label in the chart (every value between
        # two frequencies has the same frequency)
        timestep = (@world.elapsed_time - @piston_world_time).to_f.round(2)
        log_max_actuator_tensions(1 / timestep)
      end
      hash
    end
  end

  def test_piston_for_hub_movement(node, point)
    test_pistons
    update_entities
    node.hub.body.get_position(1).distance(point)
  end

  # this automatically uses the test function on all the pistons in the scene
  # => and tries to find the piston whose movement brings a given node closest
  # => to a given point
  def test_pistons_for(seconds, node, point)
    closest_distance = Float::INFINITY
    steps = (seconds.to_f / Configuration::WORLD_TIMESTEP).to_i
    steps.times do
      @world.advance
      distance = test_piston_for_hub_movement(node, point)
      closest_distance = distance if distance < closest_distance
    end
    reset_tested_pistons
    closest_distance
  end

  def check_pose(combination)
    highest_force = 0

    Graph.instance.edges.each_value do |edge|
      edge.link.joint.stiffness = 0.999
    end
    # move them to the proper position
    combination.each do |id, pos|
      actuator = @pistons[id]
      actuator.joint.breaking_force = 0
      actuator.joint.rate = 10
      actuator.joint.controller = case pos
                                  when -1
                                    actuator.min
                                  when 0
                                    0
                                  when 1
                                    actuator.max
                                  end
    end

    update_world_headless_by(3) # settle down

    # record
    @max_link_tensions.clear
    update_world_headless_by(0.2, true)

    Graph.instance.edges.each_value do |edge|
      force = @max_link_tensions[edge.id]
      highest_force = force if force.abs > highest_force.abs
    end
    highest_force
  end

  def check_static_force(piston_id, position)
    Graph.instance.edges.each_value do |edge|
      edge.link.joint.stiffness = 0.999
    end

    actuator = @pistons[piston_id]
    actuator.joint.breaking_force = 0
    actuator.joint.rate = 10
    actuator.joint.controller = actuator.max * position.to_f +
                                actuator.min * (1 - position.to_f)

    update_world_headless_by(3)
    @max_link_tensions.clear
    update_world_headless_by(0.2, true)
    @max_link_tensions[piston_id]
  end

  def print_piston_stats
    @moving_pistons.each do |hash|
      p "PISTON #{hash[:id]}"
      p "Speed: #{hash[:speed]}"
    end
  end

  #
  # Automatic Piston Movement Methods
  #

  def change_piston_value(id, value)
    actuator = @pistons[id.to_i]
    return unless actuator.joint && actuator.joint.valid?
    actuator.joint.rate = actuator.rate
    actuator.joint.controller =
      (value.to_f - Configuration::ACTUATOR_INIT_DIST) * (actuator.max -
                                                          actuator.min)
  end

  def grouped_change_piston_value(id, value)
    grouped_edges = @auto_piston_group[id.to_i]
    return if grouped_edges.empty?
    grouped_edges.each do |edge|
      actuator = edge.link
      next unless actuator.joint && actuator.joint.valid?
      actuator.joint.rate = actuator.rate
      actuator.joint.controller =
        (value.to_f - Configuration::ACTUATOR_INIT_DIST) * (actuator.max -
                                                            actuator.min)
    end
  end

  def move_joint(id, next_position, duration)
    @auto_piston_group.each do |edges|
      next if edges.nil?
      edges.each do |edge|
        link = edge.link
        next if link.piston_group != id || link.nil? || !link.joint.valid?
        joint = link.joint

        next_position_normalized = link.max * next_position.to_f +
                                   link.min * (1 - next_position.to_f)
        current_postion = joint.cur_distance - joint.start_distance
        position_distance = (current_postion - next_position_normalized).abs

        rate = position_distance / duration

        joint.rate = rate > 0.001 ? rate : link.rate
        joint.controller = next_position_normalized
      end
    end
  end

  def expand_actuator(id)
    move_joint(id, true)
  end

  def retract_actuator(id)
    move_joint(id, false)
  end

  def stop_actuator(id)
    link = nil
    @auto_piston_group.each do |edges|
      edges.each do |edge|
        next unless edge.link.piston_group == id
        link = edge.link
        unless link.nil?
          joint = link.joint
          joint.rate = 0
        end
      end
    end
  end

  def reset_piston_group
    Graph.instance.edges.each_value do |edge|
      edge.link.piston_group = -1
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

  def stopped?
    @stopped
  end

  def toggle_pause
    if @paused
      # reset_force_labels
      start
    else
      # note(tim): I'm not sure if we want to do this on pause. There should
      # probably be another mode that shows the force labels.
      # model = Sketchup.active_model
      # model.start_operation('update force label', true)
      # update_force_labels
      # model.commit_operation
      @paused = true
    end
  end

  def pause
    @paused = true
  end

  def unpause
    start
  end

  def restart
    @sensors.each do |sensor|
      @sensor_dialog.reset_chart(sensor.id) unless @sensor_dialog.nil?
    end
    reset
    setup
    start
  end

  def reset_positions
    @saved_transformations.each do |entity, transformation|
      entity.move!(transformation) if entity.valid?
    end
    @saved_transformations.clear
    Graph.instance.nodes.each_value do |node|
      node.update_position(node.original_position)
    end

    Graph.instance.triangles.each_value(&:update_sketchup_object)
  end

  def update_forces
    Graph.instance.nodes.each_value do |node|
      node.hub.apply_force
    end
    Graph.instance.edges.each_value do |edge|
      link = edge.link
      link.update_force if link.is_a?(PidController)
	  if link.is_a?(MetalSpringLink)
		#link.force = @frame
		link.update_force
	  elsif link.is_a?(DamperLink) or link.is_a?(SpringDamperLink)
		link.update_force(@timesteps)
	  end
    end
  end

  def update_world_by(time_step)
    steps = (time_step.to_f / Configuration::WORLD_TIMESTEP).to_i
    steps.times do
      update_forces
      @world.advance
      # We need to record this every time the world updates, otherwise,
      # we might skip the crucial forces involved
      rec_max_actuator_tensions
      rec_max_link_tensions if @peak_force_mode
    end
    Sketchup.active_model.start_operation('Sim: Visualize force', true)
    if @highest_force_mode
      visualize_highest_tension
    else
      visualize_tensions
    end
    Sketchup.active_model.commit_operation
  end
  
  def update_world_one_step
    update_forces
    @world.advance
    # We need to record this every time the world updates, otherwise,
    # we might skip the crucial forces involved
    rec_max_actuator_tensions
    rec_max_link_tensions if @peak_force_mode
    
    Sketchup.active_model.start_operation('Sim: Visualize force', true)
    if @highest_force_mode
      visualize_highest_tension
    else
      visualize_tensions
    end
    Sketchup.active_model.commit_operation
  end

  def update_world_headless_by(time_step, rec_max_tension = false)
    steps = (time_step.to_f / Configuration::WORLD_TIMESTEP).to_i
    steps.times do
      @world.advance
      rec_max_link_tensions if rec_max_tension
    end
  end

  def update_world
    Configuration::WORLD_NUM_ITERATIONS.times do
      update_forces
      @world.update_timestep = 1.0 / (@fps.nil? ? 60 : @fps)
      @ui.change_timeline_factor((@fps.nil? ? 60 : @fps) / 60.0)
      @world.advance
      # We need to record this every time the world updates, otherwise,
      # we might skip the crucial forces involved
      rec_max_actuator_tensions
      rec_max_link_tensions if @peak_force_mode
    end
    Sketchup.active_model.start_operation('Sim: Visualize force', true)
    if @highest_force_mode
      visualize_highest_tension
    else
      visualize_tensions
    end
    Sketchup.active_model.commit_operation
  end

  def update_entities
    model = Sketchup.active_model
    @world.update_group_transformations
    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
    Graph.instance.nodes.values.each do |node|
      node.update_position(node.hub.body.get_position(1))
    end
  end

  def update_hub_addons
    Graph.instance.nodes.values.each do |node|
      node.hub.move_addons(node.position)
    end
  end

  def reset_force_arrows
    Graph.instance.nodes.values.each do |node|
      node.hub.reset_addon_positions
    end
  end

  def reset_sensor_symbols
    Graph.instance.edges.each_value do |edge|
      edge.link.reset_sensor_symbol_position
    end
  end

  def nextFrame(view) # rubocop:disable Naming/MethodName
    view.show_frame
    return @running unless @running && !@paused

    update_world_one_step
    update_hub_addons
    update_entities

    if (@frame % 5).zero?
      # shift_chart_data if @frame > 100
      send_sensor_data_to_dialog
      test_pistons
    end

    @frame += 1

    update_status_text

    @running
  end

  def update_status_text
    delta_frame = @frame - @last_frame
    now = Time.now.to_f
    delta_time = now - @last_time
    @fps = (delta_frame / delta_time).to_i
    Sketchup.set_status_text("Frame: #{@frame}   "\
                             "Time: #{format('%.2f', @world.elapsed_time)} s  "\
                             "FPS: #{@fps}   "\
                             "Threads: #{@world.cur_threads_count}", SB_PROMPT)
    @last_frame = @frame
    @last_time = now
  end

  #
  # Sensor Related Methods
  #

  def open_sensor_dialog
    collect_sensors
    return if @sensors.empty?
    @sensor_dialog = ForceChart.new(@sensors)
    @sensor_dialog.open_dialog
  end

  def close_sensor_dialog
    return if @sensor_dialog.nil?
    @sensor_dialog.close if @sensor_dialog.visible?
  end

  def collect_sensors
    Graph.instance.nodes.values.each do |node|
      @sensors.push(node.hub) if node.hub.sensor?
    end
    Graph.instance.edges.values.each do |edge|
      @sensors.push(edge.link) if edge.link.sensor?
    end
  end

  def send_sensor_data_to_dialog
    return unless @sensor_dialog
    @sensors.each do |sensor|
      if sensor.is_a?(Hub)
        speed = sensor.body.get_velocity.length.to_f
        @sensor_dialog.add_chart_data(sensor.id, ' ', speed, 'Speed', 'Hub')
        accel = sensor.body.get_acceleration.length.to_f
        @sensor_dialog.add_chart_data(sensor.id, ' ', accel,
                                      'Acceleration', 'Hub')
      elsif sensor.is_a?(Link)
        @sensor_dialog.add_chart_data(sensor.id,
                                      ' ', @max_actuator_tensions[sensor.id],
                                      'Force', 'Edge')
        if TrussFab.store_sensor_output?
          @sensor_output_csv
            .write(@max_actuator_tensions[sensor.id].to_s + "\n")
        end
        @max_actuator_tensions[sensor.id] = 0
      end
    end
  end

  #
  # Force Related Methods
  #

  def add_force_to_node(node, force)
    node.hub.body.apply_force(force)
  end

  def apply_force
    @generic_links.each_value do |generic_link|
      generic_link.force = Configuration::GENERIC_LINK_FORCE
    end
  end

  # returns true if any of the joints in the structure broke
  def broken?
    broken = false
    Graph.instance.edges.each_value do |edge|
      next if edge.link.joint.nil?
      broken = true unless edge.link.joint.valid?
    end
    broken
  end

  # This is called when simulation starts and
  # assigns unique materials to bottles
  # Note: this must be wrapped in operation
  def assign_unique_materials
    mats = Sketchup.active_model.materials
    # First, store current mats of bottles and sub-bottles
    Graph.instance.edges.each_value do |edge|
      link = edge.link
      # Get the bottle of the link
      bottle = if link.is_a?(ActuatorLink)
                 link.first_cylinder.entity
               else
                 link.children[1].entity
               end
      persist_material(link, bottle)
    end
    # Now, create new materials
    @bottle_dat.each do |link, dat|
      umat = mats.add('TFX')
      umat.color = Configuration::BOTTLE_COLOR
      dat[3] = umat
      dat[0].material = umat
      dat[2].each { |e, _| e.material = nil }
      if link.is_a?(PhysicsLink) && !link.is_a?(ActuatorLink)
        second_cylinder = link.children[0].entity
        second_cylinder.material = dat[3]
      end
    end
  end

  def persist_material(link, bottle)
    bottle_entities = if bottle.is_a?(::Sketchup::Group)
                        bottle.entities
                      else
                        bottle.definition.entities
                      end
    sub_mats = {}
    bottle_entities.each do |entity|
      if entity.is_a?(::Sketchup::Group) ||
         entity.is_a?(::Sketchup::ComponentInstance)
        sub_mats[entity] = entity.material
      end
    end
    @bottle_dat[link] = [bottle, bottle.material, sub_mats, nil]
  end

  # This is called when simulation ends and restores original materials,
  # deleting the created ones.
  # Note: this must be wrapped in operation
  def reset_materials
    Graph.instance.edges.each_value do |edge|
      edge.link.un_highlight
    end
    @bottle_dat.each do |_, dat|
      Sketchup.active_model.materials.remove(dat[3]) if dat[3] && dat[3].valid?
    end
    @bottle_dat.clear
  end

  # The way this works is that before simulation starts,
  #   all bottles are assigned their own materials
  # During simulation, we update the colors of the materials,
  #   thus new materials are not created.
  # Note: this must be wrapped in operation
  def visualize_tensions
    @bottle_dat.each do |link, dat|
      mat = dat[3]
      next unless mat && mat.valid?
      force = if @peak_force_mode
                @max_link_tensions[link.id]
              else
                get_directed_force(link)
              end
      update_force_labels if @display_values
      r = (@breaking_force + force * Configuration::TENSION_SENSITIVITY) *
          @breaking_force_invh
      mat.color = Geometry.blend_colors(Configuration::TENSION_COLORS, r)
    end
  end

  def visualize_highest_tension
    whiten_all_bottles
    lowest_force_tuple = [nil, Float::INFINITY]
    highest_force_tuple = [nil, -Float::INFINITY]
    @bottle_dat.each do |link, _|
      force = if @peak_force_mode && !@max_link_tensions[link.id].nil?
                @max_link_tensions[link.id]
              else
                get_directed_force(link)
              end

      if force < lowest_force_tuple[1]
        lowest_force_tuple = [link, force]
      elsif force > highest_force_tuple[1]
        highest_force_tuple = [link, force]
      end
    end
    update_force_labels if @display_values
    color_single_link(lowest_force_tuple[0])
    color_single_link(highest_force_tuple[0])
  end

  def color_single_link(link)
    dat = @bottle_dat[link]
    mat = dat[3]
    return unless mat && mat.valid?
    force = get_directed_force(link)
    force = @max_link_tensions[link.id] if @peak_force_mode
    r = (@breaking_force + force * Configuration::TENSION_SENSITIVITY) *
        @breaking_force_invh
    mat.color = Geometry.blend_colors(Configuration::TENSION_COLORS, r)
  end

  def get_directed_force(link)
    if link.joint && link.joint.valid?
      pt1 = link.first_node.hub.entity.bounds.center
      pt2 = link.second_node.hub.entity.bounds.center
      dir = pt1.vector_to(pt2).normalize
      link.joint.linear_tension.dot(dir)
    else
      0.0
    end
  end

  def whiten_all_bottles
    @bottle_dat.each do |_, dat|
      dat[3].color = Configuration::HIGHLIGHT_COLOR
    end
  end

  # Returns total tension applied to actuators along their directions
  def compute_net_actuator_tension(edge)
    link = edge.link
    net_lin_tension = get_directed_force(link) if link.is_a?(Link)
    net_lin_tension
  end

  # Updates the net maximum tension variable
  def rec_max_actuator_tensions
    return unless @sensor_dialog
    Graph.instance.edges.each_value do |edge|
      next unless edge.link.sensor?
      net_lin_tension = compute_net_actuator_tension(edge)
      if @max_actuator_tensions[edge.id].nil?
        @max_actuator_tensions[edge.id] = net_lin_tension
      end
      if net_lin_tension.abs > @max_actuator_tensions[edge.id].abs
        @max_actuator_tensions[edge.id] = net_lin_tension
      end
    end
  end

  def rec_max_link_tensions
    Graph.instance.edges.each_value do |edge|
      net_lin_tension = compute_net_actuator_tension(edge)
      if @max_link_tensions[edge.id].nil?
        @max_link_tensions[edge.id] = net_lin_tension
      end
      if net_lin_tension.abs > @max_link_tensions[edge.id].abs
        @max_link_tensions[edge.id] = net_lin_tension
      end
    end
  end

  # Outs the net maximum tension of all actuators to the chart
  # and resets the @max_actuator_tensions variable
  def log_max_actuator_tensions(label)
    return unless @chart
    @chart.addData(label, @max_actuator_tensions)
    @max_actuator_tensions = 0.0
  end

  def add_chart_data(label, force)
    return unless @chart
    @chart.addData(label, force)
  end

  def shift_chart_data
    return unless @chart
    @chart.shift_data
  end

  # Sends @total_force to the force graph and adds a label
  # FIXME
  def add_chart_label(label)
    return unless @chart
    @chart.addData(label, @max_actuator_tensions.to_f)
  end

  # Adds a label with the force value for each edge in the graph
  # Note: this must be wrapped in operation
  def update_force_labels
    Graph.instance.edges.each_value do |edge|
      link = edge.link
      next unless link.is_a?(Link) # this might unnecessary
      pt1 = link.first_node.hub.entity.bounds.center
      pt2 = link.second_node.hub.entity.bounds.center
      dir = pt1.vector_to(pt2).normalize
      position = Geom.linear_combination(0.5, pt1, 0.5, pt2)
      tension = if link.joint && link.joint.valid?
                  if @peak_force_mode
                    @max_link_tensions[link.id]
                  else
                    link.joint.linear_tension.dot(dir)
                  end
                else
                  0.0
                end
      update_force_label(link, tension, position)
    end
  end

  # Adds a label with the force value for a single edge
  # Note: this must be wrapped in operation
  def update_force_label(link, force, position)
    if @force_labels[link].nil?
      model = Sketchup.active_model
      force_label = model.entities.add_text("--------------- #{force.round(1)}",
                                            position)
      force_label.layer = model.layers[Configuration::FORCE_LABEL_VIEW]
      @force_labels[link] = force_label
    else
      @force_labels[link].text = "--------------- #{force.round(1)}"
      @force_labels[link].point = position
    end
  end

  # Removes force labels
  # Note: this must be wrapped in operation
  def reset_force_labels
    @force_labels.each { |_, label| label.text = '' }
  end
end
