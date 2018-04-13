require 'src/tools/tool'

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
    @combinations = @states.repeated_permutation(@pistons.length).map { |values| @pistons.map { |piston| piston[0] }.zip(values).to_h }
    @combinations.each do |combination|
      force = @simulation.check_pose(combination)
      @combinations_with_force << {force: force, combination: combination}
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
          "minimum"
        when 0
          "middle"
        when 1
          "maximum"
        end
        p "Piston #{id}: #{pos_string} position"
      end
      p ''
    end

    reset_simulation
  end

  def onMouseMove(_flags, x, y, view)
  end

  def onLButtonDown(_flags, x, y, view)
  end
end
