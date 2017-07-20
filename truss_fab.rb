require 'src/configuration/configuration.rb'
require 'src/utility/project_helper.rb'
require 'src/ui/user_interaction.rb'
require 'reloader'

class TrussFab
  ProjectHelper.setup_sketchup
  @reloader = Reloader.new
  @ui = UserInteraction.new

  def self.start
    @ui.open_main_dialog
  end

  def self.stop
    @ui.close_main_dialog
  end

  def self.reload
    @reloader.reload
  end
end
