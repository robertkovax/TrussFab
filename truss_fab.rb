require 'trussFab/source/configuration/configuration.rb'
require 'trussFab/source/utility/project_helper.rb'
require 'trussFab/source/ui/user_interaction.rb'

class TrussFab
  def self.start
    TrussFab.new
  end

  def initialize
    ProjectHelper.setup_sketchup
    UserInteraction.new
  end
end
