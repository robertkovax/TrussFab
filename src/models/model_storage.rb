require 'src/models/ball_hub_model.rb'
require 'src/models/connector_model.rb'
require 'src/models/bottle_model_factory.rb'
require 'src/models/actuator_model.rb'
require 'src/models/pod_model.rb'
require 'src/configuration/configuration.rb'

class ModelStorage
  include Singleton

  attr_reader :models

  def initialize
    @models = {}
    setup_models
  end

  private

  def setup_models
    components = Sketchup.active_model.definitions
    @models['ball_hub'] = components['Hub'].nil? ? BallHubModel.new : components['Hub']
    @models['connector'] = components['Connector'].nil? ? ConnectorModel.new : components['Connector']
    @models['pod'] = components['Pod'].nil? ? PodModel.new : components['Pod']
    @models['hard'] = BottleModelFactory.new(Configuration::SMALL_BOTTLE_LENGTH, Configuration::BIG_BOTTLE_LENGTH)
    @models['actuator'] = ActuatorModel.new
  end
end
