require File.expand_path('../', File.dirname(__FILE__)) + '/utility/project_helper.rb'
class Configuration
  # Sketchup Layers
  LINE_VIEW = 'Link lines'
  COMPONENT_VIEW = 'Bottles'
  HUB_VIEW = 'Hubs'
  HUB_ID_VIEW = 'Hub IDs'
  CONNECTOR_MODE_VIEW = 'Connectors'
  TRIANGLE_SURFACES_VIEW = 'Triangle Surfaces'
  DRAW_TOOLTIPS_VIEW = 'Drawing Tooltips'

  # UI Dialog Properties
  HTML_DIALOG = {
      :dialog_title => "TrussFab",
      :scrollable => true,
      :resizable => true,
      :width => 380,
      :height => 900,
      :left => 10,
      :top => 100,
      :style => UI::HtmlDialog::STYLE_DIALOG
  }

  # Elongation properties
  DEFAULT_ELONGATION = 30.mm

  BALL_HUB_RADIUS = 14.mm

  TETRAHEDRON = ProjectHelper.asset_directory + '/primitives/tetrahedron.json'

  # Model Settings
  HARD_MODELS = [
      {
          NAME: 'Big Big Double Bottle (60cm)',
          WEIGHT: 0.16,
          PATH: ProjectHelper.component_directory + '/1-big-big-double-bottle(60cm).skp'
      },
      {
          NAME: 'Small Big Double Bottle (53cm)',
          WEIGHT: 0.14,
          PATH: ProjectHelper.component_directory + '/2-small-big-double-bottle(53cm).skp'
      },
      {
          NAME: 'Small Small Double Bottle (46cm)',
          WEIGHT: 0.11,
          PATH: ProjectHelper.component_directory + '/3-small-small-double-bottle(46cm).skp'
      },
      {
          NAME: 'Big Single Bottle (30cm)',
          WEIGHT: 0.078,
          PATH: ProjectHelper.component_directory + '/4-big-single-bottle(30cm).skp'
      },
      {
          NAME: 'Small Single Bottle (23cm)',
          WEIGHT: 0.048,
          PATH: ProjectHelper.component_directory + '/5-small-single-bottle(23cm).skp'
      }
  ]

  ELONGATION_COLOR = [0.69, 0.75, 0.81]
  ELONGATION_RADIUS = 11.mm
  CONNECTOR_COLOR = 'blue'
  CONNECTOR_RADIUS = 8.mm
end