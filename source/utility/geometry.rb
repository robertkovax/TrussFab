class Geometry
  X_AXIS = Geom::Vector3d.new 1, 0, 0
  Y_AXIS = Geom::Vector3d.new 0, 1, 0
  Z_AXIS = Geom::Vector3d.new 0, 0, 1

  def self.rotation_angle_between first_vector, second_vector
    first_vector.angle_between second_vector
  end

  def self.perpendicular_rotation_axis first_vector, second_vector
    if first_vector.parallel? second_vector
      get_perpendicular_vector first_vector
    else
      first_vector.cross second_vector
    end
  end

  def self.get_perpendicular_vector vector
    Geom::Vector3d.new  vector.y - vector.z,
                        vector.z - vector.x,
                        vector.x - vector.y
  end

  def self.triangle_incenter point1, point2, point3
    length_a = point1.distance point2
    length_b = point2.distance point3
    length_c = point3.distance point1
    total_length = length_a + length_b + length_c
    Geom::Point3d.new (length_a * point1.x + length_b * point2.x + length_c * point3.x) / total_length,
                      (length_a * point1.y + length_b * point2.y + length_c * point3.y) / total_length,
                      (length_a * point1.z + length_b * point2.z + length_c * point3.z) / total_length
  end
end