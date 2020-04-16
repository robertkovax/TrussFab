#!/usr/bin/env ruby
require 'json'
require 'erb'
require_relative 'modelica_configuration.rb'

Modelica_LineForceWithMass = Struct.new(:name, :mass, :orientation_fixed_a, :orientation_fixed_b)
Modelica_Rod = Struct.new(:name, :length, :static_constant)
Modelica_Spring = Struct.new(:name, :c, :length)
Modelica_Connection = Struct.new(:from, :to)
Modelica_Fixture = Struct.new(:name, :x, :y, :z)
Modelica_PointMass = Struct.new(:name, :mass, :is_user, :x_start, :y_start, :z_start)
Modelica_Force = Struct.new(:name)

# Generates a modelica model with a given truss fab geometry.
class ModelicaModelGenerator
  def self.sketchup_to_modelica_units(x)
    (x / 1000).round(10)
  end

  def self.euclidean_distance(vector1, vector2)
    sum = 0
    vector1.zip(vector2).each do |v1, v2|
      component = (v1 - v2)**2
      sum += component
    end
    Math.sqrt(sum)
  end

  def self.generate_modelica_file(json_string)
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

    # Phase 3.1 Generate Main Components
    edges.each { |edgeID, edge|
      edge[:name] = edge_to_modelica_name(edge)
      edge_mass = edge[:length] * ModelicaConfiguration::PIPE_WEIGHT_KG_PER_M
      edge_component = Modelica_LineForceWithMass.new(edge[:name], edge_mass, edge[:n1_orientation_fixed], edge[:n2_orientation_fixed] )

      force_translator = Modelica_Spring.new("#{edge[:name]}_spring", ModelicaConfiguration::STATIC_SPRING_CONSTANT, edge[:length])

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
    if ModelicaConfiguration::POINT_MASS_GENERATION_ENABLED
      nodes.select {|nodeId, node| not node[:fixed]}.each{ |nodeId, node|
        primary_edge_connection_direction = get_direction(node, node[:primary_edge])

        # get added mass placed by user from truss fab geometry
        mass = node['added_mass']
        is_user = false
        if json_model['mounted_users'] && json_model['mounted_users'][nodeId.to_s]
          is_user = true
          mass += json_model['mounted_users'][nodeId.to_s]
        end
        # add weight of node structure

        mass += ModelicaConfiguration::NODE_WEIGHT_KG

        # Generate PointMasses
        point_mass_component = Modelica_PointMass.new(identifier_for_node_id(nodeId), mass, is_user, *node[:pos])
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

    # Phase 3.4 Generate Force Handles to enable interaction with the structure
    nodes.each { |id, node|
      primary_edge_connection_direction = get_direction(node, node[:primary_edge])

      force = Modelica_Force.new("node_#{id}_force")
      modelica_components.push(force)
      modelica_connections.push(generate_mutlibody_connection(force, :b, node[:primary_edge], primary_edge_connection_direction))
    }


    # Phase 4 Write out to modelica template
    renderer = ERB.new(File.read(File.join(File.dirname(__FILE__), 'modelica_template.mo.erb')))

    b = binding
    b.local_variable_set(:modelica_components, modelica_components)
    b.local_variable_set(:modelica_connections, modelica_connections)
    renderer.result(b)

  end

  def self.edge_to_modelica_name(edge)
    identifier_for_edge(edge['n1'], edge['n2'])
  end

  def self.generate_force_connections(from_component, to_component)
    # in modelica there is the concept of a force 'connection'. In order to connect
    # to of those input and output have to be connected
    # TODO move this logic to ERB file
    return Modelica_Connection.new("#{from_component[:name]}.flange_a", "#{to_component[:name]}.flange_a"),
        Modelica_Connection.new("#{from_component[:name]}.flange_b", "#{to_component[:name]}.flange_b")
  end

  def self.direction_hash_to_char(direction)
    if direction == :a
      return 'a'
    elsif direction == :b
      return 'b'
    end
  end

  def self.generate_mutlibody_connection(from_component, from_direction, to_component, to_direction)
    return Modelica_Connection.new(
        "#{from_component[:name]}.frame_#{direction_hash_to_char(from_direction)}", "#{to_component[:name]}.frame_#{direction_hash_to_char(to_direction)}"
    )
  end

  def self.get_direction(node, edge)
    if edge['n1'] == node['id']
      return :a
    elsif edge['n2'] == node['id']
      return :b
    else
      raise "This edge is not connected to the input node."
    end
  end

  def self.identifier_for_edge(n1, n2)
    "edge_from_#{n1}_to_#{n2}"
  end

  def self.identifier_for_node_id(node_id)
    "node_#{node_id}"
  end
end
