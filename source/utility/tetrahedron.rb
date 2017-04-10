require ProjectHelper.utility_directory + 'geometry.rb'

class Tetrahedron
  def self.build position, definition, surface = nil
    x_vector, y_vector, z_vector = setup_scaled_axis_vectors definition
    surface = create_ground_surface(position, x_vector) if surface.nil?
  end

  def self.setup_scaled_axis_vectors definition
    edge_length = link_model.length + Configuration::DEFAULT_ELONGATION * 2

    x_vector = Geometry::X_AXIS
    y_vector = Geometry::Y_AXIS
    z_vector = Geometry::Z_AXIS

    x_vector.length = edge_length
    y_vector.length = edge_length
    z_vector.length = edge_length

    return x_vector, y_vector, z_vector
  end

  def self.create_ground_surface position, vector
    rotation = Geom::Transformation.rotation origin, Geometry::Z_AXIS, 2/3*Math::PI # rotate 120 degree in x-y-plane
    second_position = position + vector
    third_position = second_position + vector.transform(rotation)
    Graph.instance.create_surface_from_points position, second_position, third_position, definition
  end
end