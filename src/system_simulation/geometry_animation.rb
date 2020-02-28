class GeometryAnimation
  attr_accessor :factor, :running
  def initialize(data, index = 0)
    @data = data
    @index = index
    @running = true
    @factor = 1

    ragdoll
  end

  def frontBodyPosition position
    position
  end

  def backBodyPosition position
    position + Geom::Vector3d.new(-10, 0, 0)
  end

  def downBodyPosition position
    position + Geom::Vector3d.new(-5, 0, -10)
  end

  def rightArmBodyPosition position
    position + Geom::Vector3d.new(-5, -10, -5)
  end

  def ragdoll
    @world = TrussFab::World.new
    @world.set_gravity(0.0, 0.0, -9.81)

    position = Geom::Point3d.new( 0, 0, 0)

    frontHub = Hub.new(frontBodyPosition(position), incidents: [])
    frontHub.create_body @world
    frontHub.body.static = true
    frontHub.body.mass = 10
    backHub = Hub.new(backBodyPosition(position), incidents: [])
    backHub.create_body @world
    backHub.body.static = true
    backHub.body.mass = 10
    downHub = Hub.new(downBodyPosition(position), incidents: [])
    downHub.create_body @world
    downHub.body.static = true
    downHub.body.mass = 10

    rightArmHub = Hub.new(rightArmBodyPosition(position), incidents: [])
    rightArmHub.create_body @world
    rightArmHub.body.static = false
    rightArmHub.body.mass = 10

    @frontRightJoint = TrussFab::PointToPoint.new(@world, frontHub.body, rightArmHub.body, frontBodyPosition(position), rightArmBodyPosition(position), nil)
    @backRightJoint = TrussFab::PointToPoint.new(@world, backHub.body, rightArmHub.body, backBodyPosition(position), rightArmBodyPosition(position), nil)
    @rightArmDownJoint = TrussFab::PointToPointGasSpring.new(@world, rightArmHub.body, downHub.body, rightArmBodyPosition(position), downBodyPosition(position), nil)

    [@frontRightJoint, @backRightJoint].each do |joint|
      joint.solver_model = Configuration::JOINT_SOLVER_MODEL
      joint.stiffness = Configuration::JOINT_STIFFNESS
      joint.breaking_force = 0
      joint.start_distance = 0.26
      joint.bodies_collidable = false
    end

    @rightArmDownJoint.solver_model = Configuration::JOINT_SOLVER_MODEL
    @rightArmDownJoint.extended_length = 0.5
    @rightArmDownJoint.stroke_length = 0.3
    @rightArmDownJoint.extended_force = 0.00001
    @rightArmDownJoint.threshold = 0.1
    @rightArmDownJoint.damp = 0.1
  end

  def toggle_running
    puts "Toggle running, before toggle: #{@running}"
    @running = !@running
    ragdoll
    @factor = 1
  end

  def nextFrame(view)
    Sketchup.active_model.start_operation('visualize export result', true)
    unless (@running)
      # last frame before animation stops – so we set value to last data sample and reset index to reset animation
      @index = 0
    end
    current_data_sample = @data[@index]

    # Graph.instance.nodes.each do |node_id, node|
    #   node.update_position(current_data_sample.position_data[node_id.to_s])
    #   node.hub.update_position(current_data_sample.position_data[node_id.to_s])
    #   node.hub.update_user_indicator
    # end

    if @frontRightJoint
      1.times do
        puts "World advance"
        @world.advance
      end
      z = 20 * Math.sin( @index.to_f / @data.length.to_f * 2* Math::PI * 2)
      if z > 19
        z = 20
      end
      position = Geom::Point3d.new(0, 0, z)
      # puts "Position: #{position}"
      #
      # puts "frontRightJ valid? #{@frontRightJoint.valid?}"
      # puts "backRightJ valid? #{@backRightJoint.valid?}"
      # puts "force on spring: #{@rightArmDownJoint.linear_tension}"
      # puts "spring valid?: #{@rightArmDownJoint.valid?}"
      # puts "spring distance: #{@rightArmDownJoint.cur_length}"

      @rightArmDownJoint.set_point2 downBodyPosition position
      @frontRightJoint.set_point1 frontBodyPosition position
      @backRightJoint.set_point1 backBodyPosition position

      Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a) if @group && !@group.deleted?
      @group = Sketchup.active_model.entities.add_group
      entities = @group.entities
      entities.add_line(@frontRightJoint.get_point1, @frontRightJoint.get_point2)
      entities.add_line(@backRightJoint.get_point1, @backRightJoint.get_point2)
      entities.add_line(@backRightJoint.get_point1, @rightArmDownJoint.get_point1)
      entities.add_line(@frontRightJoint.get_point1, @rightArmDownJoint.get_point1)
      entities.add_line(@rightArmDownJoint.get_point1, @rightArmDownJoint.get_point2)
    end

    Graph.instance.edges.each do |_, edge|
      link = edge.link
      link.update_link_transformations
    end
    puts(current_data_sample.time_stamp)

    ## new_position = Geom::Point3d.new(value[1].to_f().mm * 1000, value[2].to_f().mm * 1000, value[3].to_f().mm * 1000)
    #new_position = Geom::Point3d.new(value[1], value[2], value[3])
    #
    #scaled_second_vector = @second_vector.clone
    #scaled_second_vector.length = ((@second_vector.length * 2) * (1.0 + value[1].to_f) * @factor) - @second_vector.length
    #
    #@edge.second_node.update_position(new_position)
    #@edge.second_node.hub.update_position(@edge.second_node.hub.position)
    #
    #Graph.instance.edges.each do |_, edge|
    #  link = edge.link
    #  link.update_link_transformations
    #end
    Sketchup.active_model.commit_operation
    view.refresh
    @index = @index + @factor
    if @index + @factor >= @data.length
      @index = 0
      sleep(1)
    end

    return @running
  end
end
