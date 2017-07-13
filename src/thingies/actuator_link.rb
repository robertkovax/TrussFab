require 'src/thingies/link.rb'
require 'src/thingies/link_entities/cylinder.rb'
require 'src/simulation/simulation.rb'

class ActuatorLink < Link

  attr_reader :piston, :first_cylinder_body, :second_cylinder_body,
              :piston_group

  def initialize(first_position, second_position, id: nil)
    @first_cylinder = nil
    @second_cylinder = nil

    @first_cylinder_body = nil
    @second_cylinder_body = nil

    @piston = nil
    super(first_position, second_position, 'actuator', id: id)
    @piston_group = 'a'
  end

  def change_piston_group(group=nil)
    if group.nil?
      case @piston_group 
        when 'a'  
          @piston_group = 'b'
          set_group_color('piston_b')
          puts "i'm group B now"
        when 'b'
          @piston_group = 'c'
          set_group_color('piston_c')
          puts "i'm group C now"
        when 'c'  
          @piston_group = 'd'
          set_group_color('piston_d')
          puts "i'm group D now"
        when 'd'  
          @piston_group = 'a'
          set_group_color('piston_a')
          puts "i'm group A now"
      end
    else
      @piston_group = group
      4.times { |n| change_piston_group }
    end
  end

  def set_group_color(color)
    change_color(color)
    sub_thingies.each { |sub_thingy| sub_thingy.color = color }
  end

  def create_body(world)
    @first_cylinder_body = @first_cylinder.create_body(world)
    @second_cylinder_body = @second_cylinder.create_body(world)

    direction_up = @position.vector_to(@second_position)
    piston_matrix = Geom::Transformation.new(@position, direction_up)
    @piston = Simulation.create_piston(world,
                                       @first_cylinder_body,
                                       @second_cylinder_body,
                                       piston_matrix)

    [@first_cylinder_body, @second_cylinder_body]
  end

  def create_joints(world)
    @first_joint.create(world, @first_cylinder.body)
    @second_joint.create(world, @second_cylinder.body)
  end

  def create_ball_joints(world, first_node, second_node)
    first_direction = mid_point.vector_to(first_node.position)
    second_direction = mid_point.vector_to(second_node.position)

    first_ball_joint = ThingyBallJoint.new(first_node, first_direction)
    second_ball_joint = ThingyBallJoint.new(second_node, second_direction)

    first_ball_joint.create(world, @first_cylinder.body)
    second_ball_joint.create(world, @second_cylinder.body)
  end

  def create_sub_thingies
    direction_up = @position.vector_to(@second_position)
    direction_down = @second_position.vector_to(@position)

    @first_cylinder = Cylinder.new(@position, direction_up, @model.outer_piston)
    @second_cylinder = Cylinder.new(@second_position, direction_down, @model.inner_piston)

    add(@first_cylinder, @second_cylinder)
  end
end