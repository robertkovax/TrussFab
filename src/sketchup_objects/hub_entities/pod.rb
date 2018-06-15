require 'src/simulation/simulation.rb'

# Pod
class Pod < SketchupObject
  attr_accessor :is_fixed

  attr_reader :position, :direction

  def initialize(position, direction, is_fixed: true,
                 id: nil, material: 'elongation_material')
    super(id, material: material)
    @position = position
    @direction = direction
    @model = ModelStorage.instance.models['pod']
    @direction.length = @model.length
    @entity = create_entity
    @is_fixed = is_fixed
    persist_entity
  end

  def distance(point)
    # offset first point to factor in the visible hub radius
    first_point = @position.offset(@direction,
                                   Configuration::BALL_HUB_RADIUS / 2)
    second_point = @position + @direction
    Geometry.dist_point_to_segment(point, [first_point, second_point])
  end

  def translation
    Geom::Transformation.translation(@position)
  end

  def rotation
    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS,
                                                     @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS,
                                                         @direction)
    Geom::Transformation.rotation(@position, rotation_axis, rotation_angle)
  end

  def update_position(position)
    @position = position
    transformation = rotation * translation
    @entity.move!(transformation)
  end

  def delete
    super
  end

  private

  def create_entity
    transformation = rotation * translation

    entity = Sketchup.active_model
                     .active_entities
                     .add_instance(@model.definition, transformation)
    entity.material = @material
    entity
  end
end
