require 'src/sketchup_objects/physics_link.rb'
require 'src/configuration/configuration.rb'
require 'src/sketchup_objects/link_entities/spring_cylinder.rb'
require 'src/system_simulation/spring_picker.rb'
require 'src/sketchup_objects/spring_constant_observer.rb'

# PhysicsLink that behaves like a gas spring
class SpringLink < ActuatorLink
  attr_accessor :actual_spring_length, :initial_edge_length
  attr_reader :edge, :initial_spring_length, :spring_parameters

  COLORS = Configuration::INTENSE_COLORS

  def initialize(first_node, second_node, edge, spring_parameters: nil, id: nil)
    @initial_edge_length = edge.length.to_f
    @spring_parameters = spring_parameters ? spring_parameters : SpringPicker.instance.get_default_spring(edge.length.to_m)
    @spring_parameters[:enable_preloading] = true
    @actual_spring_length = @spring_parameters[:unstreched_length].m
    @spring_coil_diameter = @spring_parameters[:coil_diameter].m
    super(first_node, second_node, edge, id: id)
    @first_elongation_length =
      @second_elongation_length = Configuration::MINIMUM_ELONGATION
    @id_label = nil

    persist_entity
    update_id_label
  end

  def spring_parameter_k
    @spring_parameters[:k]
  end

  def get_color_string
    COLORS[@piston_group]
  end

  def spring_parameters=(parameters)
    @spring_parameters = parameters
    @actual_spring_length = @spring_parameters[:unstreched_length].m
    @spring_coil_diameter = @spring_parameters[:coil_diameter].m
    update_link_properties
    update_id_label
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

  def delete
    @id_label.erase!
    super
  end

  #
  # Physics methods
  #

  def update_link_properties
    super
    recreate_children
  end

  # Position and rotate the models correctly in the scene.
  def update_link_transformations
    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center
    pt3 = Geom::Point3d.linear_combination(0.5, pt1, 0.5, pt2)
    # puts( "springl: " + pt1.to_s + pt2.to_s)
    move_sensor_symbol(pt3)

    # Update placing of spring and cylinders calculating a transformation from the origin to the new position
    vector_representation = pt1.vector_to(pt2)
    current_edge_length = vector_representation.length

    # Resembles the compression while animating
    scale_factor = current_edge_length.to_f / @initial_edge_length

    link_center_position = pt1 + Geometry.scale_vector(vector_representation, 0.5)
    # Get the springs position by going half a spring length of the link center
    half_spring_vector = vector_representation.clone
    half_spring_vector.length = @actual_spring_length / 2
    spring_position = link_center_position - Geometry.scale_vector(half_spring_vector, scale_factor)

    # Create transformation for spring
    # SketchupObjects are oriented along the z-axis
    scaling = Geom::Transformation.scaling(1, 1, scale_factor)
    rotation = Geometry.rotation_transformation(Geom::Vector3d.new(0, 0, 1),
                                                vector_representation,
                                                Geom::Point3d.new(0, 0, 0))

    translation = Geom::Transformation.translation(spring_position)

    @first_cylinder.entity.transformation = translation * rotation * scaling

    # Create transformation for cylinder
    translation_cylinder = Geom::Transformation.translation(pt1)
    scaling_cylinder = Geom::Transformation.scaling(1, 1, scale_factor)
    @second_cylinder.entity.transformation = translation_cylinder * rotation * scaling_cylinder


  end

  def create_children
    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center

    # scale the entity to make it always connect the two adjacent hubs

    spring_model = ParametricSpringModel.new(@actual_spring_length, @spring_parameters)
    @first_cylinder = Spring.new(self, spring_model.definition, nil)
    add(@first_cylinder)

    @second_cylinder = SpringCylinder.new(self, @initial_edge_length, @actual_spring_length,
                                          @spring_coil_diameter)
    add(@second_cylinder)

    # Update the link_transformation, that we're previously just initialized
    # with identity
    update_link_transformations
    set_piston_group_color
  end

  def inspect
    initial_length =
      (@initial_edge_length - 2 * Configuration::BALL_HUB_RADIUS)
      .to_mm.round(2)
    "Spring #{id} (#{@first_node.id}, #{@second_node.id}): " \
    "initial Length: #{initial_length}mm, " \
    "spring parameters: #{@spring_parameters}"
  end

  def set_piston_group_color
    #@second_cylinder.material = COLORS[@piston_group]
  end

  def update_id_label
    # always recreate label
    @id_label.erase! if @id_label

    pt1 = @first_node.hub.entity.bounds.center
    pt2 = @second_node.hub.entity.bounds.center

    vector_representation = pt1.vector_to(pt2)
    spring_center = pt1.offset(vector_representation, vector_representation.length / 2)
    label_position = spring_center.offset(Geom::Vector3d.new(0, 1, 0), 12.cm)

    @id_label = Sketchup.active_model.entities.add_text("#{@spring_parameters[:k]}N/m ",
                                                        spring_center, label_position - spring_center)
    @id_label.layer = Sketchup.active_model.layers[Configuration::SPRING_INSIGHTS]
    @id_label.add_observer(SpringConstantObserver.new(@id))
  end

  def upadate_spring_visualization
    delete_children
    create_children
  end
end
