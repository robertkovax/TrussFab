require 'src/thingies/link.rb'
require 'src/thingies/link_entities/cylinder.rb'
require 'src/simulation/simulation_helper.rb'

class ActuatorLink < Link

  attr_reader :piston

  def initialize(first_position, second_position, id: nil)
    @first_cylinder = nil
    @second_cylinder = nil
    @piston = nil
    super(first_position, second_position, 'actuator', id: id)
  end

  def create_body(world)
    first_cylinder_body = @first_cylinder.create_body(world)
    second_cylinder_body = @second_cylinder.create_body(world)

    direction_up = @first_position.vector_to(@second_position)
    piston_matrix = Geom::Transformation.new(@first_position, direction_up)
    @piston = create_piston(world,
                            first_cylinder_body,
                            second_cylinder_body,
                            piston_matrix)

    [first_cylinder_body, second_cylinder_body]
  end

  def create_joints(world)
    @first_joint.create(world, @first_cylinder.body)
    @second_joint.create(world, @second_cylinder.body)
  end

  def create_sub_thingies
    direction_up = @first_position.vector_to(@second_position)
    direction_down = @second_position.vector_to(@first_position)

    @first_cylinder = Cylinder.new(@first_position, direction_up, @model.outer_piston)
    @second_cylinder = Cylinder.new(@second_position, direction_down, @model.inner_piston)

    add(@first_cylinder, @second_cylinder)
  end
end