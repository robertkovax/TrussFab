require 'src/models/ball_hub_model.rb'
require 'src/models/connector_model.rb'
require 'src/models/bottle_model.rb'
require 'src/models/actuator_model.rb'
require 'src/models/pod_model.rb'

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
    @models['hard'] = BottleModel.new('hard', Configuration::HARD_MODELS)
    @models['actuator'] = ActuatorModel.new
  end
end
