require 'src/configuration/configuration.rb'
require 'src/utility/project_helper.rb'
require 'src/ui/user_interaction.rb'
require 'reload'

class TrussFab
  ProjectHelper.setup_sketchup
  @reloader = Reloader.new
  @ui = UserInteraction.new

  def self.open
    @ui.open_dialog
  end

  def self.close
    @ui.close_dialog
  end

  def self.reload
    @reloader.reload
  end
end
