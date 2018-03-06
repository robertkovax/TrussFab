require 'src/models/ball_hub_model.rb'
require 'src/models/connector_model.rb'
require 'src/models/bottle_model.rb'
require 'src/models/actuator_model.rb'
require 'src/models/spring_model.rb'
require 'src/models/generic_link_model.rb'
require 'src/models/pod_model.rb'
require 'src/models/force_arrow_model.rb'
require 'src/models/sensor_model.rb'

class ModelStorage
  include Singleton

  attr_reader :models

  def initialize
    @models = {}
  end

  def setup_models
    if @models['ball_hub'].nil? || !@models['ball_hub'].valid?
      @models['ball_hub'] = BallHubModel.new
    end

    if @models['connector'].nil? || !@models['connector'].valid?
      @models['connector'] = ConnectorModel.new
    end

    if @models['pod'].nil? || !@models['pod'].valid?
      @models['pod'] = PodModel.new
    end

    if @models['hard'].nil? || !@models['hard'].valid?
      @models['hard'] = BottleModel.new('hard', Configuration::HARD_MODELS)
    end

    if @models['actuator'].nil? || !@models['actuator'].valid?
      @models['actuator'] = ActuatorModel.new
    end

    if @models['generic'].nil? || !@models['generic'].valid?
      @models['generic'] = SpringModel.new
    end

    if @models['spring'].nil? || !@models['spring'].valid?
      @models['spring'] = GenericLinkModel.new
    end

    if @models['force_arrow'].nil? || !@models['force_arrow'].valid?
      @models['force_arrow'] = ForceArrowModel.new
    end

    if @models['sensor'].nil? || !@models['sensor'].valid?
      @models['sensor'] = SensorModel.new
    end
  end
end
