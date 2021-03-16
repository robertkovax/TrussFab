#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require_relative 'animation_data_sample.rb'

SIMULATION_RUNNER_HOST = "http://#{Configuration::SIMULATION_SERVER_HOST}:#{Configuration::SIMULATION_SERVER_PORT}".freeze

class SimulationRunnerClient
  def self.update_model(json_string)
    p "server request: update_model"

    request = Sketchup::Http::Request.new("#{SIMULATION_RUNNER_HOST}/update_model", Sketchup::Http::POST)
    request.headers = {'Content-Type' => 'text/json'}
    request.body = json_string.to_s

    request.start do |request, response|
      puts "/update_model successful"
      json_response = JSON.parse(response.body)
      yield json_response
    end
  end

  def self.update_spring_constants(spring_constants)
    p "server request: update_spring_constants"
    patch_updated_data('update_spring_constants', JSON.pretty_generate(spring_constants))
  end

  def self.update_mounted_users(mounted_users)
    p "update_mounted_users"
    patch_updated_data('update_mounted_users', JSON.pretty_generate(mounted_users))
  end

  def self.update_mounted_users_excitement(excitement)
    p "update_mounted_users_excitement"
    p JSON.pretty_generate(excitement)
    patch_updated_data('update_mounted_users_excitement', JSON.pretty_generate(excitement))
  end

  def self.patch_updated_data(route, json_data)
    p "server request: patch_updated_data"
    uri = URI.parse("#{SIMULATION_RUNNER_HOST}/#{route}")
    header = {'Content-Type' => 'text/json'}

    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Patch.new(uri.request_uri, header)
    request.body = json_data

    http.request(request)
  end

  def self.get_user_stats(node_id)
    p "server request: get_user_stats"
    json_response_from_server("get_user_stats/#{node_id}", nil, 180)
  end

  def self.get_hub_time_series(force_vectors = nil)
    json_result = if force_vectors
                    json_response_from_server('get_hub_time_series_with_force_vector', JSON.pretty_generate(force_vectors))
                  else
                    json_response_from_server('get_hub_time_series')
                  end
    parse_data(json_result['data'])
  end

  def self.get_equilibrium
    # TODO implement
    p json_response_from_server('get_equilibrium')
  end

  def self.get_constant_for_constrained_angle
    p "server request: get_constant_for_constrained_angle"
    p json_response_from_server('get_constant_for_constrained_angle')
  end

  def self.optimize_spring_for_constrain
    p "server request: optimize_spring_for_constrain"
    p json_response_from_server('optimize/hitting_ground', nil, 360)
  end

  def self.bode_plot
    p "server request: bode_plot"
    json_response_from_server('linearize/bode_plot', nil, 180)
  end

  def self.get_preload_positions(joules, enabled_spring_ids)
    p "server request: get_preload_positions"
    formated_spring_ids = enabled_spring_ids.join(",")
    json_result = json_response_from_server('get_preloaded_positions', nil, 280, joules: joules, spring_ids: formated_spring_ids)
    p json_result
    data_sample = parse_data(json_result['data'])[0]
    p data_sample
    data_sample
  end

  private

  # @param [Integer] timeout in seconds
  def self.json_response_from_server(route, json_data = nil, timeout = 80, params = {})
    uri = URI.parse("#{SIMULATION_RUNNER_HOST}/#{route}")
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = timeout
    request = Net::HTTP::Get.new(uri.request_uri)
    request.body = json_data if json_data
    response = http.request(request)
    if response.code != "500"
      return JSON.parse(response.body)
    else
      return {}
    end

  end
end
