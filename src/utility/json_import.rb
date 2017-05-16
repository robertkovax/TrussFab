require 'json'
require 'src/database/graph.rb'
require 'src/utility/geometry.rb'

module JsonImport
  def self.at_position(path, position)
    json_objects = load_json(path)
    return if json_objects.nil?
    points = build_points(json_objects, position)
    edges = build_edges(json_objects, points)
    create_surfaces(edges)
  end

  def self.at_triangle(path, snap_triangle)
    json_objects = load_json(path)
    return if json_objects.nil?

    # retrieve points from json
    json_points = build_points(json_objects, Geom::Point3d.new(0, 0, 0))

    # get center and direction of the triangle to snap to from our graph
    # and the triangle to snap on from json

    # snap on triangle (from our graph)
    snap_direction = snap_triangle.normal_towards_user
    snap_center = snap_triangle.center


    # snap to triangle (from json)
    json_direction, json_triangle_points = json_triangle(json_objects, json_points)
    json_center = Geometry.triangle_incenter(*json_triangle_points)



    # move all json points to snap triangle
    translation = Geom::Transformation.new(snap_center - json_center)

    # rotate json points so that the snap triangle and json triangle are planar
    rotation1 = Geometry.rotation_transformation(json_direction,
                                                 snap_direction,
                                                 json_center)

    transformation = translation * rotation1

    # recompute json triangle points and center after transformation
    json_triangle_points.map! { |point| point.transform(transformation) }
    json_center = Geometry.triangle_incenter(*json_triangle_points)


    # get two corresponding vectors from snap and json triangle to align them
    ref_point_snap = snap_triangle.first_node.position
    ref_point_json = json_triangle_points.min_by { |point| ref_point_snap.distance(point) }

    vector_snap = snap_center.vector_to(ref_point_snap)
    vector_json = json_center.vector_to(ref_point_json)

    rotation_around_center = Geometry.rotation_transformation(vector_json,
                                                              vector_snap,
                                                              json_center)

    transformation = rotation_around_center * transformation

    json_points.values.each do |point|
      point.transform!(transformation)
    end

    json_triangle_ids = json_objects['standard_surface']

    snap_points = snap_triangle.nodes.map(&:position)

    json_triangle_ids.each do |id|
      # TODO: find corresponding points via construction
      json_points[id] = snap_points.min_by { |point| point.distance(json_points[id])}
    end


    edges = build_edges(json_objects, json_points)
    surfaces = create_surfaces(edges)
  end

  def self.load_json(path)
    file = File.open(path, 'r')
    json_string = file.read
    file.close
    JSON.parse(json_string)
  end


  def self.json_triangle(json_objects, nodes)
    points = json_objects['standard_surface'].map { |id| nodes[id] }
    vector1 = points[0].vector_to(points[1])
    vector2 = points[0].vector_to(points[2])
    standard_direction = vector1.cross(vector2)
    [standard_direction, points]
  end

  # create surfaces from partners
  # we look at both first_node and second_node, since surfaces with a missing link can occur
  def self.create_surfaces(edges)
    surfaces = {}
    edges.each_value do |edge|
      [edge.first_node, edge.second_node].each do |edge_node|
        edge_node.partners.each_value do |partner|
          node = partner[:node]
          other_edge_node =
            if edge.first_node == edge_node
              edge.second_node
            else
              edge.first_node
            end
          next if node == edge.first_node ||
                  node == edge.second_node
          next unless other_edge_node.partners_include?(node)
          surface = Graph.instance.create_surface(edge.first_node, edge.second_node, node)
          surfaces[surface.id] = surface
        end
      end
    end
    surfaces
  end

  def self.build_points(json_objects, position)
    first = true
    translation = Geom::Transformation.new
    points = {}
    json_objects['nodes'].each do |node|
      x = node['x'].to_f.mm
      y = node['y'].to_f.mm
      z = node['z'].to_f.mm
      point = Geom::Point3d.new(x, y, z)
      if first
        translation = point.vector_to(position)
        first = false
      end
      point.transform!(translation)
      points[node['id']] = point
    end
    points
  end

  def self.build_edges(json_objects, nodes)
    edges = {}
    json_objects['edges'].each do |edge|
      first_node = nodes[edge['n1']]
      second_node = nodes[edge['n2']]
      link_type = edge['type']
      model_name = edge['model'].nil? ? 'hard' : edge['model']
      first_elongation_length = edge['e1'].nil? ? 0 : edge['e1'].to_l
      second_elongation_length = edge['e2'].nil? ? 0 : edge['e2'].to_l
      new_edge = Graph.instance.create_edge_from_points(first_node, second_node,
                                                        model_name,
                                                        first_elongation_length,
                                                        second_elongation_length,
                                                        link_type: link_type)
      edges[edge['id']] = new_edge
    end
    edges
  end
end
