require 'src/models/ball_hub_model.rb'
require 'src/models/connector_model.rb'
require 'src/models/bottle_model.rb'
require 'src/models/actuator_model.rb'
require 'src/models/spring_model.rb'
require 'src/models/generic_link_model.rb'
require 'src/models/pod_model.rb'
require 'src/models/force_arrow_model.rb'
require 'src/models/weight_indicator_model.rb'
require 'src/models/sensor_model.rb'
require 'src/models/pid_model.rb'
require 'src/models/pipe_model.rb'

# Model Storage
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
      if Configuration::PIPE_MODE
        @models['hard'] = PipeModel.new('hard')
      else
        @models['hard'] = BottleModel.new('hard', bottle_specifications)
      end
    end

    if @models['actuator'].nil? || !@models['actuator'].valid?
      @models['actuator'] = ActuatorModel.new
    end

    if @models['generic'].nil? || !@models['generic'].valid?
      @models['generic'] = SpringModel.new
    end

    if @models['pid_controller'].nil? || !@models['pid_controller'].valid?
      @models['pid_controller'] = PIDModel.new
    end

    if @models['spring'].nil? || !@models['spring'].valid?
      @models['spring'] = GenericLinkModel.new
    end

    if @models['force_arrow'].nil? || !@models['force_arrow'].valid?
      @models['force_arrow'] = ForceArrowModel.new
    end

    if @models['weight_indicator'].nil? || !@models['weight_indicator'].valid?
      @models['weight_indicator'] = WeightIndicatorModel.new
    end

    if @models['sensor'].nil? || !@models['sensor'].valid?
      @models['sensor'] = SensorModel.new
    end
  end

  def bottle_specifications
    specifications = []
    puts 'Loaded files:'
    Dir.glob(ProjectHelper.component_directory + '/*.skp') do |model_file_path|
      # File scheme is '.../number-name-short_name-weight_in_grams.skp'
      file_name = File.basename(model_file_path, '.skp')
      next unless /^\d*-[^-]*-[^-]*-\d*\z/ =~ file_name
      puts file_name
      _, name, short_name, weight_in_grams = file_name.split('-')
      model = {}
      model[:PATH] = model_file_path
      model[:NAME] = name
      model[:SHORT_NAME] = short_name
      model[:WEIGHT] = weight_in_grams.to_f / 1000
      specifications.push model
    end
    specifications
  end
end
