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
  HTML_DIALOG = {
    dialog_title: 'TrussFab',
    scrollable: true,
    resizable: true,
    width: 380,
    height: 900,
    left: 10,
    top: 100,
    style: UI::HtmlDialog::STYLE_DIALOG
  }.freeze

  # Thingy properties
  MINIMUM_ELONGATION = 20.mm.freeze
  DEFAULT_ELONGATION = 30.mm.freeze
  MAXIMUM_ELONGATION = 100.mm.freeze
  BALL_HUB_RADIUS = 14.mm.freeze
  STANDARD_BOTTLES = 'hard'.freeze
  COVER_THICKNESS = 20.mm.freeze

  # Paths
  JSON_PATH = (ProjectHelper.asset_directory + '/exports/').freeze
  TETRAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/tetrahedron.json').freeze
  OCTAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/octahedron.json').freeze
  DYNAMIC_TETRAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/dynamic_tetrahedron.json').freeze
  DYNAMIC_OCTAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/dynamic_octahedron.json').freeze

  BIG_BIG_BOTTLE_NAME = 'Big Big Double Bottle (60cm)'.freeze
  SMALL_BIG_BOTTLE_NAME = 'Small Big Double Bottle (53cm)'.freeze
  SMALL_SMALL_BOTTLE_NAME = 'Small Small Double Bottle (46cm))'.freeze
  BIG_BOTTLE_NAME = 'Big Single Bottle (30cm)'.freeze
  SMALL_BOTTLE_NAME = 'Small Single Bottle (30cm)'.freeze

  # Model Settings
  HARD_MODELS = [
    {
      NAME: BIG_BIG_BOTTLE_NAME,
      WEIGHT: 0.16,
      PATH: ProjectHelper.component_directory + '/1-big-big-double-bottle(60cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: SMALL_BIG_BOTTLE_NAME,
      WEIGHT: 0.14,
      PATH: ProjectHelper.component_directory + '/2-small-big-double-bottle(53cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: SMALL_SMALL_BOTTLE_NAME,
      WEIGHT: 0.11,
      PATH: ProjectHelper.component_directory + '/3-small-small-double-bottle(46cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: BIG_BOTTLE_NAME,
      WEIGHT: 0.078,
      PATH: ProjectHelper.component_directory + '/4-big-single-bottle(30cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: SMALL_BOTTLE_NAME,
      WEIGHT: 0.048,
      PATH: ProjectHelper.component_directory + '/5-small-single-bottle(23cm).skp',
      MODEL: 'hard'
    }
  ].freeze

  STANDARD_COLOR = [0.5, 0.5, 0.5].freeze
  HIGHLIGHT_COLOR = [1, 1, 1].freeze
  SURFACE_COLOR = [1, 1, 1].freeze
  SURFACE_HIGHLIGHT_COLOR = [0.5, 0.5, 0.5].freeze
  HUB_COLOR = [0.69, 0.75, 0.81].freeze
  ELONGATION_COLOR = [0.69, 0.75, 0.81].freeze
  ELONGATION_RADIUS = 11.mm.freeze

  # Behavioural constants
  SNAP_TOLERANCE = 200.mm.freeze
  INTERSECTION_OFFSET = 500.mm.freeze
end
