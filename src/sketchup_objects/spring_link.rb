require 'src/sketchup_objects/physics_link.rb'
require 'src/configuration/configuration.rb'

# PhysicsLink that behaves like a gas spring
class SpringLink < ActuatorLink
  attr_accessor :spring_parameter_k
  attr_reader :edge

  def initialize(first_node, second_node, edge, id: nil)
    @spring_parameter_k = 200
    super(first_node, second_node, edge, id: id)
    persist_entity
  end

  def spring_parameter_k=(k)
    @spring_parameter_k = k
    update_link_properties
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
    recreate_children
    return unless @joint && @joint.valid?

  end

  def update_link_transformations
    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center
    pt3 = Geom::Point3d.linear_combination(0.5, pt1, 0.5, pt2)
    # puts( "springl: " + pt1.to_s + pt2.to_s)
    move_sensor_symbol(pt3)

    # update position calculating a translation from the last to the new position
    vector_representation = pt1.vector_to(pt2)
    new_position = pt1

    # scale the entity to make it always connect the two adjacent hubs
    current_length = vector_representation.length
    scale_factor = current_length.to_f / @initial_spring_length
    # spring is oriented along the z-axis
    scaling = Geom::Transformation.scaling(1, 1, scale_factor)
    rotation = Geometry.rotation_transformation(Geom::Vector3d.new(0, 0, 1),
                                                vector_representation,
                                                Geom::Point3d.new(0, 0, 0))

    translation = Geom::Transformation.translation(new_position)

    @first_cylinder.entity.transformation=(translation * rotation * scaling)
  end

  def create_children
    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center

    # scale the entity to make it always connect the two adjacent hubs
    @initial_spring_length = pt1.vector_to(pt2).length.to_f
    spring_model =
      ParametricSpringModel.new(@initial_spring_length, @spring_parameter_k)
    @first_cylinder = Spring.new(self, spring_model.definition, nil)
    add(first_cylinder)
    # Update the link_transformation, that we're previously just initialized
    # with identity
    update_link_transformations
  end

  def set_piston_group_color
    # TODO
  end
end
