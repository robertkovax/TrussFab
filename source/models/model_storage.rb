require ProjectHelper.model_directory + '/ball_hub_model.rb'
require ProjectHelper.model_directory + '/connector_model.rb'
require ProjectHelper.model_directory + '/bottle_model.rb'

class ModelStorage
  include Singleton

  attr_reader :models

  def initialize
    @models = Hash.new
    setup_models
  end

  private
  def setup_models
    components = Sketchup.active_model.definitions
    @models['ball_hub'] = components['Hub'].nil? ? BallHubModel.new : components['Hub']
    @models['connector'] = components['Connector'].nil? ? ConnectorModel.new : components['Connector']
    @models['hard'] = BottleModel.new 'hard', Configuration::HARD_MODELS
  end
end