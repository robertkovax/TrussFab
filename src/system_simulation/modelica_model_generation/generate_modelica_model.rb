#!/usr/bin/env ruby
require 'json'
require 'erb'


# DOCS
# Aussumptions: n1 -> frame_a / n2 -> frame_b

# Phase 1: LOADING
file = File.read(ARGV[0])
json_model = JSON.parse(file)

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
  node[:fixed] = node.key?('pods') && node['pods'][0]['is_fixed']
}

edges.each { |edgeID, edge|
  n1 = nodes[edge['n1']]
  n2 = nodes[edge['n2']]

  # if node is fixed, the orientation should not be defined by the line force component
  # TODO document orientation behavior
  edge[:n1_orientation_fixed] = n1[:visited] && !n1[:fixed]
  edge[:n2_orientation_fixed] = n2[:visited] && !n2[:fixed]

  # store for correct orientation in modelica file
  if n1[:primary_edge].nil?
    n1[:primary_edge] = edge
  elsif n2[:primary_edge].nil?
    n2[:primary_edge] = edge
  end

  n1[:connecting_edges].append(edge)
  n2[:connecting_edges].append(edge)

  unless n1[:visited]
    n1[:visited] = true
  end

  unless n2[:visited]
    n2[:visited] = true
  end
}

# Phase 3 Modelica Component Generation
Modelica_LineForceWithMass = Struct.new(:name, :mass, :orientation_fixed_a, :orientation_fixed_b)
Modelica_Rod = Struct.new(:name, :length)
Modelica_Spring = Struct.new(:name, :c)
Modelica_Connection = Struct.new(:from, :to)
Modelica_Fixture = Struct.new(:name, :x, :y, :z)

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

def generate_mutlibody_connection(from_component_name, to_component_name)
  return Modelica_Connection.new("#{from_component_name}.frame_a", "#{to_component_name}.frame_b")
end

# Phase 3.1 Generate Main Components
edges.each { |edgeID, edge|
  edge_name = edge_to_modelica_name(edge)
  edge_component = Modelica_LineForceWithMass.new(edge_name, 1, edge[:n1_orientation_fixed], edge[:n2_orientation_fixed] )

  if edge['type'] == 'bottle_link'
    force_translator = Modelica_Rod.new(edge_name + "_rod", 1)
  elsif edge['type'] == 'actuator'
    force_translator = Modelica_Spring.new(edge_name + "_spring", 7000)
  end

  modelica_components.append(edge_component, force_translator)
  modelica_connections.append(*generate_force_connections(edge_component, force_translator))
}

# Phase 3.2 Generate links between components
nodes.each { |id, node|
  node[:connecting_edges].each { |edge|
      unless edge == node[:primary_edge]
        modelica_connections.append(
          generate_mutlibody_connection(
            edge_to_modelica_name(node[:primary_edge]),
            edge_to_modelica_name(edge)
          )
        )
      end
  }
}

# Phase 3.3 Generate Fixtures

nodes.each { |id, node|
  if node[:fixed]
    fixture_name = "node_#{id}_fixture"
    modelica_components.append(Modelica_Fixture.new(fixture_name, node['x'].to_f, node['y'].to_f, node['z'].to_f))
    # TODO fix correct orientation of edge
    modelica_connections.append(Modelica_Connection.new(fixture_name + ".frame_b", edge_to_modelica_name(node[:primary_edge]) + ".frame_a"))
  end
}


# Phase 4 Write out to modelica template
renderer = ERB.new(File.read(File.join(File.dirname(__FILE__), 'modelica_template.mo.erb')))
renderer.run
