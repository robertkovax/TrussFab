# @since 3.3.0
module AMS::Geometry
  class << self

    # Scale vector.
    # @param [Array<Numeric>, Geom::Vector3d] vector
    # @param [Numeric] scale
    # @return [Geom::Vector3d]
    # @since 3.5.0
    def scale_vector(vector, scale)
    end

    # Rotate vector at a normal.
    # @param [Geom::Vector3d] vector The vector to rotate.
    # @param [Geom::Vector3d] normal The normal to rotate against.
    # @param [Numeric] angle The angle to rotate in radians.
    # @return [Geom::Vector3d] The rotated vector.
    # @since 3.5.0
    def rotate_vector(vector, normal, angle)
    end

    # @overload angle_between_vectors(vector1, vector2)
    #   Compute angle between two vectors.
    #   @param [Geom::Vector3d] vector1
    #   @param [Geom::Vector3d] vector2
    # @overload angle_between_vectors(vector1, vector2, normal)
    #   Compute angle between two vectors at a normal.
    #   @param [Geom::Vector3d] vector1
    #   @param [Geom::Vector3d] vector2
    #   @param [Geom::Vector3d] normal The normal to compute against.
    # @return [Numeric] The angle in radians.
    # @since 3.5.0
    def angle_between_vectors(*args)
    end

    # Get an array of unique points from an array of Point3d objects.
    # @param [Array<Geom::Point3d>] points
    # @return [Array<Geom::Point3d>]
    def get_unique_points(points)
    end

    # Determine whether an array of points lie on the same line.
    # @param [Array<Geom::Point3d>] points
    # @return [Boolean]
    def points_collinear?(points)
    end

    # Get three non-collinear points from an array of three or more points.
    # @param [Array<Geom::Point3d>] points
    # @return [Array<Geom::Point3d>, nil] An array of three non-collinear
    #   points if successful.
    def get_noncollinear_points(points)
    end

    # Get plane normal.
    # @param [Array<Geom::Point3d>] plane An array of
    #   three, non-collinear points on the plane.
    # @return [Geom::Vector3d]
    def get_plane_normal(plane)
    end

    # Determine whether an array of points lie on the same plane.
    # @param [Array<Geom::Point3d>] points
    # @return [Boolean]
    def points_coplanar?(points)
    end

    # Sort an array of points in a counter clockwise direction.
    # @param [Array<Geom::Point3d>] points
    # @return [Array<Geom::Point3d>, nil] An array of sorted points if
    #   successful.
    def sort_polygon_points(points)
    end

    # Calculate edge centre of mass.
    # @param [Sketchup::Edge] edge
    # @return [Geom::Point3d]
    def calc_edge_centre(edge)
    end

    # Calculate face centre of mass.
    # @param [Sketchup::Face] face
    # @return [Geom::Point3d]
    def calc_face_centre(face)
    end

    # Determine whether a particular point in on edge.
    # @param [Geom::Point3d] point
    # @param [Sketchup::Edge] edge
    # @return [Boolean]
    def is_point_on_edge?(point, edge)
    end

    # Determine whether a particular point is on face.
    # @param [Geom::Point3d] point
    # @param [Sketchup::Face] face
    # @return [Boolean]
    def is_point_on_face?(point, face)
    end

    # Determine whether a particular point is on triangle.
    # @param [Geom::Point3d] point The point to test.
    # @param [Geom::Point3d] pt1 The first vertex of the triangle.
    # @param [Geom::Point3d] pt2 The second vertex of the triangle.
    # @param [Geom::Point3d] pt3 The third vertex of the triangle.
    # @return [Boolean]
    def is_point_on_triangle?(point, pt1, pt2, pt3)
    end

    # Intersect ray with a triangle.
    # @param [Geom::Point3d] origin The origin of the ray.
    # @param [Geom::Vector3d] direction The direction of the ray.
    # @param [Geom::Point3d] pt1 The first vertex of the triangle.
    # @param [Geom::Point3d] pt2 The second vertex of the triangle.
    # @param [Geom::Point3d] pt3 The third vertex of the triangle.
    # @return [Geom::Point3d, nil]
    # @see Source http://www.cs.virginia.edu/~gfx/Courses/2003/ImageSynthesis/papers/Acceleration/Fast%20MinimumStorage%20RayTriangle%20Intersection.pdf
    def intersect_ray_triangle(origin, direction, pt1, pt2, pt3)
    end

    # Get the scale of axes of a transformation matrix.
    # @param [Geom::Transformation, Array<Numeric>] transformation
    # @return [Geom::Vector3d] A vector representing the scale ratios of the
    #   X-axis, Y-axis, and Z-axis.
    def get_matrix_scale(transformation)
    end

    # Set the scale of axes of a transformation matrix.
    # @param [Geom::Transformation, Array<Numeric>] transformation
    # @param [Geom::Vector3d, Array<Numeric>] scale An array of three numeric
    #   values, representing the scale ratios of the X-axis, Y-axis, and Z-axis.
    # @return [Geom::Transformation] A new, scaled transformation matrix.
    def set_matrix_scale(transformation, scale)
    end

    # Normalize the scale of axes of a transformation matrix.
    # @param [Geom::Transformation, Array<Numeric>] transformation
    # @return [Geom::Transformation] A new, normalize transformation matrix.
    def extract_matrix_scale(transformation)
    end

    # Determine whether a transformation matrix is flipped.
    # @param [Geom::Transformation, Array<Numeric>] transformation
    # @return [Boolean]
    def is_matrix_flipped?(transformation)
    end

    # Determine whether a transformation matrix is uniform. A uniform
    # transformation matrix has its axes perpendicular to each other.
    # @param [Geom::Transformation, Array<Numeric>] transformation
    # @return [Boolean]
    def is_matrix_uniform?(transformation)
    end

    # Rotate a transformation matrix so that its Z-axis aligns with a directing
    # vector.
    # @param [Geom::Transformation] transformation
    # @param [Geom::Vector] direction
    # @return [Geom::Transformation]
    # @since 3.5.0
    def rotate_matrix_zaxis_to_dir(transformation, direction)
    end

    # Transition between two cameras.
    # @param [Sketchup::Camera] camera1
    # @param [Sketchup::Camera] camera2
    # @param [Numeric] ratio A value between 0.0 and 1.0.
    # @return [Sketchup::Camera]
    def transition_camera(camera1, camera2, ratio)
    end

    # Transition between two colors.
    # @param [Sketchup::Color] color1
    # @param [Sketchup::Color] color2
    # @param [Numeric] ratio A value between 0.0 and 1.0.
    # @return [Sketchup::Color]
    def transition_color(color1, color2, ratio)
    end

    # Transition between two points.
    # @param [Geom::Point3d] point1
    # @param [Geom::Point3d] point2
    # @param [Numeric] ratio A value, not necessarily
    #   between 0.0 and 1.0.
    # @return [Geom::Point3d]
    def transition_point(point1, point2, ratio)
    end

    # Transition between two vectors.
    # @note Unlike the {transition_point} function, this function rotates and
    #   scales vector1 to vector2 a specific ratio.
    # @param [Geom::Vector3d] vector1
    # @param [Geom::Vector3d] vector2
    # @param [Numeric] ratio A value, not necessarily
    #   between 0.0 and 1.0.
    # @return [Geom::Vector3d]
    def transition_vector(vector1, vector2, ratio)
    end

    # Transition between two transformation matrices.
    # @note For the function to work properly, both transformation matrices must
    #   be uniform and non-flipped. They can, however, since version 3.5.0, have
    #   scaled axes.
    # @param [Geom::Transformation] transformation1
    # @param [Geom::Transformation] transformation2
    # @param [Numeric] ratio A value, not necessarily
    #   between 0.0 and 1.0.
    # @return [Geom::Transformation]
    def transition_transformation(transformation1, transformation2, ratio)
    end

    # Transition between two numbers.
    # @param [Numeric] number1
    # @param [Numeric] number2
     # @param [Numeric] ratio A value, not necessarily
    #   between 0.0 and 1.0.
    # @return [Numeric]
    def transition_number(number1, number2, ratio)
    end

    # Transition between multiple colors.
    # @param [Array<Sketchup::Color, String, Array>] colors An array of colors
    #   to transition between.
    # @param [Numeric] ratio A value between 0.0 and 1.0.
    # @return [Sketchup::Color]
    # @since 3.5.0
    def blend_colors(colors, ratio)
    end

    # Get points of a two dimensional circle.
    # @param [Array<Numeric>] origin
    # @param [Numeric] radius
    # @param [Fixnum] num_seg Number of segments.
    # @param [Numeric] rot_angle Rotate angle in radians.
    # @return [Array<Geom::Point3d>] An array of points making up the circle.
    # @since 3.5.0
    def get_points_on_circle2d(origin, radius, num_seg = 16, rot_angle = 0.0)
    end

    # Get points of a three dimensional circle.
    # @param [Array<Numeric>, Geom::Point3d] origin
    # @param [Array<Numeric>, Geom::Vector3d] normal
    # @param [Numeric] radius
    # @param [Fixnum] num_seg Number of segments.
    # @param [Numeric] rot_angle Rotate angle in radians.
    # @return [Array<Geom::Point3d>] An array of points making up the circle.
    # @since 3.5.0
    def get_points_on_circle3d(origin, normal, radius, num_seg = 16, rot_angle = 0)
    end

    # Cast a ray through the model that intersects with the given entities only.
    # @param [Array<Sketchup::Drawingelement>] entities An array of entities to
    #   include.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array, nil] A ray result.
    # @see http://ruby.sketchup.com/Sketchup/Model.html#raytest-instance_method
    # @since 3.5.0
    def raytest1(entities, point, vector, chg = false)
    end

    # Cast a ray through the model that intersects with all but the given
    # entities.
    # @param [Array<Sketchup::Drawingelement>] entities An array of entities to
    #   ignore.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array, nil] A ray result.
    # @see http://ruby.sketchup.com/Sketchup/Model.html#raytest-instance_method
    # @since 3.5.0
    def raytest2(entities, point, vector, chg = false)
    end

    # Cast a ray that intersects with non-transparent faces only; a ray that
    # passes through all the transparent faces and stops when hits a solid face.
    # @note A face is considered transparent if front or back side, depending on
    #   which the ray hits, has a material with alpha less than 255.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array, nil] A ray result.
    # @see http://ruby.sketchup.com/Sketchup/Model.html#raytest-instance_method
    # @since 3.5.0
    def raytest3(point, vector, chg = false)
    end

    # Cast a continuous ray that intersects with all the entities.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array<Array>] An array of ray results.
    # @see http://ruby.sketchup.com/Sketchup/Model.html#raytest-instance_method
    # @since 3.5.0
    def deepray1(point, vector, chg = false)
    end

    # Cast a continuous ray that intersects with the given entities only.
    # @param [Array<Sketchup::Drawingelement>] entities An array of entities to
    #   include.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array<Array>] An array of ray results.
    # @see http://ruby.sketchup.com/Sketchup/Model.html#raytest-instance_method
    # @since 3.5.0
    def deepray2(entities, point, vector, chg = false)
    end

    # Cast a continuous ray that intersects with all but the given entities.
    # @param [Array<Sketchup::Drawingelement>] entities An array of entities to
    #   ignore.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array<Array>] An array of ray results.
    # @see http://ruby.sketchup.com/Sketchup/Model.html#raytest-instance_method
    # @since 3.5.0
    def deepray3(entities, point, vector, chg = false)
    end

  end # class << self
end # module AMS::Geometry
