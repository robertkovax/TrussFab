require 'source/configuration/configuration.rb'
require 'source/utility/project_helper.rb'
require 'source/ui/user_interaction.rb'

class TrussFab
  def self.start
    TrussFab.new
  end

  def initialize
    ProjectHelper.setup_sketchup
    UserInteraction.new

    # Sketchup.active_model.tools.add_observer(ToolLogObserver.new)

    # LoadBottleModels.instance
    # BallHubModel.instance
    # DiscHubModel.instance

    # ComponentProperties.instance

    # ProjectHelper.remove_fleeting_entities
    # Storage.instance.build_from_dict
  end
end
