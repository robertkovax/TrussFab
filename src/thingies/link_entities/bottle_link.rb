class BottleLink < Thingy
  attr_reader :model, :direction

  def initialize(position, direction, model,
                 id: nil, material: 'bottle_material')
    super(id, material: material)
    @position = position
    @direction = direction
    @model = model
    @entity = create_entity
    change_color(@material)
    persist_entity
  end

  def change_color(color)
    Sketchup.active_model.start_operation('Bottle Link: Change color', true, false, true)
    @entity.definition.entities.each do |ent|
      if ent.material != color
        ent.material = color
      end
    end
    Sketchup.active_model.commit_operation
  end

  def highlight(highlight_material = @highlight_material)
    change_color(highlight_material)
  end

  def un_highlight
    change_color(@model.model.material.color)
  end

  private

  def create_entity
    Sketchup.active_model.start_operation('Bottle Link: Create', true, false, true)
    return @entity if @entity
    translation = Geom::Transformation.translation(@position)

    rotation_angle = Geometry.rotation_angle_between(Geometry::Z_AXIS, @direction)
    rotation_axis = Geometry.perpendicular_rotation_axis(Geometry::Z_AXIS, @direction)
    rotation = Geom::Transformation.rotation(@position, rotation_axis, rotation_angle)

    transformation = rotation * translation

    entity = Sketchup.active_model.active_entities.add_instance(@model.definition, transformation)
    entity.layer = Configuration::COMPONENT_VIEW
    Sketchup.active_model.commit_operation
    entity.make_unique
  end
end
