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

  def movement_plane
    [Geometry.midpoint(@movement_curve[0], @movement_curve[-1]),
     (@movement_curve[0] - @movement_curve[-1]).normalize]
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
      position_on_plane = position.project_to_plane(movement_plane)
      vector = position_on_plane - position

      @partner_handle.update_position(position_on_plane + vector)
    end
  end

  def create_entity
    group = Sketchup.active_model.entities.add_group
    entities = group.entities
    puts @definition
    entities.add_instance(@definition, Geom::Transformation::translation(@position))
  end
end
