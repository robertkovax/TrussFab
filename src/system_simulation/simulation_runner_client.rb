#!/usr/bin/env ruby

require 'net/http'
require "uri"


SIMULATION_RUNNER_HOST = "http://172.16.78.199:8080"

class SimulationRunnerClient
  def self.update_model(json_string)
    uri = URI.parse("#{SIMULATION_RUNNER_HOST}/update_model")
    header = {'Content-Type' => 'text/json'}

    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = json_string.to_s

    response = http.request(request)
    p response
  end

  def self.get_period
    uri = URI.parse("#{SIMULATION_RUNNER_HOST}/get_period")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    p response
  end

end
