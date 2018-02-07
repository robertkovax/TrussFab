class ThingyRotation
  def vector
    raise NotImplementedError
  end
end

class EdgeRotation < ThingyRotation
  def initialize(edge)
    @edge = edge
  end

  def vector
    @edge.direction
  end

  def edge
    @edge
  end
end

class PlaneRotation < ThingyRotation
  def initialize(plane_nodes)
    @plane_nodes = plane_nodes
  end

  def vector
    points = @plane_nodes.map(&:position)
    plane = Geom.fit_plane_to_points(points)
    Geom::Vector3d.new(plane[0..2])
  end
end