#!/usr/bin/env ruby
require 'sinatra'
require_relative './simulation_runner.rb'
require_relative './generate_modelica_model.rb'

set :port, 8080
set :environment, :production

sim = nil

post '/update_model' do
  sim = SimulationRunner.new_from_json_export(request.body.read)
  p sim
  return ''
end

patch '/update_spring_constants' do
  return if SimulationRunner.status != :ready

  sim.update_spring_constants(JSON.parse(request.body.read)) if sim
  return ''
end

patch '/update_mounted_users' do
  return if SimulationRunner.status != :ready

  sim.update_mounted_users(JSON.parse(request.body.read)) if sim
  return ''
end

get '/get_user_stats/:node_id' do
  return if SimulationRunner.status != :ready

  return_message = sim.get_user_stats(params['node_id'])
  return_message.to_json
end

get '/get_hub_time_series' do
  return if SimulationRunner.status != :ready

  return_message = { data: sim.get_hub_time_series([]) }
  return_message.to_json
end

get '/get_hub_time_series_with_force_vector' do
  return_message = { data: sim.get_hub_time_series(JSON.parse(request.body.read)) }
  return_message.to_json
end

get '/get_equilibrium' do
  return_message = { equilibrium: sim.get_period.to_s }
  return_message.to_json
end

get '/optimize/hitting_ground' do
  return_message = sim.optimize_springs(:hitting_ground)
  return_message.to_json
end

get '/get_constant_for_constrained_angle' do
  # We don't do that for now...
  return_message = { constant: sim.get_period.to_s }
  return_message.to_json
end
