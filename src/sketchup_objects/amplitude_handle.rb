require 'src/sketchup_objects/sketchup_object.rb'

class AmplitudeHandle < SketchupObject
  attr_reader :movement_curve
  attr_writer :partner_handle

  def initialize(position, material:Sketchup.active_model.materials['amplitude_handle_material'], id:nil, movement_curve:nil, partner_handle: nil, group: nil)
    super(id, material:material)
    @position = position
    @definition = ModelStorage.instance.models['amplitude_handle'].definition
    @entity = create_entity
    self.material = material
    @movement_curve = movement_curve
    @external_group = group
  end

  def midpoint
    Geometry.midpoint(@movement_curve[0], @movement_curve[-1])
  end

  def movement_plane
    [midpoint,
     (@movement_curve[0] - @movement_curve[-1]).normalize]
  end

  def update_position(position, move_partner: false)
    previous_position = @position
    @position = position
    @entity.move!(Geom::Transformation::translation(@position))

    if move_partner
      position_on_plane = position.project_to_plane(movement_plane)
      vector = position_on_plane - position

      previous_distance =
        (previous_position.project_to_plane(movement_plane) - previous_position).length

      scale_transform = Geom::Transformation.scaling(
        @movement_curve[@movement_curve.length / 2].project_to_plane(movement_plane),
        vector.length / previous_distance
      )

      @partner_handle.update_position(position_on_plane + vector)
      @external_group.transform! scale_transform
    end
  end

  def create_entity
    group = Sketchup.active_model.entities.add_group
    entities = group.entities
    puts @definition
    entities.add_instance(@definition, Geom::Transformation::translation(@position))
  end
end
