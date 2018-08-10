require 'json'
require 'src/database/graph.rb'
require 'src/utility/geometry.rb'
require 'src/simulation/thingy_rotation.rb'

# imports object from JSON
module JsonImport
  class << self
    def distance_to_ground(json_objects)
      lowest_z = Float::INFINITY
      first_z = json_objects['nodes'][0]['z'].to_f.mm
      json_objects['nodes'].each do |node|
        z = node['z'].to_f.mm
        lowest_z = [lowest_z, z].min
      end
      first_z - lowest_z
    end

    def at_position(path, position)
      json_objects = load_json(path)
      points = build_points(json_objects,
                            position,
                            distance_to_ground(json_objects))
      edges, nodes = build_edges(json_objects, points)
      triangles = create_triangles(edges)
      add_joints(json_objects, edges, nodes) unless json_objects['joints'].nil?
      add_pods(json_objects, nodes)
      animation = json_objects['animation'].to_s
      [triangles.values, edges.values, animation]
    end

    def at_triangle(path, snap_triangle)
      json_objects = load_json(path)

      # retrieve points from json
      json_points = build_points(json_objects, Geom::Point3d.new(0, 0, 0), 0)

      # get center and direction of the triangle to snap to from our graph
      # and the triangle to snap on from json

      # snap on triangle (from our graph)
      snap_direction = snap_triangle.normal_towards_user
      snap_center = snap_triangle.center

      # snap to triangle (from json)
      json_direction, json_triangle_points = json_triangle(json_objects,
                                                           json_points)
      json_center = Geometry.triangle_incenter(*json_triangle_points)

      # move all json points to snap triangle
      translation = Geom::Transformation.new(snap_center - json_center)

      # rotate json points so that the snap triangle
      # and json triangle are planar
      rotation1 = Geometry.rotation_transformation(json_direction,
                                                   snap_direction,
                                                   json_center)

      transformation = translation * rotation1

      # recompute json triangle points and center after transformation
      json_triangle_points.map! { |point| point.transform(transformation) }
      json_center = Geometry.triangle_incenter(*json_triangle_points)

      # get two corresponding vectors from snap and json triangle to align them
      ref_point_snap = snap_triangle.first_node.position
      ref_point_json = json_triangle_points.min_by do |point|
        ref_point_snap.distance(point)
      end

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
        json_points[id] = snap_points.min_by do |point|
          point.distance(json_points[id])
        end
      end

      edges, nodes = build_edges(json_objects, json_points)
      triangles = create_triangles(edges)
      add_joints(json_objects, edges, nodes) unless json_objects['joints'].nil?
      animation = json_objects['animation'].to_s
      [triangles.values, edges.values, animation]
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
    # we look at both first_node and second_node, since triangles with a missing
    # link can occur
    def create_triangles(edges)
      triangles = {}
      edges.values.each do |edge|
        edge.first_node.incidents.each do |first_incident|
          edge.second_node.incidents.each do |second_incident|
            next if first_incident == second_incident ||
                    (first_incident.opposite(edge.first_node) !=
                    second_incident.opposite(edge.second_node))
            triangle = Graph.instance
                            .create_triangle(edge.first_node,
                                             edge.second_node,
                                             first_incident
                                            .opposite(edge.first_node))
            triangles[triangle.id] = triangle
          end
        end
      end
      triangles
    end

    def build_points(json_objects, position, z_height)
      first = true
      translation = Geom::Transformation.new
      points = {}
      json_objects['nodes'].each do |node|
        x = node['x'].to_f.mm
        y = node['y'].to_f.mm
        z = node['z'].to_f.mm
        point = Geom::Point3d.new(x, y, z)
        if first
          position.z = z_height + Configuration::BALL_HUB_RADIUS
          translation = point.vector_to(position)
          first = false
        end
        point.transform!(translation)
        points[node['id']] = point
      end
      points
    end

    def parse_elongation(elongation)
      # For backward compatibility with SU2016 JSON files
      if elongation.is_a?(String)
        elongation.sub!('~ ', '') if elongation.include?('~ ')
        elongation.to_f.mm
      # Sketchup 2017
      elsif elongation.is_a?(Numeric)
        elongation.mm
      else
        raise 'Unknown elongation specification during JSON import.'
      end
    end

    def build_edges(json_objects, positions)
      edges = {}
      nodes = {}
      json_objects['edges'].each do |edge_json|
        first_position = positions[edge_json['n1']]
        second_position = positions[edge_json['n2']]
        link_type = edge_json['type'].nil? ? 'bottle_link' : edge_json['type']

        # For backward compatibility with SU2016 JSON files
        link_type = 'bottle_link' if link_type == 'LinkTypes::BOTTLE_LINK'

        bottle_type = edge_json['bottle_type'].nil? ? '' : edge_json['bottle_type']
        edge = Graph.instance.create_edge_from_points(first_position,
                                                      second_position,
                                                      bottle_type: bottle_type,
                                                      link_type: link_type)

        # recreate elongation ratio
        unless edge_json['e1'].nil? || edge_json['e2'].nil?
          first_elongation_length = parse_elongation(edge_json['e1'])
          second_elongation_length = parse_elongation(edge_json['e2'])

          total_elongation_length =
            first_elongation_length + second_elongation_length
          edge.link.elongation_ratio =
            first_elongation_length / total_elongation_length
        end

        if edge.link.is_a?(ActuatorLink)
          piston_group = edge_json['piston_group']
          edge.link.piston_group = piston_group unless piston_group.nil?
        end
        edges[edge_json['id']] = edge
        nodes[edge_json['n1']] = edge.first_node
        nodes[edge_json['n2']] = edge.second_node
      end
      [edges, nodes]
    end

    def add_joints(json_objects, edges, nodes)
      json_objects['joints'].each do |joint_json|
        if !joint_json['rotation_axis_id'].nil?
          EdgeRotation.new(edges[joint_json['rotation_axis_id']])
        elsif !joint_json['rotation_plane_ids'].nil?
          plane_nodes = joint_json['rotation_plane_ids'].map { |id| nodes[id] }
          PlaneRotation.new(plane_nodes)
        else
          raise ArgumentError('No rotation vector given')
        end
      end
    end

    def string_to_vector3d(string)
      string.delete!('(')
      string.delete!(')')
      string_parts = string.split(', ')
      Geom::Vector3d.new(string_parts[0].to_f,
                         string_parts[1].to_f,
                         string_parts[2].to_f)
    end

    def add_pods(json_objects, nodes)
      json_objects['nodes'].each do |node_json|
        node = nodes[node_json['id']]
        next if node_json['pods'].nil? || node_json['pods'].empty?
        node_json['pods'].each do |pod_info|
          node.add_pod(string_to_vector3d(pod_info['direction']),
                       is_fixed: pod_info['is_fixed'])
        end
      end
    end
  end
end
