require 'src/utility/project_helper.rb'

module Configuration
  # Sketchup Layers
  LINE_VIEW = 'Link lines'.freeze
  COMPONENT_VIEW = 'Bottles'.freeze
  HUB_VIEW = 'Hubs'.freeze
  HUB_ID_VIEW = 'Hub IDs'.freeze
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
  ELONGATION_RADIUS = 11.mm.freeze
  BALL_HUB_RADIUS = 14.mm.freeze
  STANDARD_BOTTLES = 'hard'.freeze
  COVER_THICKNESS = 20.mm.freeze

  # Paths
  JSON_PATH = (ProjectHelper.asset_directory + '/exports/').freeze
  TETRAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/tetrahedron.json').freeze
  OCTAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/octahedron.json').freeze
  DYNAMIC_TETRAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/dynamic_tetrahedron.json').freeze
  DYNAMIC_OCTAHEDRON_PATH = (ProjectHelper.asset_directory + '/primitives/dynamic_octahedron.json').freeze

  BIG_BIG_BOTTLE_NAME = 'Big Big Double Bottle'.freeze
  SMALL_BIG_BOTTLE_NAME = 'Small Big Double Bottle'.freeze
  SMALL_SMALL_BOTTLE_NAME = 'Small Small Double Bottle'.freeze

  # Bottle lengths
  SMALL_BOTTLE_LENGTH = 23.cm
  BIG_BOTTLE_LENGTH = 30.cm

  # General Model Settings, in inch
  NECK_RADIUS = 0.27534.freeze
  NECK_LENGTH = 0.68901.freeze
  FRONT_CONE_LENGTH = 2.3422.freeze
  CYLINDER_LENGTH = 5.61384.freeze
  CYLINDER_RADIUS = 1.12994.freeze
  BACK_CONE_LENGTH = 0.55237.freeze
  BOTTOM_RADIUS = 0.73885.freeze

  # colors
  STANDARD_COLOR = [0.5, 0.5, 0.5].freeze
  HIGHLIGHT_COLOR = [1, 1, 1].freeze
  SURFACE_COLOR = [1, 1, 1].freeze
  SURFACE_HIGHLIGHT_COLOR = [0.5, 0.5, 0.5].freeze
  HUB_COLOR = [0.69, 0.75, 0.81].freeze
  ELONGATION_COLOR = [0.69, 0.75, 0.81].freeze

  # Behavioural constants
  SNAP_TOLERANCE = 200.mm.freeze
  INTERSECTION_OFFSET = 200.mm.freeze
end
