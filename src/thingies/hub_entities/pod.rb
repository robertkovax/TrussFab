require 'src/simulation/simulation.rb'

class Pod < Thingy

  attr_accessor :body
  attr_reader :position, :direction

  attr_reader :node

  def initialize(node, position, direction,
                 id: nil, material: 'elongation_material')
    super(id, material: material)
    @position = position
    @direction = direction
    @model = ModelStorage.instance.models['pod']
    @body = nil
    @node = node
    @direction.length = @model.length
    @entity = create_entity
  end

  def distance(point)
    # offset first point to factor in the visible hub radius
    first_point = @position.offset(@direction, Configuration::BALL_HUB_RADIUS / 2)
    second_point = @position + @direction
    Geometry.dist_point_to_segment(point, [first_point, second_point])
  end

  def update_position(position)
    @position = position
    delete_entity
    @entity = create_entity
  end

  def create_body(world)
    @body = Simulation.create_body(world, @entity)
    @body.collidable = true
    @body.mass = Simulation::POD_MASS
    @body.static = true
    @body
  end

  def delete
    @node.delete_pod_information(@id)
    super
  end

  private

  def create_entity
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS, @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS, @direction)
    rotation = Geom::Transformation.rotation(@position, rotation_axis, rotation_angle)

    transformation = rotation * translation

    entity = Sketchup.active_model.active_entities.add_instance(@model.definition, transformation)
    entity.material = @material
    entity
  end
end
