require 'src/utility/geometry.rb'

class Tetrahedron
  def self.build(position, definition, surface = nil)
    x_vector, y_vector, z_vector = setup_scaled_axis_vectors(definition)
    surface = create_ground_surface(position, x_vector, definition) unless surface
    upper_point = Geometry.intersect_three_spheres(
      surface.first_node.position, surface.second_node.position, surface.third_node.position,
      z_vector.length, z_vector.length, z_vector.length
    )
    lower_point = Geometry.intersect_three_spheres(
      surface.third_node.position, surface.second_node.position, surface.first_node.position,
      z_vector.length, z_vector.length, z_vector.length
    )
    eye = Sketchup.active_model.active_view.camera.eye
    upper_point = lower_point if eye.distance(lower_point) < eye.distance(upper_point)
    return if upper_point.nil?
    surface.nodes.each do |node|
      Graph.instance.create_edge_from_points(node.position, upper_point, definition.model.name, 0, 0)
    end
    node = Graph.instance.duplicated_node?(upper_point)
    return unless node
    Graph.instance.create_surface(surface.first_node, surface.second_node, node)
    Graph.instance.create_surface(surface.first_node, surface.third_node, node)
    Graph.instance.create_surface(surface.second_node, surface.third_node, node)
  end

  def self.setup_scaled_axis_vectors(definition)
    edge_length = definition.length + Configuration::DEFAULT_ELONGATION * 2

    x_vector = Geometry::X_AXIS
    y_vector = Geometry::Y_AXIS
    z_vector = Geometry::Z_AXIS

    x_vector.length = edge_length
    y_vector.length = edge_length
    z_vector.length = edge_length

    [x_vector, y_vector, z_vector]
  end

  def self.create_ground_surface(position, vector, definition)
    rotation = Geom::Transformation.rotation(position, Geometry::Z_AXIS, 60.degrees)
    second_position = position + vector
    third_position = position + vector.transform(rotation)
    Graph.instance.create_surface_from_points(position, second_position, third_position, definition)
  end
end
