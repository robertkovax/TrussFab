require 'src/configuration/configuration.rb'
require 'src/utility/project_helper.rb'
require 'src/ui/user_interaction.rb'

class TrussFab
  def self.start
    TrussFab.new
  end

  def initialize
    ProjectHelper.setup_sketchup
    UserInteraction.new
  end
end
