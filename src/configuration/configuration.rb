require 'src/utility/project_helper.rb'

module Configuration
  # Sketchup Layers
  LINE_VIEW = 'Link lines'.freeze
  COMPONENT_VIEW = 'Bottles'.freeze
  HUB_VIEW = 'Hubs'.freeze
  HUB_ID_VIEW = 'Hub IDs'.freeze
  TRIANGLE_SURFACES_VIEW = 'Triangle Surfaces'.freeze
  DRAW_TOOLTIPS_VIEW = 'Drawing Tooltips'.freeze
  FORCE_LABEL_VIEW = 'Force Labels'.freeze
  FORCE_VIEW = 'Forces'.freeze
  HINGE_VIEW = 'Hinge lines'.freeze
  ACTUATOR_VIEW = 'Actuators'.freeze

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

  UI_WIDTH  = 380
  UI_HEIGHT = 700

  # SketchupObject Properties
  MINIMUM_ELONGATION    = 20.mm.freeze
  DEFAULT_ELONGATION    = 30.mm.freeze
  MAXIMUM_ELONGATION    = 100.mm.freeze
  BALL_HUB_RADIUS       = 14.mm.freeze
  STANDARD_BOTTLES      = 'hard'.freeze
  COVER_THICKNESS       = 20.mm.freeze
  ELONGATION_RADIUS     = 11.mm.freeze

  # Paths
  JSON_PATH = (ProjectHelper.asset_directory + '/exports/').freeze
  TETRAHEDRON_PATH = (ProjectHelper.asset_directory +
                     '/primitives/tetrahedron.json').freeze
  OCTAHEDRON_PATH = (ProjectHelper.asset_directory +
                    '/primitives/octahedron.json').freeze
  DYNAMIC_TETRAHEDRON_PATH = (ProjectHelper.asset_directory +
                             '/primitives/dynamic_tetrahedron.json').freeze
  DYNAMIC_OCTAHEDRON_PATH = (ProjectHelper.asset_directory +
                            '/primitives/dynamic_octahedron.json').freeze
  ASSETS_LEG_PATH = (ProjectHelper.asset_directory +
                    '/primitives/leg.json').freeze
  ASSETS_BEND_PATH = (ProjectHelper.asset_directory +
                     '/primitives/bend.json').freeze
  ASSETS_PARALLEL_PATH = (ProjectHelper.asset_directory +
                         '/primitives/parallel.json').freeze
  ASSETS_HINGE_PATH = (ProjectHelper.asset_directory +
                      '/primitives/asset_hinge.json').freeze

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
      PATH: ProjectHelper.component_directory +
        '/1-big-big-double-bottle(60cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: SMALL_BIG_BOTTLE_NAME,
      WEIGHT: 0.14,
      PATH: ProjectHelper.component_directory +
        '/2-small-big-double-bottle(53cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: SMALL_SMALL_BOTTLE_NAME,
      WEIGHT: 0.11,
      PATH: ProjectHelper.component_directory +
        '/3-small-small-double-bottle(46cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: BIG_BOTTLE_NAME,
      WEIGHT: 0.078,
      PATH: ProjectHelper.component_directory +
        '/4-big-single-bottle(30cm).skp',
      MODEL: 'hard'
    },
    {
      NAME: SMALL_BOTTLE_NAME,
      WEIGHT: 0.048,
      PATH: ProjectHelper.component_directory +
        '/5-small-single-bottle(23cm).skp',
      MODEL: 'hard'
    }
  ].freeze

  # Colors
  STANDARD_COLOR            = Sketchup::Color.new(1.0, 1.0, 1.0)
  BOTTLE_COLOR              = Sketchup::Color.new(1.0, 1.0, 1.0)
  ACTUATOR_COLOR            = Sketchup::Color.new(1.0, 1.0, 1.0)
  SPRING_COLOR              = Sketchup::Color.new(1.0, 0.64, 0.0)
  GENERIC_LINK_COLOR        = Sketchup::Color.new(0.72, 1.0, 0.0)
  HIGHLIGHT_COLOR           = Sketchup::Color.new(0.5, 0.5, 0.5)
  SURFACE_COLOR             = Sketchup::Color.new(1.0, 1.0, 1.0)
  SURFACE_HIGHLIGHT_COLOR   = Sketchup::Color.new(0.5, 0.5, 0.5)
  HUB_COLOR                 = Sketchup::Color.new(0.69, 0.75, 0.81)
  ELONGATION_COLOR          = Sketchup::Color.new(0.69, 0.75, 0.81)
  PID_COLOR                 = Sketchup::Color.new(1.0, 0.45, 0.0)

  # Ground Stuff
  GROUND_COLOR          = Sketchup::Color.new(1.0, 1.0, 1.0)
  GROUND_ALPHA          = 0.0
  GROUND_SIZE           = 10_000 # in inches
  GROUND_HEIGHT         = 0.01 # in inches
  GROUND_THICKNESS      = 20.0 # in inches

  # Behavioural Constants
  SNAP_TOLERANCE        = 200.mm.freeze
  INTERSECTION_OFFSET   = 200.mm.freeze

  # Simulation Properties
  WORLD_GRAVITY         = -9.8 # in m/s/s
  WORLD_SOLVER_MODEL    = 1 # 1 - 64
  WORLD_TIMESTEP        = 1.0 / 60 # in seconds
  WORLD_NUM_ITERATIONS  = ((1.0 / 60) / WORLD_TIMESTEP).to_i
  JOINT_SOLVER_MODEL    = 0 # 0 or 2
  JOINT_STIFFNESS       = 0.95 # ratio (0.0 - 1.0)
  JOINT_BREAKING_FORCE  = 1500 # (in Newtons)
  BODY_STATIC_FRICITON  = 0.9
  BODY_KINETIC_FRICITON = 0.5
  BODY_ELASTICITY       = 0.1
  BODY_SOFTNESS         = 0.1
  DRAG_FACTOR           = 10

  # PointToPointActuator Properties
  ACTUATOR_RATE         = 0.5 # in m/s
  ACTUATOR_POWER        = 0.0 # in Newtons (0 indicates max)
  ACTUATOR_REDUCTION    = 0.1 # ratio (0.0 - 1.0)
  ACTUATOR_MIN          = -0.2 # in meters
  ACTUATOR_MAX          = 0.2 # in meters
  ACTUATOR_INIT_DIST    = 0.4

  # PointToPointGasSpring Properties
  SPRING_STROKE_LENGTH = 0.2
  SPRING_EXTENDED_FORCE = 20
  SPRING_THRESHOLD = 0.015
  SPRING_DAMP = 10

  # GenericPointToPoint Properties
  GENERIC_LINK_FORCE = 0
  GENERIC_LINK_MIN_DISTANCE = -0.2
  GENERIC_LINK_MAX_DISTANCE = 0.2

  # Tension
  TENSION_COLORS = [
    Sketchup::Color.new(0, 0, 255),
    Sketchup::Color.new(255, 255, 255),
    Sketchup::Color.new(255, 0, 0)
  ].freeze
  TENSION_SENSITIVITY = 1.0

  # Mass (in kilograms)
  # Because only hubs have physics components to them,
  #  it would be ideal to increase hub mass to accommodate
  #  for all the linked pods and links.
  ELONGATION_MASS   = 0.0
  LINK_MASS         = 0.2
  PISTON_MASS       = 0.3
  HUB_MASS          = 0.12
  POD_MASS          = 0.1

  # Socket-Communication
  SOCKET_ENABLE_SENDING = false
  SOCKET_ADDRESS = 'localhost'
  SOCKET_PORT = 5000

  #PID_Controller
  STATIC_FORCE_ANALYSIS_STEPS = 5
end
