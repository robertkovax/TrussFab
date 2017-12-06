require 'src/configuration/configuration.rb'
require 'src/utility/project_helper.rb'
require 'src/ui/user_interaction.rb'
require 'src/ui/component_properties.rb'
require 'reloader'

class TrussFab
  ProjectHelper.setup_sketchup
  @reloader = Reloader.new
  @ui = UserInteraction.new
  ComponentProperties.new

  def self.start
    @ui.open_dialog
  end

  def self.stop
    @ui.close_dialog
  end

  def self.reload
    @reloader.reload
  end
end
