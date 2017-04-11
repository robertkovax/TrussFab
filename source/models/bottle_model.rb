require ProjectHelper.model_directory + '/bottle.rb'

class BottleModel
  attr_reader :name, :models

  def initialize name, specifications
    @name = name
    @models = Hash.new
    specifications.each do |specification|
      @models[specification[:NAME]] = create_model specification
    end
  end

  def find_model_shorter_than length
    long_model = shortest_model
    @models.values.each do |model|
      next if model.length > length
      long_model = model if model.length > long_model.length
    end
    long_model
  end

  def find_model_longer_than length
    short_model = longest_model
    @models.values.each do |model|
      next if model.length < length
      short_model = model if model.length < short_model.length
    end
    short_model
  end

  def longest_model
    length = -Float::INFINITY
    longest_model = nil
    @models.values.each do |model|
      if model.length > length
        longest_model = model
        length = model.length
      end
    end
    longest_model
  end

  def shortest_model
    length = Float::INFINITY
    shortest_model = nil
    @models.values.each do |model|
      if model.length < length
        shortest_model = model
        length = model.length
      end
    end
    shortest_model
  end

  private
  def create_model specification
    components = Sketchup.active_model.definitions # Sketchup Component Definitions
    name = specification[:NAME]
    if components[name]
      model = components[name]
    else
      definition = components.load specification[:PATH]
      model = Bottle.new name, specification[:WEIGHT], definition, self
    end
    model
  end
end