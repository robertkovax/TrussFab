# Geometry-based helper functions
module Geometry
  X_AXIS = Geom::Vector3d.new(1, 0, 0)
  Y_AXIS = Geom::Vector3d.new(0, 1, 0)
  Z_AXIS = Geom::Vector3d.new(0, 0, 1)
  ORIGIN = Geom::Point3d.new(0, 0, 0)

  def self.rotation_angle_between(first_vector, second_vector)
    first_vector.angle_between(second_vector)
  end

  def self.sign(x)
    if x > 0
      1
    elsif x < 0
      -1
    else
      0
    end
  end

  def self.clamp(x, min, max)
    return min if x < min
    return max if x > max
    x
  end

  def self.angle_around_normal(first_vector, second_vector, normal)
    dot_prod = clamp(first_vector.normalize.dot(second_vector.normalize),
                     1.0,
                     1.0)
    angle = Math.acos(dot_prod)
    if normal.dot(first_vector.cross(second_vector)) < 0
      angle = 2 * Math::PI - angle
    end
    angle
  end

  def self.rotation_transformation(from_vector, to_vector, position)
    rotation_angle = Geometry.rotation_angle_between(from_vector,
                                                     to_vector)
    rotation_axis = Geometry.perpendicular_rotation_axis(from_vector,
                                                         to_vector)
    Geom::Transformation.rotation(position,
                                  rotation_axis,
                                  rotation_angle)
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
    x = (length_a * first_point.x +
      length_b * second_point.x +
      length_c * third_point.x) / total_length
    y = (length_a * first_point.y +
      length_b * second_point.y +
      length_c * third_point.y) / total_length
    z = (length_a * first_point.z +
      length_b * second_point.z +
      length_c * third_point.z) / total_length
    Geom::Point3d.new(x, y, z)
  end

  def self.intersect_three_spheres(first_center,
                                   second_center,
                                   third_center,
                                   first_radius,
                                   second_radius,
                                   third_radius)
    # https://en.wikipedia.org/wiki/Trilateration#Derivation
    # reverse the order of centers to get the opposite intersection

    d, i, j, ex, ey, ez = transform_to_local_coordiantes(first_center,
                                                         second_center,
                                                         third_center)
    # ex, ey, ez are local coordinates unit vectors
    # d, i, j are non-zero coordinates of local sphere centers
    # Now our spheres are defined as
    # r1^2 = x^2 + y^2 + z^2
    # r2^2 = (x-d)^2 + y^2 + z^2
    # r3^2 = (x-i)^2 + (y-j)^2 + z^2
    # with d being the x coordinate of sphere B
    #     i and j being x and y coordinates of sphere C
    #     r_* being the radii
    # the intersection point (x,y,z) must satisfy all of these equations

    x = (first_radius * first_radius -
      second_radius * second_radius + d * d) / (2 * d)
    y = (first_radius * first_radius -
      third_radius * third_radius + i * i + j * j) / (2 * j) - x * i / j
    z_squared = first_radius * first_radius - x * x - y * y
    return nil if z_squared < 0 # no solution: three spheres don't intersect
    z = Math.sqrt(z_squared)

    first_center + scale(ex, x) + scale(ey, y) + scale(ez, z)
  end

  def self.transform_to_local_coordiantes(first_center,
                                          second_center,
                                          third_center)
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
    if cloned_vector.length > 0
      cloned_vector.length = cloned_vector.length * scalar
    end
    cloned_vector
  end

  def self.scale_vector(vector, mag)
    Geom::Vector3d.new(vector.x * mag, vector.y * mag, vector.z * mag)
  end

  def self.blend_colors(colors, ratio)
    raise(TypeError, 'Expected at least two colors') if colors.size < 2
    ratio = ratio.to_f
    if ratio < 1.0e-6
      Sketchup::Color.new(colors.first)
    elsif ratio > 0.9999
      Sketchup::Color.new(colors.last)
    else
      cr = (colors.size - 1) * ratio
      i1 = cr.to_i
      i2 = i1 + 1
      i2 -= 1 if i2 == colors.size
      lr = cr - i1.to_f
      c1 = colors[i1]
      c2 = colors[i2]
      r = (c1.red + (c2.red - c1.red) * lr).to_i
      g = (c1.green + (c2.green - c1.green) * lr).to_i
      b = (c1.blue + (c2.blue - c1.blue) * lr).to_i
      a = (c1.alpha + (c2.alpha - c1.alpha) * lr).to_i
      Sketchup::Color.new(r, g, b, a)
    end
  end

  # http://geomalgorithms.com/a02-_lines.html
  def self.dist_point_to_segment(point, segment)
    return point.distance(closest_point_on_segment(point, segment))
  end

  # http://geomalgorithms.com/a02-_lines.html
  def self.closest_point_on_segment(point, segment)
    s0, s1 = segment
    v = s1 - s0
    w = point - s0

    c1 = w.dot(v)
    return s0 if c1 <= 0

    c2 = v.dot(v)
    return s1 if c2 <= c1

    b = c1 / c2
    pb = s0 + scale(v, b)
    return pb
  end

  # http://geomalgorithms.com/a02-_lines.html
  def self.closest_point_on_segment_with_fraction(point, segment)
    s0, s1 = segment
    v = s1 - s0
    w = point - s0

    c1 = w.dot(v)
    return s0, 0 if c1 <= 0

    c2 = v.dot(v)
    return s1, 1 if c2 <= c1

    b = c1 / c2
    pb = s0 + scale(v, b)
    return pb, b
  end

  # Return the position of the given point on the curve in the form
  # start_segment_index + percentage of the 'starting' segment
  def self.point_on_curve_index_position(point, curve)
    closest_distance = Float::INFINITY
    segment_start_index = nil
    fraction = nil
    index = 0
    curve.each_cons(2) do |segment_start, segment_end|
      dist = Geometry::dist_point_to_segment(point, [segment_start, segment_end])
      if dist < closest_distance
        segment_start_index = index
        closest_distance = dist
        closest_point, fraction =
          Geometry::closest_point_on_segment_with_fraction(point, [segment_start , segment_end])
      end
      index += 1
    end
    if fraction == 1
      segment_start_index += 1
      fraction = 0
    end
    puts "Index_position: #{segment_start_index + fraction}"
    segment_start_index + fraction
  end

  def self.position_from_curve_index(curve, index)
    i = index.floor
    fraction = index.modulo(1)
    return curve[i] if fraction == 0

    curve[i] + scale(curve[i+1] - curve[i], fraction)
  end

  def self.move_point_along_curve(point, distance, curve)
    # WLOG make distance positive
    if distance < 0
      return move_point_along_curve(point, -distance, curve.reverse)
    elsif distance == 0
      return point
    end

    distance_to_go = distance
    index_position = point_on_curve_index_position(point, curve)
    position_on_curve = position_from_curve_index(curve, index_position)
    puts "distance: #{distance}, index_position: #{index_position}, position_on_curve: #{position_on_curve}"
    puts "curve.length: #{curve.length}"

    current_index = index_position.floor + 1
    if (position_on_curve - curve[current_index]).length > distance
      direction = (curve[current_index] - curve[current_index + 1])
      direction.length = distance
      return point + direction
    end

    distance_to_go -= (position_on_curve - curve[current_index]).length
    while true
      current_index += 1
      if curve.length >= current_index
        puts "EDGE_CASE_2"
        return curve[curve.length - 1]
      end
      next_segment_length = (curve[current_index] - curve[current_index - 1]).length
      if next_segment_length > distance_to_go
        distance_to_go -= next_segment_length
      else
        direction = curve[current_index] - curve[current_index - 1]
        direction.length = distance_to_go
        return curve[current_index] + direction
      end
    end
  end

  # Given two points laying on a segment curve
  # return the distance of both curves along that curve
  def self.distance_on_curve(point1, point2, curve)
    multiplicator = 1
    point1_index = point_on_curve_index_position(point1, curve)
    point2_index = point_on_curve_index_position(point2, curve)

    points_on_same_segment = point1_index.floor == point2_index.floor
    if points_on_same_segment
      return (point1 - point2).length
    end

    if point1_index > point2_index
      point1_index, point2_index = point2_index, point1_index
      multiplicator = -1
    end

    # Distances to the segments start / end
    distance =
      (point1 - curve[point1_index.floor + 1]).length
      + (point2 - curve[point2_index.floor]).length

    # Distances over the segments
    ((point1_index.floor + 1)...point2_index.floor).each do |index|
      distance += (curve[index] - curve[index + 1]).length
    end
    distance * multiplicator
  end

  def self.midpoint(point1, point2)
    Geom::Point3d.new((point1.x + point2.x) / 2,
                      (point1.y + point2.y) / 2,
                      (point1.z + point2.z) / 2)
  end

  # Given two non-collinear vectors, this creates the rotation matrix for these
  # vectors.
  def self.rotation_to_local_coordinate_system(first_vector, second_vector)
    third_vector = first_vector.cross(second_vector).normalize!

    # There seems to be a bug in Sketchup with using the .axes method
    # see https://forums.sketchup.com/t/skew-transformation-inverse-issue-when-constructed-with-axes-method/49766/3
    Geom::Transformation.new([
                               first_vector.x, first_vector.y, first_vector.z, 0,
                               second_vector.x, second_vector.y, second_vector.z, 0,
                               third_vector.x, third_vector.y, third_vector.z, 0,
                               0, 0, 0, 1
                             ])
  end
end

