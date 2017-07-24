require 'src/utility/project_helper.rb'

module Configuration
  # Sketchup Layers
  LINE_VIEW = 'Link lines'.freeze
  COMPONENT_VIEW = 'Bottles'.freeze
  HUB_VIEW = 'Hubs'.freeze
  HUB_ID_VIEW = 'Hub IDs'.freeze
  CONNECTOR_MODE_VIEW = 'Connectors'.freeze
  TRIANGLE_SURFACES_VIEW = 'Triangle Surfaces'.freeze
  DRAW_TOOLTIPS_VIEW = 'Drawing Tooltips'.freeze

  # UI Dialog Properties
  MAIN_HTML_DIALOG = {
    dialog_title: 'TrussFab',
    scrollable: true,
    resizable: true,
    width: 380,
    height: 900,
    left: 10,
    top: 100,
    style: UI::HtmlDialog::STYLE_DIALOG
  }.freeze

  TIMELINE_HTML_DIALOG = {
    dialog_title: 'TrussFab - Scheduler',
    scrollable: true,
    resizable: true,
    width: 400,
    height: 400,
    left: 400,
    bottom: 50,
    style: UI::HtmlDialog::STYLE_DIALOG
  }.freeze

  # Thingy properties
  MINIMUM_ELONGATION = 20.mm.freeze
  DEFAULT_ELONGATION = 30.mm.freeze
  MAXIMUM_ELONGATION = 100.mm.freeze
  BALL_HUB_RADIUS = 14.mm.freeze
  STANDARD_BOTTLES = 'hard'.freeze

  # Paths
  JSON_PATH = (ProjectHelper.asset_directory + '/exports/').freeze
  TETRAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/tetrahedron.json').freeze
  OCTAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/octahedron.json').freeze
  DYNAMIC_TETRAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/dynamic_tetrahedron.json').freeze
  DYNAMIC_OCTAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/dynamic_octahedron.json').freeze

  # Model Settings
  HARD_MODELS = [
    {
      NAME: 'Big Big Double Bottle (60cm)',
      WEIGHT: 0.16,
      PATH: ProjectHelper.component_directory + '/1-big-big-double-bottle(60cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: 'Small Big Double Bottle (53cm)',
      WEIGHT: 0.14,
      PATH: ProjectHelper.component_directory + '/2-small-big-double-bottle(53cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: 'Small Small Double Bottle (46cm)',
      WEIGHT: 0.11,
      PATH: ProjectHelper.component_directory + '/3-small-small-double-bottle(46cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: 'Big Single Bottle (30cm)',
      WEIGHT: 0.078,
      PATH: ProjectHelper.component_directory + '/4-big-single-bottle(30cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: 'Small Single Bottle (23cm)',
      WEIGHT: 0.048,
      PATH: ProjectHelper.component_directory + '/5-small-single-bottle(23cm).skp',
      MODEL: 'hard'
    }
  ].freeze

  ELONGATION_COLOR = [0.69, 0.75, 0.81].freeze
  ELONGATION_RADIUS = 11.mm.freeze
  CONNECTOR_COLOR = 'blue'.freeze
  CONNECTOR_RADIUS = 8.mm.freeze

  # Behavioural constants
  SNAP_TOLERANCE = 200.mm.freeze
  INTERSECTION_OFFSET = 500.mm.freeze
end
