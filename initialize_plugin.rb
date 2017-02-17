require 'bottleProject/configuration/configuration'
require 'bottleProject/util/project_helper'
require 'bottleProject/ui/user_interaction'
require 'bottleProject/ui/component_properties'
require 'bottleProject/thingies/links/models/load_bottle_models'
require 'bottleProject/observer/tool_log_observer'
require 'bottleProject/storage/storage'


class InitializePlugin
  def initialize
    ProjectHelper.setup_sketchup_background
    Sketchup.active_model.options["UnitsOptions"]["LengthUnit"] = 2 #print and display lengths in mm
    Sketchup.active_model.options["UnitsOptions"]["LengthFormat"] = 0 #print and display lengths as decimal number
    Sketchup.active_model.tools.add_observer(ToolLogObserver.new)
    ProjectHelper.create_layers

    LoadBottleModels.instance
    BallHubModel.instance
    DiscHubModel.instance

    ComponentProperties.instance

    ProjectHelper.remove_fleeting_entities
    Storage.instance.build_from_dict

    UserInteraction.instance
  end

end
