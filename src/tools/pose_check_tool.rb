require 'src/tools/tool'

# A tool that tries to find the force limit by putting an object with actuators
# in different poses (e.g. actuator extended, actuator in the middle, actuator
# retracted) and checks how high the static forces in each combination is
class PoseCheckTool < Tool
  def initialize(ui)
    super(ui)
    @pistons = nil
    @combinations_with_force = []
    @combinations = []
    @states = [-1, 0, 1]
  end

  def reset_simulation
    @simulation.stop
    @simulation.reset
  end

  def activate
    @simulation = Simulation.new
    @simulation.setup
    @pistons = @simulation.pistons
    @combinations =
      @states.repeated_permutation(@pistons.length).map do |values|
        @pistons.map { |piston| piston[0] }.zip(values).to_h
      end
    @combinations.each do |combination|
      force = @simulation.check_pose(combination)
      @combinations_with_force << { force: force, combination: combination }
      @simulation.reset
      @simulation.setup
    end

    @combinations_with_force.sort! { |x, y| y[:force] <=> x[:force] }
    @combinations_with_force.each do |combination|
      p "Highest Recorded Force: #{combination[:force]}"
      p 'Piston positioning: '
      combination[:combination].each do |id, pos|
        pos_string = case pos
                     when -1
                       'minimum'
                     when 0
                       'middle'
                     when 1
                       'maximum'
                     end
        p "Piston #{id}: #{pos_string} position"
      end
      p ''
    end

    reset_simulation
  end

  def onMouseMove(_flags, _x, _y, _view); end

  def onLButtonDown(_flags, _x, _y, _view); end
end
