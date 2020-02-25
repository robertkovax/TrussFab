#!/usr/bin/env ruby
require 'sinatra'
require './simulation_runner.rb'

set :port, 8080
set :environment, :production

sim = SimulationRunner.new

get '/get_period' do
  return_message = {'period' => sim.get_period()}
  return_message.to_json
end
