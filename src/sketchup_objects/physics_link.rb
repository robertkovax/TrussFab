require 'src/sketchup_objects/link.rb'
require 'src/sketchup_objects/link_entities/cylinder.rb'
require 'src/sketchup_objects/link_entities/spring.rb'
require 'src/simulation/simulation.rb'

# SuperClass for moving links
class PhysicsLink < Link
  attr_reader :joint, :first_cylinder, :second_cylinder

  def initialize(first_node, second_node, edge, link_type, id: nil)
    @first_cylinder = nil
    @second_cylinder = nil
    @joint = nil
    @link_type = link_type

    super(first_node, second_node, edge, link_type, id: id)

    persist_entity
  end

  def change_color(color)
    [@first_cylinder, @second_cylinder].each do |cylinder|
      cylinder.material = color
    end
  end

  def highlight(highlight_material = @highlight_material)
    [@first_cylinder, @second_cylinder].each do |cylinder|
      cylinder.change_color(highlight_material)
    end
  end

  def un_highlight
    [@first_cylinder, @second_cylinder].each do |cylinder|
      cylinder.change_color(cylinder.material)
    end
  end

  #
  # Physics methods
  #

  def create_joints(world, first_node, second_node, breaking_force)
    bd1 = first_node.hub.body
    bd2 = second_node.hub.body
    pt1 = bd1.group.bounds.center
    pt2 = bd2.group.bounds.center
    @joint = case @link_type # NOTE: Add newly created link_types here
             when 'actuator'
               TrussFab::PointToPointActuator.new(world, bd1, bd2, pt1, pt2,
                                                  nil)
             when 'spring'
               TrussFab::PointToPointGasSpring.new(world, bd1, bd2, pt1, pt2,
                                                   nil)
             when 'generic'
               TrussFab::GenericPointToPoint.new(world, bd1, bd2, pt1, pt2, nil)
             when 'pid_controller'
               TrussFab::GenericPointToPoint.new(world, bd1, bd2, pt1, pt2, nil)
             else
               raise 'Link type @link_type is not yet implemented'
             end
    @joint.solver_model = Configuration::JOINT_SOLVER_MODEL
    @joint.stiffness = Configuration::JOINT_STIFFNESS
    @joint.breaking_force = breaking_force
    @initial_length = if @joint.class <= TrussFab::PointToPointActuator
                        @joint.cur_distance
                      elsif @joint.class <= TrussFab::GenericPointToPoint
                        @joint.cur_distance
                      else
                        @joint.cur_length
                      end
    update_link_properties
  end

  def update_link_transformations
    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center
    pt3 = Geom::Point3d.linear_combination(0.5, pt1, 0.5, pt2)
    dir = pt2 - pt1
    return if dir.length.to_f < 1.0e-6
    dir.normalize!

    ot = Geometry.scale_vector(dir, Configuration::MINIMUM_ELONGATION)
    t1 = Geom::Transformation.new(pt1 + ot, dir)
    t2 = Geom::Transformation.new(pt2 - ot, dir.reverse)
    @first_cylinder.entity.move!(t1)
    @second_cylinder.entity.move!(t2)

    move_sensor_symbol(pt3)
  end

  def reset_physics
    super
    @joint = nil
  end

  def update_link_properties
    raise NotImplementedError
  end

  #
  # Children SketchupObject methods
  #

  def update_limits; end

  def create_children
    if @link_type ==  'spring'
      direction_up = @position.vector_to(@second_position)
      offset_up = direction_up.clone
      position = @position.offset(offset_up, offset_up.length() / 2)

      spring_model = SpringModel.new
      @first_cylinder = Spring.new(position, direction_up, self, spring_model.definition, nil);
    else
      @first_elongation_length =
        @second_elongation_length = Configuration::MINIMUM_ELONGATION

      direction_up = @position.vector_to(@second_position)
      direction_down = @second_position.vector_to(@position)

      offset_up = direction_up.clone
      offset_down = direction_down.clone

      offset_up.length = @first_elongation_length
      offset_down.length = @second_elongation_length

      cylinder_start = @position.offset(offset_up)
      cylinder_end = @second_position.offset(offset_down)

      cylinder_model = PhysicsLinkModel.new(length)

      @first_cylinder = Cylinder.new(cylinder_start, direction_up, self,
                                     cylinder_model.outer_cylinder, length)
      @second_cylinder = Cylinder.new(cylinder_end, direction_down, self,
                                      cylinder_model.inner_cylinder, length)

      update_limits

      add(@first_cylinder, @second_cylinder)
    end
  end
end
