# TODO
# * two hinges on one elongation

class ExportHub
  def initialize(is_main_hub)
    @is_main_hub = is_main_hub # otherwise sub hubs ('hubless design')
    @elongations = []
  end

  def add_elongation(elongation)
    @elongations.push(elongation)
  end
end
