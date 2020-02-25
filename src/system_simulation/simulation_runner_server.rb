#!/usr/bin/env ruby
require 'sinatra'
require './simulation_runner.rb'
require "./generate_modelica_model.rb"

set :port, 8080
set :environment, :production

sim = nil

post '/update_model' do
  sim = SimulationRunner.new_from_json_export(request.body.read)
  return ""
end

get '/get_period' do
  return_message = {'period' => sim.get_period().to_s}
  return_message.to_json
end
