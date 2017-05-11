require 'json'
require 'src/database/graph.rb'
require 'src/utility/geometry.rb'

module JsonImport
  def self.import(path, position)
    json_objects = load_json(path)
    return if json_objects.nil?
    nodes = build_nodes(json_objects, position)
    edges = build_edges(json_objects, nodes)
    create_surfaces(edges)
  end

  def self.import_at_triangle(path, snap_triangle)
    json_objects = load_json(path)
    return if json_objects.nil?
    nodes = build_nodes(json_objects, Geom::Point3d.new(0, 0, 0))
    standard_direction, points = json_triangle(json_objects, nodes) 
    snap_center = snap_triangle.center
    snap_direction = snap_triangle.normal_towards_user
    json_triangle_center = Geometry.triangle_incenter(*points)
    rotation1 = Geometry.rotation_transformation(standard_direction,
                                                snap_direction,
                                                json_triangle_center)
    translation = Geom::Transformation.new(snap_center - json_triangle_center)
    transformation = translation * rotation1 
    nodes.values.each do |node|
      puts(node.class)
      node.transform!(transformation)
    end
    edges = build_edges(json_objects, nodes)
    surfaces = create_surfaces(edges)
    # rotate around center to align points
    # change positions of json triangle to positions of snap triangle
    # create links
  end

  def self.load_json(path)
    file = File.open(path, 'r')
    json_string = file.read
    file.close
    JSON.parse(json_string)
  end

  def self.json_triangle(json_objects, nodes)  
    standard_direction = json_objects['standard_direction']
    points = json_objects['standard_surface'].map { |id| nodes[id] }
    vector1 = points[0].vector_to(points[1])
    vector2 = points[0].vector_to(points[2])
    standard_direction = vector1.cross(vector2)
    return standard_direction, points 
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
                  node == edge.second_node ||
                  Graph.instance.find_surface([edge.first_node, edge.second_node, node])
          next unless other_edge_node.partners_include?(node)
          surface = Graph.instance.create_surface(edge.first_node, edge.second_node, node)
          surfaces[surface.id] = surface
        end
      end
    end
    surfaces
  end

  def self.build_nodes(json_objects, position)
    first = true
    translation = Geom::Transformation.new
    nodes = {}
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
      nodes[node['id']] = point
    end
    nodes
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
      new_edge = Graph.instance.create_edge_from_points(first_node, second_node, model_name,
                                                        first_elongation_length, second_elongation_length, link_type: link_type)
      edges[edge['id']] = new_edge
    end
    edges
  end
end
