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
    # puts( "springl: " + pt1.to_s + pt2.to_s)
    move_sensor_symbol(pt3)

    # update position calculating a translation from the last to the new position
    vector_representation = pt1.vector_to(pt2)
    offset_up = vector_representation.clone
    new_position = pt1.offset(offset_up, offset_up.length / 2)
    old_position = @first_cylinder.entity.bounds.center
    translation = Geom::Transformation.translation(old_position.vector_to(new_position))

    # scale the entity to make it always connect the two adjacent hubs
    current_length = vector_representation.length
    scale_factor = current_length.to_f / @last_length
    # spring is oriented along the x-axis
    scaling = Geom::Transformation.scaling(old_position, 1, 1, scale_factor)
    @last_length = current_length

    @first_cylinder.entity.transform!(Geometry.rotation_transformation(vector_representation, Geom::Vector3d.new(0, 0, 1), old_position))
    @first_cylinder.entity.transform!(scaling)
    @first_cylinder.entity.transform!(Geometry.rotation_transformation(Geom::Vector3d.new(0, 0, 1), vector_representation, old_position))
    # is translation needed?
    @first_cylinder.entity.transform!(translation)
  end


  def create_children
    direction_up = @position.vector_to(@second_position)
    offset_up = direction_up.clone
    position = @position.offset(offset_up, offset_up.length / 2)

    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center

    # update position calculating a translation from the last to the new position
    vector_representation = pt1.vector_to(pt2)

    # scale the entity to make it always connect the two adjacent hubs
    current_length = vector_representation.length
    if @last_length.nil?
      @last_length = current_length.to_f
    end
    scale_factor = current_length.to_f / @last_length


    spring_model = SpringModel.new
    @first_cylinder = Spring.new(position, direction_up, scale_factor, self, spring_model.definition, nil)
    @second_cylinder = SketchupObject.new #Spring.new(position, direction_up, self, spring_model.definition, nil);
    add(first_cylinder, second_cylinder)
  end

  def set_piston_group_color
    # TODO
  end
end
