require 'json'
require 'src/database/graph.rb'
require 'src/utility/geometry.rb'
require 'src/simulation/joints.rb'

module JsonImport
  class << self

    def at_position(path, position)
      json_objects = load_json(path)
      points = build_points(json_objects, position)
      edges = build_edges(json_objects, points)
      triangles = create_triangles(edges)
      add_joints(json_objects, edges) unless json_objects['joints'].nil?
      [triangles.values, edges.values]
    end

    def at_triangle(path, snap_triangle)
      json_objects = load_json(path)

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
      triangles = create_triangles(edges)
      add_joints(json_objects, edges) unless json_objects['joints'].nil?
      [triangles.values, edges.values]
    end

    def load_json(path)
      file = File.open(path, 'r')
      json_string = file.read
      file.close
      json_objects = JSON.parse(json_string)
      raise(ArgumentError, 'Json string invalid') if json_objects.nil?
      json_objects
    end

    def json_triangle(json_objects, nodes)
      points = json_objects['standard_surface'].map { |id| nodes[id] }
      vector1 = points[0].vector_to(points[1])
      vector2 = points[0].vector_to(points[2])
      standard_direction = vector1.cross(vector2)
      [standard_direction, points]
    end

    # create triangles from incidents
    # we look at both first_node and second_node, since triangles with a missing link can occur
    def create_triangles(edges)
      triangles = {}
      edges.values.each do |edge|
        edge.first_node.incidents.each do |first_incident|
          edge.second_node.incidents.each do |second_incident|
            next if first_incident == second_incident
            if first_incident.opposite(edge.first_node) == second_incident.opposite(edge.second_node)
              triangle = Graph.instance.create_surface(edge.first_node,
                                                      edge.second_node,
                                                      first_incident.opposite(edge.first_node))
              triangles[triangle.id] = triangle
            end
          end
        end
      end
      triangles
    end

    def build_points(json_objects, position)
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

    def build_edges(json_objects, nodes)
      edges = {}
      json_objects['edges'].each do |edge|
        first_node = nodes[edge['n1']]
        second_node = nodes[edge['n2']]
        link_type = edge['type'].nil? ? 'bottle_link' : edge['type']
        model_name = edge['model'].nil? ? 'hard' : edge['model']
        new_edge = Graph.instance.create_edge_from_points(first_node,
                                                          second_node,
                                                          model_name: model_name,
                                                          link_type: link_type)

        edges[edge['id']] = new_edge
      end
      edges
    end

    def add_joints(json_objects, edges)
      json_objects['joints'].each do |joint_json|
        edge = edges[joint_json['edge_id']]
        edge_json = json_objects['edges'].find { |json| json['id'] == joint_json['edge_id'] }
        node = if joint_json['node_id'] == edge_json['n1']
                 edge.first_node
               else
                 edge.second_node
               end

        rotation_edge = edges[joint_json['rotation_axis_id']]

        joint = case joint_json['type']
                when 'hinge'
                  ThingyHinge.new(node, edge, rotation_edge)
                else
                  raise "Unsupported joint type: #{joint_json['type']}"
                end
        if joint_json['node_id'] == edge_json['n1']
          edge.thingy.first_joint = joint
        else
          edge.thingy.second_joint = joint
        end
      end
    end
  end
end
