module Geometry
  X_AXIS = Geom::Vector3d.new(1, 0, 0)
  Y_AXIS = Geom::Vector3d.new(0, 1, 0)
  Z_AXIS = Geom::Vector3d.new(0, 0, 1)
  ORIGIN = Geom::Point3d.new(0, 0, 0)

  def self.rotation_angle_between(first_vector, second_vector)
    first_vector.angle_between(second_vector)
  end

  def self.perpendicular_rotation_axis(first_vector, second_vector)
    if first_vector.parallel?(second_vector)
      perpendicular_vector(first_vector)
    else
      first_vector.cross(second_vector)
    end
  end

  def self.perpendicular_vector(vector)
    Geom::Vector3d.new(vector.y - vector.z,
                       vector.z - vector.x,
                       vector.x - vector.y)
  end

  def self.triangle_incenter(first_point, second_point, third_point)
    length_a = first_point.distance(second_point)
    length_b = second_point.distance(third_point)
    length_c = third_point.distance(first_point)
    total_length = length_a + length_b + length_c
    x = (length_a * first_point.x + length_b * second_point.x + length_c * third_point.x) / total_length
    y = (length_a * first_point.y + length_b * second_point.y + length_c * third_point.y) / total_length
    z = (length_a * first_point.z + length_b * second_point.z + length_c * third_point.z) / total_length
    Geom::Point3d.new(x, y, z)
  end

  def self.intersect_three_spheres(first_center, second_center, third_center, first_radius, second_radius, third_radius)
    # https://en.wikipedia.org/wiki/Trilateration#Derivation
    # reverse the order of centers to get the opposite intersection

    d, i, j, ex, ey, ez = transform_to_local_coordiantes(first_center, second_center, third_center)
    # ex, ey, ez are local coordinates unit vectors
    # d, i, j are non-zero coordinates of local sphere centers
    # Now our spheres are defined as
    # r1² = x² + y² + z²
    # r2² = (x-d)² + y² + z²
    # r3² = (x-i)² + (y-j)² + z²
    # with d being the x coordinate of sphere B
    #     i and j being x and y coordinates of sphere C
    #     r_* being the radii
    # the intersection point (x,y,z) must satisfy all of these equations

    x = (first_radius * first_radius - second_radius * second_radius + d * d) / (2 * d)
    y = (first_radius * first_radius - third_radius * third_radius + i * i + j * j) / (2 * j) - x * i / j
    z_squared = first_radius * first_radius - x * x - y * y
    return nil if z_squared < 0 # no solution: three spheres don't intersect
    z = Math.sqrt(z_squared)

    first_center + scale(ex, x) + scale(ey, y) + scale(ez, z)
  end

  def self.transform_to_local_coordiantes(first_center, second_center, third_center)
    # https://en.wikipedia.org/wiki/Trilateration#Preliminary_and_final_computations
    # ex, ey, ez to be the local coordinates base unit vectors
    # d,i,j to be the non-zero coordinates of the three spheres
    ex = (second_center - first_center)
    ex.normalize!
    i = ex.dot(third_center - first_center)
    ey = third_center - first_center - scale(ex, i)
    ey.normalize!
    ez = ex * ey
    d = (second_center - first_center).length
    j = ey.dot(third_center - first_center)
    [d, i, j, ex, ey, ez]
  end

  def self.scale(vector, scalar)
    cloned_vector = vector.clone
    cloned_vector.length = cloned_vector.length * scalar
    cloned_vector
  end

  # http://geomalgorithms.com/a02-_lines.html
  def self.dist_point_to_segment(point, segment)
    s0, s1 = segment
    v = s1 - s0
    w = point - s0

    c1 = w.dot(v)
    return point.distance(s0) if c1 <= 0

    c2 = v.dot(v)
    return point.distance(s1) if c2 <= c1

    b = c1 / c2
    pb = s0 + scale(v, b)
    point.distance(pb)
  end
end
