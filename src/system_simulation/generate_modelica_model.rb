#!/usr/bin/env ruby
require 'json'
require 'erb'

NODE_WEIGHT_KG = 30
PIPE_WEIGHT_KG = 1
SPRING_CONSTANT = 7000
POINT_MASS_GENERATION_ENABLED = true

Modelica_LineForceWithMass = Struct.new(:name, :mass, :orientation_fixed_a, :orientation_fixed_b)
Modelica_Rod = Struct.new(:name, :length)
Modelica_Spring = Struct.new(:name, :c, :length)
Modelica_Connection = Struct.new(:from, :to)
Modelica_Fixture = Struct.new(:name, :x, :y, :z)
Modelica_PointMass = Struct.new(:name, :mass, :x_start, :y_start, :z_start)

def sketchup_to_modelica_units(x)
  (x / 1000).round(10)
end

def euclidean_distance(vector1, vector2)
  sum = 0
  vector1.zip(vector2).each do |v1, v2|
    component = (v1 - v2)**2
    sum += component
  end
  Math.sqrt(sum)
end

def generate_modelica_file(json_string)
  # Phase 1: LOADING
  json_model = JSON.parse(json_string)

  # Phase 2: Preprocessing
  nodes = json_model['nodes']
  edges = json_model['edges']

  # TODO no longer assume that nodes are already sorted by their id
  nodes = nodes.map { |node| [node['id'], node] }.to_h
  edges = edges.map { |edge| [edge['id'], edge] }.to_h

  nodes.each { |key, node|
    node[:visited] = false
    node[:primary_edge] = nil
    node[:connecting_edges] = Array.new
    node[:fixed] = node.key?('pods') && node['pods'].any? && node['pods'][0]['is_fixed']
    node[:pos] = [node['x'], node['y'], node['z']].map {|x| sketchup_to_modelica_units(x) }
  }


  # Delete all edges that are in between fixed nodes and don't contribute to the simulation
  edges.delete_if { |edgeID, edge|
    nodes[edge['n1']][:fixed] && nodes[edge['n2']][:fixed]
  }

  edges.each { |edgeID, edge|
    n1 = nodes[edge['n1']]
    n2 = nodes[edge['n2']]

    edge[:length] = euclidean_distance(n1[:pos], n2[:pos])

    n1[:connecting_edges].push(edge)
    n2[:connecting_edges].push(edge)

    edge[:n1_orientation_fixed] = false
    edge[:n2_orientation_fixed] = false
  }

  nodes.each { |nodeId, node|
    node[:primary_edge] = node[:connecting_edges][0]

    if not node[:fixed]
      if node[:primary_edge]['n1'] == nodeId
        node[:primary_edge][:n1_orientation_fixed] = true
      else node[:primary_edge]['n2'] == nodeId
        node[:primary_edge][:n2_orientation_fixed] = true
      end
    end
  }

  # Phase 3 Modelica Component Generation
  modelica_components = Array.new
  modelica_connections = Array.new

  def edge_to_modelica_name(edge)
    return edge_ids_to_modelica_name(edge['n1'], edge['n2'])
  end

  def edge_ids_to_modelica_name(n1, n2)
    return "edge_from_#{n1}_to_#{n2}"
  end

  def generate_force_connections(from_component, to_component)
    # in modelica there is the concept of a force 'connection'. In order to connect
    # to of those input and output have to be connected
    # TODO move this logic to ERB file
    return Modelica_Connection.new("#{from_component[:name]}.flange_a", "#{to_component[:name]}.flange_a"),
           Modelica_Connection.new("#{from_component[:name]}.flange_b", "#{to_component[:name]}.flange_b")
  end

  def direction_hash_to_char(direction)
    if direction == :a
      return 'a'
    elsif direction == :b
      return 'b'
    end
  end

  def generate_mutlibody_connection(from_component, from_direction, to_component, to_direction)
    return Modelica_Connection.new(
      "#{from_component[:name]}.frame_#{direction_hash_to_char(from_direction)}", "#{to_component[:name]}.frame_#{direction_hash_to_char(to_direction)}"
    )
  end

  def get_direction(node, edge)
    if edge['n1'] == node['id']
      return :a
    elsif edge['n2'] == node['id']
      return :b
    else
      raise "This edge is not connected to the input node."
    end
  end

  # Phase 3.1 Generate Main Components
  edges.each { |edgeID, edge|
    edge[:name] = edge_to_modelica_name(edge)
    edge_component = Modelica_LineForceWithMass.new(edge[:name], PIPE_WEIGHT_KG, edge[:n1_orientation_fixed], edge[:n2_orientation_fixed] )

    if edge['type'] == 'bottle_link'
      force_translator = Modelica_Rod.new(edge[:name] + "_rod", edge[:length].to_f)
    elsif edge['type'] == 'spring'
      force_translator = Modelica_Spring.new(edge[:name] + "_spring", SPRING_CONSTANT, edge[:length])
    end

    # store for constructing connections
    edge[:modelica_component] = edge_component

    modelica_components.push(edge_component, force_translator)
    modelica_connections.push(*generate_force_connections(edge_component, force_translator))
  }


  # Phase 3.2 Generate links between components
  nodes.each { |nodeId, node|
    primary_edge_connection_direction = get_direction(node, node[:primary_edge])
    # Connect all rods
    node[:connecting_edges].each { |edge|
      unless edge == node[:primary_edge]
        modelica_connections.push(
          generate_mutlibody_connection(
            node[:primary_edge][:modelica_component], primary_edge_connection_direction,
            edge[:modelica_component], get_direction(node, edge)
          )
        )
      end
    }
  }

  # Phase 3.3 Generate Point Masses on all nodes
  if POINT_MASS_GENERATION_ENABLED
    nodes.select {|nodeId, node| not node[:fixed]}.each{ |nodeId, node|
      primary_edge_connection_direction = get_direction(node, node[:primary_edge])

      # get mass from truss fab geometry if set
      mass = json_model['mounted_users'][nodeId.to_s]
      # fall back to default mass otherwise
      mass ||= NODE_WEIGHT_KG

      # Generate PointMasses
      point_mass_component = Modelica_PointMass.new("node_#{nodeId}", mass, *node[:pos])
      modelica_components.push(point_mass_component)
      modelica_connections.push(generate_mutlibody_connection(node[:primary_edge], primary_edge_connection_direction, point_mass_component, :a))
    }
  end

  # Phase 3.3 Generate Fixtures
  nodes.select{|id, node| node[:fixed]}.each { |id, node|
    primary_edge_connection_direction = get_direction(node, node[:primary_edge])

    fixture = Modelica_Fixture.new("node_#{id}_fixture", *node[:pos])
    modelica_components.push(fixture)
    modelica_connections.push(generate_mutlibody_connection(fixture, :b, node[:primary_edge], primary_edge_connection_direction))
  }


  # Phase 4 Write out to modelica template
  renderer = ERB.new(File.read(File.join(File.dirname(__FILE__), 'modelica_template.mo.erb')))

  b = binding
  b.local_variable_set(:modelica_components, modelica_components)
  b.local_variable_set(:modelica_connections, modelica_connections)
  renderer.result(b)

end
