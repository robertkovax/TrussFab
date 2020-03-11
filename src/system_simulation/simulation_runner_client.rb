#!/usr/bin/env ruby

require 'net/http'
require "uri"
require_relative 'animation_data_sample.rb'

SIMULATION_RUNNER_HOST = "http://0.0.0.0:8080".freeze

class SimulationRunnerClient
  def self.update_model(json_string)
    uri = URI.parse("#{SIMULATION_RUNNER_HOST}/update_model")
    header = {'Content-Type' => 'text/json'}

    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = json_string.to_s

    response = http.request(request)
  end

  def self.update_spring_constants(spring_constants)
    patch_updated_data('update_spring_constants', JSON.pretty_generate(spring_constants))
  end

  def self.update_mounted_users(mounted_users)
    patch_updated_data('update_mounted_users', JSON.pretty_generate(mounted_users))
  end

  def self.patch_updated_data(route, json_data)
    uri = URI.parse("#{SIMULATION_RUNNER_HOST}/#{route}")
    header = {'Content-Type' => 'text/json'}

    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Patch.new(uri.request_uri, header)
    request.body = json_data

    response = http.request(request)
  end

  def self.get_period(node_id)
    json_response_from_server("get_period/#{node_id}")['period']
  end

  def self.get_hub_time_series
    json_result = json_response_from_server('get_hub_time_series')
    parse_data(json_result["data"])
  end

  def self.get_equilibrium
    # TODO implement
    p json_response_from_server('get_equilibrium')
  end

  def self.get_constant_for_constrained_angle
    # TODO implement
    p json_response_from_server('get_constant_for_constrained_angle')
  end

  private

  def self.json_response_from_server(route)
    uri = URI.parse("#{SIMULATION_RUNNER_HOST}/#{route}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    JSON.parse(response.body)
  end

  # Parses data retrieved from a csv, must contain header at the first index.
  def self.parse_data(data_array)
    # parse in which columns the coordinates for each node are stored
    indices_map = AnimationDataSample.indices_map_from_header(data_array[0])

    # remove header of loaded data
    data_array.shift

    # parse csv
    data_samples = []
    data_array.each do |value|
      data_samples << AnimationDataSample.from_raw_data(value, indices_map)
    end

    data_samples

  end

  def self.spring_data_from_graph
    constants_for_springs = {}
    spring_links = Graph.instance.edges.values
                       .select { |edge| edge.link_type == 'spring' }
                       .map(&:link)
    spring_links.each do |link|
      constants_for_springs[link.edge.id] = link.spring_parameter_k
    end
    constants_for_springs
  end

end
