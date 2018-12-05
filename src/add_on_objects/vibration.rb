# Defines Vibration Object which can be placed on Hubs by using the 'add Vibration Tool'
class Vibration
    attr_accessor :frequency, :max_force, :direction

    # @param [Float] frequency sets how fast the object should move back and forth
    # @param [Int] max_force sets maximum strength to be used to move the object
    # @param [Vector3d] direction defines on what vector the object moves
    def initialize(frequency = 2, max_force = 5, direction = Geom::Vector3d.new(0, 1, 0))
        @frequency = frequency
        @max_force = max_force
        @direction = direction
    end

    # Calculates a force vector for the vibration object at a given time in the simulation
    # @param [Int] frame current frame number
    # @param [Float] timesteps number of frames per second
    # @return [Vector3d]
    def get_current_force_vector(frame, timesteps)
        current_time = frame * timesteps
        current_force = @max_force * Math.sin(current_time * @frequency * 2 * Math::PI)

        Geom::Vector3d.new(@direction.x * current_force,
                           @direction.y * current_force,
                           @direction.z * current_force)
    end
end
