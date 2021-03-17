require 'src/sketchup_objects/sketchup_object.rb'

class AmplitudeHandle < SketchupObject
  attr_reader :movement_curve
  attr_writer :partner_handle

  def initialize(position, material:Sketchup.active_model.materials['amplitude_handle_material'], id:nil, movement_curve:nil, partner_handle: nil)
    super(id, material:material)
    @position = position
    @definition = create_handle_definition
    @entity = create_entity
    self.material = material
    @movement_curve = movement_curve
  end

  def create_handle_definition
    # TODO: this could probably be cached
    handle_definition = Sketchup.active_model.definitions.add "Amplitude Handle Definition"
    handle_definition.behavior.always_face_camera = true
    entities = handle_definition.entities
    # always_face_camera will try to always make y axis face the camera
    edgearray = entities.add_circle(Geom::Point3d.new, Geom::Vector3d.new(0, -1, 0), 1, 10)
    edgearray.each { |e| e.hidden = true }
    first_edge = edgearray[0]
    arccurve = first_edge.curve
    entities.add_face(arccurve)
    handle_definition
  end

  def update_position(position, move_partner: false)
    previous_position = @position
    @position = position
    @entity.move!(Geom::Transformation::translation(@position))

    if move_partner
      distance = Geometry.distance_on_curve(previous_position, position, @movement_curve)
      partner_position = Geometry.move_point_along_curve(@partner_handle.position, distance, @movement_curve)
      @partner_handle.update_position(partner_position)
    end
  end

  def create_entity
    group = Sketchup.active_model.entities.add_group
    entities = group.entities
    puts @definition
    entities.add_instance(@definition, Geom::Transformation::translation(@position))
  end
end
