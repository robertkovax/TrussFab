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
    @movement_curve = extend_motion_curve(movement_curve.clone)
    @external_group = group
  end

  def extend_motion_curve(curve)
    # We don't use the last segment for the vector, but the before ones, as
    # these tend to be more stable. Probably because the last segment can have
    # problems due to the sampling of the motion
    vec = curve[1] - curve[2]
    vec.normalize!
    10.times do
      curve.unshift(curve[0] + vec)
    end

    vec = curve[-2] - curve[-3]
    vec.normalize!
    10.times do
      curve.push(curve[-1] + vec)
    end
    curve
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

    position_on_plane = position.project_to_plane(movement_plane)
    vector = position_on_plane - position

    previous_distance =
      (previous_position.project_to_plane(movement_plane) - previous_position).length

    amplitude_vec = (@movement_curve[0] - @movement_curve[-1]).normalize
    to_middle_vec = (@movement_curve[@movement_curve.length / 2] - @movement_curve[0])

    perpendicular_to_plane_vec = amplitude_vec.cross(to_middle_vec)

    move_to_center = Geom::Transformation.translation(midpoint)
    rotate_to_x_axis = Geometry.rotation_to_local_coordinate_system(amplitude_vec, perpendicular_to_plane_vec)

    scale_transform = Geom::Transformation.scaling(
      vector.length / previous_distance,
      1,
      (1 - vector.length / previous_distance) / 7 + 1,
      )
    fake_scale_transform = move_to_center* rotate_to_x_axis* scale_transform * rotate_to_x_axis.inverse * move_to_center.inverse

    @entity.transform!(fake_scale_transform)

    if move_partner

      puts "New distance between handles: #{(position_on_plane + vector - position).length.to_mm}.mm"
      @partner_handle.update_position(position_on_plane + vector)
      @external_group.transform! fake_scale_transform
    end
  end

  def create_entity
    group = Sketchup.active_model.entities.add_group
    entities = group.entities
    puts @definition
    instance = entities.add_instance(@definition, Geom::Transformation::translation(@position))
    instance.layer = Configuration::MOTION_TRACE_VIEW
    instance
  end
end
