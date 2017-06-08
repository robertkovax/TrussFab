module MSPhysics

  # @since 1.0.0
  class Spring < Joint

    DEFAULT_MIN = -10.0
    DEFAULT_MAX = 10.0
    DEFAULT_ACCEL = 40.0
    DEFAULT_DAMP = 10.0
    DEFAULT_STRENGTH = 0.98
    DEFAULT_HOOKES_ENABLED = false
    DEFAULT_LIMITS_ENABLED = false
    DEFAULT_START_POSITION = 0.0
    DEFAULT_CONTROLLER = 1.0

    # Create a spring joint.
    # @param [MSPhysics::World] world
    # @param [MSPhysics::Body, nil] parent
    # @param [Geom::Transformation, Array<Numeric>] pin_tra Pin transformation
    #   in global space. Matrix origin is interpreted as the pin position.
    #   Matrix z-axis is interpreted as the pin direction.
    # @param [Sketchup::Group, Sketchup::ComponentInstance, nil] group
    def initialize(world, parent, pin_tra, group = nil)
      super(world, parent, pin_tra, group)
      MSPhysics::Newton::Spring.create(@address)
      MSPhysics::Newton::Spring.set_min(@address, DEFAULT_MIN)
      MSPhysics::Newton::Spring.set_max(@address, DEFAULT_MAX)
      MSPhysics::Newton::Spring.set_accel(@address, DEFAULT_ACCEL)
      MSPhysics::Newton::Spring.set_damp(@address, DEFAULT_DAMP)
      MSPhysics::Newton::Spring.set_strength(@address, DEFAULT_STRENGTH)
      MSPhysics::Newton::Spring.set_mode(@address, DEFAULT_HOOKES_ENABLED ? 1 : 0)
      MSPhysics::Newton::Spring.enable_limits(@address, DEFAULT_LIMITS_ENABLED)
      MSPhysics::Newton::Spring.set_start_position(@address, DEFAULT_START_POSITION)
      MSPhysics::Newton::Spring.set_controller(@address, DEFAULT_CONTROLLER)
    end

    # Get minimum position in meters with respect to the starting position.
    # @return [Numeric]
    def min
      MSPhysics::Newton::Spring.get_min(@address)
    end

    # Set minimum position in meters with respect to the starting position.
    # @param [Numeric] value
    def min=(value)
      MSPhysics::Newton::Spring.set_min(@address, value)
    end

    # Get maximum position in meters with respect to the starting position.
    # @return [Numeric]
    def max
      MSPhysics::Newton::Spring.get_max(@address)
    end

    # Set maximum position in meters with respect to the starting position.
    def max=(value)
      MSPhysics::Newton::Spring.set_max(@address, value)
    end

    # Determine whether min and max position limits are enabled.
    # @return [Boolean]
    def limits_enabled?
      MSPhysics::Newton::Spring.limits_enabled?(@address)
    end

    # Enable/disable min and max position limits.
    # @param [Boolean] state
    def limits_enabled=(state)
      MSPhysics::Newton::Spring.enable_limits(@address, state)
    end

    # Get spring oscillation acceleration.
    # @return [Numeric] A spring constant in kg/s² or spring accel in 1/s²,
    #   depending on the mode; a value greater than or equal to zero.
    def accel
      MSPhysics::Newton::Spring.get_accel(@address)
    end

    # Set spring oscillation acceleration.
    # @param [Numeric] value A spring constant in kg/s² or spring accel in 1/s²,
    #   depending on the mode; a value greater than or equal to zero.
    def accel=(value)
      MSPhysics::Newton::Spring.set_accel(@address, value)
    end

    # Get spring oscillation drag.
    # @return [Numeric] A spring drag coefficient in kg/s or spring damp in 1/s,
    #   depending on the mode; a value greater than or equal to zero.
    def damp
      MSPhysics::Newton::Spring.get_damp(@address)
    end

    # Set spring oscillation drag.
    # @param [Numeric] value A spring drag coefficient in kg/s or spring damp
    #    in 1/s, depending on the mode; a value greater than or equal to zero.
    def damp=(value)
      MSPhysics::Newton::Spring.set_damp(@address, value)
    end

    # Get spring strength coefficient.
    # @note This option has an effect only if mode is set to zero.
    # @return [Numeric] A value between 0.0 and 1.0.
    def strength
      MSPhysics::Newton::Spring.get_strength(@address)
    end

    # Set spring strength coefficient.
    # @note This option has an effect only if mode is set to zero.
    # @param [Numeric] value A value between 0.0 and 1.0.
    def strength=(value)
      MSPhysics::Newton::Spring.set_strength(@address, value)
    end

    # Get spring mode.
    # @return [Fixnum]
    #   * 0 - if using standard accel/damp/strength.
    #   * 1 - if using Hooke's spring constant and spring damping coefficient.
    def mode
      MSPhysics::Newton::Spring.get_mode(@address)
    end

    # Set spring mode.
    # @param [Fixnum] value
    #   * 0 - use standard accel/damp/strength.
    #   * 1 - use Hooke's spring constant and spring damping coefficient.
    def mode=(value)
      MSPhysics::Newton::Spring.set_mode(@address, value)
    end

    # Get current position in meters with respect to the starting position.
    # @return [Numeric]
    def cur_position
      MSPhysics::Newton::Spring.get_cur_position(@address)
    end

    # Get current velocity in meters per second.
    # @return [Numeric]
    def cur_velocity
      MSPhysics::Newton::Spring.get_cur_velocity(@address)
    end

    # Get current acceleration in meters per second per second.
    # @return [Numeric]
    def cur_acceleration
      MSPhysics::Newton::Spring.get_cur_acceleration(@address)
    end

    # Get starting position along joint Z-axis in meters.
    # @note The actual starting position is
    #   <tt>start_posistion * controller</tt>.
    # @return [Numeric]
    def start_position
      MSPhysics::Newton::Spring.get_start_position(@address)
    end

    # Set starting position along joint Z-axis in meters.
    # @note The actual starting position is
    #   <tt>start_posistion * controller</tt>.
    # @param [Numeric] position
    def start_position=(position)
      MSPhysics::Newton::Spring.set_start_position(@address, position)
    end

    # Get spring controller, magnitude and direction of the starting position.
    # By default, controller value is 1.
    # @note The actual starting position is
    #   <tt>start_posistion * controller</tt>.
    # @return [Numeric]
    def controller
      MSPhysics::Newton::Spring.get_controller(@address)
    end

    # Set spring controller, magnitude and direction of the starting position.
    # By default, controller value is 1.
    # @note The actual starting position is
    #   <tt>start_posistion * controller</tt>.
    # @param [Numeric] value
    def controller=(value)
      MSPhysics::Newton::Spring.set_controller(@address, value)
    end

  end # class Spring < Joint
end # module MSPhysics
