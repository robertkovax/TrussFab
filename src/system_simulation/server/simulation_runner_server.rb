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
  sim.update_spring_constants(JSON.parse(request.body.read)) if sim
  status 200
  body ''
end

patch '/update_mounted_users' do
  sim.update_mounted_users(JSON.parse(request.body.read)) if sim
  status 200
  body ''
end

patch '/update_mounted_users_excitement' do
  sim.update_mounted_users_excitement(JSON.parse(request.body.read)) if sim
  status 200
  body ''
end

get '/get_user_stats/:node_id' do
  return_message = sim.get_user_stats(params['node_id'])
  p return_message
  return_message.to_json
end

get '/get_hub_time_series' do
  return_message = { data: sim.get_hub_time_series([]) }
  return_message.to_json
end

get '/get_preloaded_positions' do
  return_message = { data: sim.get_preloaded_positions(params["joules"].to_f, params["spring_ids"].split(',')) }
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
  # TODO: combine both already supported optimization methods (hitting_ground and flipping) here
  return_message = sim.optimize_springs(:flipping)
  return_message.to_json
end

get '/get_constant_for_constrained_angle' do
  # We don't do that for now...
  return_message = { constant: sim.get_period.to_s }
  return_message.to_json
end

get  '/linearize/bode_plot' do
  linear_model = sim.linearize
  return_message = linear_model.bode_plot
  return_message.to_json
end
