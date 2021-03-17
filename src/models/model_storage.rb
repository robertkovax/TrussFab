require 'src/models/ball_hub_model.rb'
require 'src/models/connector_model.rb'
require 'src/models/bottle_model.rb'
require 'src/models/actuator_model.rb'
require 'src/models/generic_link_model.rb'
require 'src/models/pod_model.rb'
require 'src/models/force_arrow_model.rb'
require 'src/models/weight_indicator_model.rb'
require 'src/models/user_indicator_model.rb'
require 'src/models/sensor_model.rb'
require 'src/models/pid_model.rb'
require 'src/models/amplitude_handle_model'

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
      @models['hard'] = BottleModel.new('hard', bottle_specifications)
    end

    if @models['actuator'].nil? || !@models['actuator'].valid?
      @models['actuator'] = ActuatorModel.new
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

    if @models['amplitude_handle'].nil? || !@models['amplitude_handle'].valid?
      @models['amplitude_handle'] = AmplitudeHandleModel.new
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

  def attachable_users
    return @attachable_users unless @attachable_users.nil?

    @attachable_users = {}
    Dir.glob(ProjectHelper.component_directory + '/attachable_users/*.skp') do |model_file_path|
      # File scheme is '.../name-weight_in_kilograms.skp'
      # e.g.: '../child-100.skp' would have the name child with the weight of
      # 100 kg
      filename = File.basename(model_file_path)
      next unless /^[^-]*-\d*.skp\z/ =~ filename

      @attachable_users[filename] = UserIndicatorModel.new(filename: filename)
    end
    @attachable_users
  end
end
