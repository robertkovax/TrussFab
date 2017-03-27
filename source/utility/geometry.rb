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
end