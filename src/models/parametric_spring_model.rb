
class ParametricSpringModel
  attr_reader :definition, :material

  def initialize(free_length, spring_parameters)
    # Construct a spring out of a circle and a path
    model = Sketchup.active_model
    definitions = model.definitions
    @definition = definitions.add "Spring {#{free_length.to_s}}"
    entities = @definition.entities

    if spring_parameters
      spring_radius = spring_parameters[:coil_diameter].m
      spring_windings = spring_parameters[:windings]
      material_thickness = spring_parameters[:wire_diameter].m
    end

    spring_radius ||= 45.mm
    spring_windings ||= 8.5
    material_thickness ||= 8.mm
    # Draw a circle on the ground plane around the origin.
    curve = entities.add_curve(generate_spring_curve free_length, spring_radius, spring_windings, 200)

    first_edge = curve[0]

    normal_vector = first_edge.end.position - first_edge.start.position
    center_point = Geom::Point3d.new(spring_radius, 0, 0)
    radius = material_thickness / 2

    edgearray = entities.add_circle center_point, normal_vector, radius, 10
    circle_face = entities.add_face(edgearray)
    circle_face.followme curve
    @material = Sketchup.active_model.materials['spring_material']
  end

  def generate_spring_curve(length, radius, windings, samples)

    scale_fraction = 2 * Math::PI * windings / length
    vertices = []
    (0..samples).each do |sample|

      # t goes from 0 to 1 in samples many steps
      t = sample.to_f / samples * length

      x = radius * Math.cos(t * scale_fraction)
      y = radius * Math.sin(t * scale_fraction)
      z = t
      # puts "t: " + t.to_s + " x: " + x.to_s + " y: " + y.to_s + " z: " + z.to_s
      vertices.push([x, y, z])
    end
    vertices
  end

  def valid?
    @definition.valid?
  end
end
