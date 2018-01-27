require 'src/thingies/link.rb'
require 'src/thingies/link_entities/cylinder.rb'
require 'src/simulation/simulation.rb'
require 'src/simulation/joints'

class ActuatorLink < Link

  attr_accessor :damping, :rate, :power, :min, :max
  attr_reader :joint, :first_cylinder, :second_cylinder

  def initialize(first_node, second_node, id: nil)
    @first_cylinder = nil
    @second_cylinder = nil
    @joint = nil

    super(first_node, second_node, 'actuator', id: id)

    @damping = 0.0
    @rate = 1.0
    @power = 0.0
    @min = -0.2
    @max = 0.2

    persist_entity
  end

  def change_color(color)
    [@first_cylinder, @second_cylinder].each do |cylinder|
      cylinder.change_color(color)
    end
  end

  def highlight(highlight_material = @highlight_material)
    change_color(highlight_material)
  end

  def un_highlight
    change_color(@model.material.color)
  end

  #
  # Physics methods
  #

  def create_joints(world, first_node, second_node)
    first_direction = mid_point.vector_to(first_node.position)
    second_direction = mid_point.vector_to(second_node.position)

    bd1 = first_node.thingy.body
    bd2 = second_node.thingy.body
    @joint = MSPhysics::PointToPointActuator.new(world, bd1, bd1.group.bounds.center, bd2.group.bounds.center, nil)
    @joint.connect(bd2)
    @joint.stiffness = Simulation::DEFAULT_STIFFNESS
    @joint.rate = @rate
    @joint.reduction_ratio = @damping
    @joint.power = @power
  end
  
  def update_link_transformations
    pt1 = @first_node.thingy.entity.bounds.center
    pt2 = @second_node.thingy.entity.bounds.center
    dir = pt2 - pt1
    return if (dir.length.to_f < 1.0e-6)
    dir.normalize!
    t1 = Geom::Transformation.new(pt1, dir)
    t2 = Geom::Transformation.new(pt2, dir.reverse)
    @first_cylinder.entity.move!(t1)
    @second_cylinder.entity.move!(t2)
  end

  def create_ball_joints(world, first_node, second_node)
    create_joints(world, first_node, second_node)
  end

  def reset_physics
    super
    @joint = nil
    [@first_cylinder, @second_cylinder].each do |cylinder|
      cylinder.body = nil
    end
  end

  def update_piston
    return if @joint.nil?
    @joint.rate = @rate
    @joint.reduction_ratio = @damping
    @joint.power = @power
  end

  #
  # Subthingy methods
  #

  def create_sub_thingies
    @first_elongation_length = @second_elongation_length = Configuration::MINIMUM_ELONGATION

    direction_up = @position.vector_to(@second_position)
    direction_down = @second_position.vector_to(@position)

    offset_up = direction_up.clone
    offset_down = direction_down.clone

    offset_up.length = @first_elongation_length
    offset_down.length = @second_elongation_length

    cylinder_start = @position.offset(offset_up)
    cylinder_end = @second_position.offset(offset_down)

    @first_cylinder = Cylinder.new(cylinder_start, direction_up, self, @model.outer_cylinder)
    @second_cylinder = Cylinder.new(cylinder_end, direction_down, self, @model.inner_cylinder)

    add(@first_cylinder, @second_cylinder)
  end
end
