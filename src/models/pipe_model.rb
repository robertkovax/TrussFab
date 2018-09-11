require 'src/models/pipe.rb'

class PipeModel
  attr_reader :name, :models, :material

  def initialize(name)
    @name = name
    @models = {}
    @material = Sketchup.active_model.materials['bottle_material']
    components = Sketchup.active_model.definitions
    @definition = components.load ProjectHelper.asset_directory + "/sketchup_components/pipe.skp"
  end

  def longest_model_shorter_than(length)
    model = @models.values.find do |model|
      model.length < length &&
        length - model.length < Configuration::PIPE_ALLOWED_DIFFERENCE
    end
    puts model
    if model.nil?
      model = create_model(length)
      @models[model.name] = model
    end
    model
  end

  def shortest_model_longer_than(length)
    longest_model_shorter_than(length)
  end

  def longest_model
    @models.values.max_by(&:length)
  end

  def shortest_model
    @models.values.min_by(&:length)
  end

  def valid
    @models.each { |_, model| return false unless model.valid? }
    true
  end

  private

  def create_model(length)
    name = "Pipe(#{length})"
    short_name = length.to_s
    weight = length.to_cm * Configuration::PIPE_WEIGHT_IN_GRAMS_PER_CM
    model = Pipe.new(name, short_name, weight, @definition, self, length)
    model
  end
end
