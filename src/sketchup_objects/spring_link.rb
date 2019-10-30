require 'src/sketchup_objects/physics_link.rb'
require 'src/configuration/configuration.rb'

# PhysicsLink that behaves like a gas spring
class SpringLink < PhysicsLink
  attr_accessor :extended_length, :stroke_length, :extended_force, :threshold,
                :damp

  def initialize(first_node, second_node, edge, id: nil)
    super(first_node, second_node, edge,'spring', id: id)

    @stroke_length = Configuration::SPRING_STROKE_LENGTH
    @resonant_frequency = Configuration::SPRING_RESONANT_FRERQUENCY
    @extended_force = Configuration::SPRING_EXTENDED_FORCE
    @threshold = Configuration::SPRING_THRESHOLD
    @damp = Configuration::SPRING_DAMP

    persist_entity
  end

  def change_color(color)
    # [@first_cylinder, @second_cylinder].each do |cylinder|
    #   cylinder.material = color
    # end
  end

  def highlight(highlight_material = @highlight_material)
    # [@first_cylinder, @second_cylinder].each do |cylinder|
    #   cylinder.change_color(highlight_material)
    # end
  end

  def un_highlight
    # [@first_cylinder, @second_cylinder].each do |cylinder|
    #   cylinder.change_color(cylinder.material)
    # end
  end

  #
  # Physics methods
  #

  def update_link_properties
    return unless @joint && @joint.valid?
    @joint.stroke_length = @stroke_length
    @joint.extended_force = @extended_force
    @joint.threshold = @threshold
    @joint.damp = @damp
  end

  def update_link_transformations
    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center
    pt3 = Geom::Point3d.linear_combination(0.5, pt1, 0.5, pt2)
    # dir = pt2 - pt1
    # return if dir.length.to_f < 1.0e-6
    # dir.normalize!
    #
    # ot = Geometry.scale_vector(dir, Configuration::MINIMUM_ELONGATION / 2)
    # t1 = Geom::Transformation.new(pt1 + ot, dir)
    # t2 = Geom::Transformation.new(pt2 - ot, dir.reverse)

    # @first_cylinder.entity.move!(t1)
    # @second_cylinder.entity.move!(t2)
    move_sensor_symbol(pt3)


    direction_up = pt1.vector_to(pt2)
    offset_up = direction_up.clone
    new_position = pt1.offset(offset_up, offset_up.length() / 2)
    old_position = @first_cylinder.entity.bounds.center
    translation = Geom::Transformation.translation(old_position.vector_to(new_position))

    spring_model = SpringModel.new
    @first_cylinder.entity.transform!(translation)
  end


  def create_children
    direction_up = @position.vector_to(@second_position)
    offset_up = direction_up.clone
    position = @position.offset(offset_up, offset_up.length() / 2)

    spring_model = SpringModel.new
    @first_cylinder = Spring.new(position, direction_up, self, spring_model.definition, nil)
    @second_cylinder = SketchupObject.new #Spring.new(position, direction_up, self, spring_model.definition, nil);
  end

  def set_piston_group_color
    # TODO
  end
end
