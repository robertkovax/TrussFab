class Ragdoll
  attr_reader :position

  def initialize
    @group = Sketchup.active_model.entities.add_group
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
      joint.stiffness = 0.9
      joint.breaking_force = 0
      joint.start_distance = 0.4
      joint.bodies_collidable = false
    end

    @rightArmDownJoint.solver_model = Configuration::JOINT_SOLVER_MODEL
    @rightArmDownJoint.extended_length = 0.6
    @rightArmDownJoint.stroke_length = 0.2
    @rightArmDownJoint.extended_force = 0.0001
    @rightArmDownJoint.threshold = 0.2
    @rightArmDownJoint.damp = 999
    puts "Current length: #{@rightArmDownJoint.cur_length}"
  end

  def position=(position)
    @position = position
    # @rightArmDownJoint.set_point2 downBodyPosition @position
    @frontRightJoint.set_point1 frontBodyPosition @position
    @backRightJoint.set_point1 backBodyPosition @position
  end

  def clear
    Sketchup.active_model.active_entities.erase_entities(@group.entities.to_a) unless @group.deleted?
  end

  def redraw
    Sketchup.active_model.start_operation('', true)
    clear
    draw
    Sketchup.active_model.commit_operation
  end

  def draw
    @group = Sketchup.active_model.entities.add_group

    @group.entities.add_face(@frontRightJoint.get_point1, @frontRightJoint.get_point2, @backRightJoint.get_point1)
    puts "Lengt: #{(@frontRightJoint.get_point1 - @frontRightJoint.get_point2).length}"
    # cylinder_from_points(@backRightJoint.get_point1, @backRightJoint.get_point2, 2)
    # cylinder_from_points(@backRightJoint.get_point1, @rightArmDownJoint.get_point1, 2)
    # cylinder_from_points(@frontRightJoint.get_point1, @rightArmDownJoint.get_point1, 2)
    # This would visualize the spring:
    @group.entities.add_line(@rightArmDownJoint.get_point1, @rightArmDownJoint.get_point2)
  end

  def cylinder_from_points(point1, point2, radius)
    vec = point2 - point1
    draw_cylinder point1, radius, vec if vec.length > 1
  end

  def draw_cylinder(center, radius, direction)
    # This is actually harder than I thought, cause after pushpull, the references
    # to the faces are gone
    @group = Sketchup.active_model.entities.add_group if @group.deleted?
    entities = @group.entities
    normal = direction.normalize
    edges = entities.add_circle(center, normal, radius, 10)
    face = entities.add_face(edges)
    face.pushpull direction.length if face
  end

  def advance
    2.times do
      @world.advance
        puts "Current force: #{@rightArmDownJoint.linear_tension}"
    end
    redraw
  end

  def frontBodyPosition position
    position
  end

  def backBodyPosition position
    position + Geom::Vector3d.new(-10, 0, 0)
  end

  def downBodyPosition position
    position + Geom::Vector3d.new(-5, -10, -10)
  end

  def rightArmBodyPosition position
    position + Geom::Vector3d.new(-5, -20, 0)
  end

end
