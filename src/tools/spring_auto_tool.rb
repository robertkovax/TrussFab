require 'src/tools/tool.rb'
require 'src/utility/mouse_input.rb'
require 'src/simulation/simulation.rb'
require 'src/configuration/configuration.rb'
require 'src/sketchup_objects/spring_damper_link.rb'

# A tool that checks step-wise how much force an actuator needs in order to move
# the two nodes it is connected to. It also checks what the maximum force is
# before any node in the object breaks
class SpringAutoTool < Tool
  def initialize(ui)
    super(ui)
    @mouse_input = MouseInput.new(snap_to_edges: true)
    @move_mouse_input = nil

    @moving = false
    @force = 0
    @previous_force = 0
    @min_force = 0
    @max_force = 0
    @edge = nil
    @threshold = 0.02
    @piston_position = 0
    @steps = 0
  end

  def activate; end

  def deactivate(view)
    Sketchup.active_model.start_operation('deactivate force limit tool', true)
    view.animation = nil
    @simulation.reset unless @simulation.nil?
    @simulation = nil
    super
    @steps = @force = @previous_force = @min_force = @max_force = 0
    view.invalidate
    Sketchup.active_model.commit_operation
  end

  def update(view, x, y)
    @mouse_input.update_positions(
      view, x, y, point_on_plane_from_camera_normal: @start_position || nil
    )
  end

  def onLButtonDown(_flags, x, y, view)
    update(view, x, y)
    edge = @mouse_input.snapped_object
    if edge.nil? || !edge.link.is_a?(SpringDamperLink)
      p 'Edge is invalid. Should be a SpringDamperLink'
      return
    end

    @moving = true
    @edge = edge
    @spring = edge.link
    @old_spring_constant = @spring.spring_constant
    @old_damping_coefficient = @spring.damping_coefficient
    puts("spring auto tool")
    puts("old: #{@old_spring_constant}  #{@old_damping_coefficient}")
    find_limits
  end

  def setup_simulation
    @simulation.setup
    @simulation.timesteps = 1.0/60.0
  end

  def reset_simulation
    @simulation.reset
    setup_simulation
  end
  
  def cleanup
    @spring.spring_constant = @old_spring_constant
    @spring.damping_coefficient = @old_damping_coefficient
  end

  def find_limits
    Sketchup.active_model.start_operation('find force limits', true)
    
    #setup simulation
    @simulation = Simulation.new
    setup_simulation
    
    #test the old values
    @old_model_stable = model_stable?
    
    @spring_max = find_spring_upper_limit
    @spring_min = find_spring_lower_limit#(@spring_max)
    #puts("find(10000,0,100): #{find_spring_limit(10000, 0, 100)}")
    #puts("find(10000,0,100): #{find_spring_limit(0, 10000, 100)}")
    puts("spring:    max: #{@spring_max}, min: #{@spring_min}")
    
    @simulation.reset
    @simulation = nil
    cleanup

    Sketchup.active_model.commit_operation
    puts("calculation finished")
  end
  
  def find_spring_limit(start, end_value, precision)
    possible = end_value
    last_tested = end_value
    to_test = start
    diff = to_test - last_tested
    
    until (diff.abs < precision)
      puts("to test: #{to_test}")
      @spring.spring_constant = to_test
      stable = model_stable?
      puts("stable: #{stable ? "true" : "false"}")
      last_tested = to_test
      if (stable)
        possible = to_test
        break if to_test == start
        to_test = last_tested + (diff.abs/2)
      else
        to_test = last_tested - (diff.abs/2)
      end
      diff = to_test - last_tested
    end
    
    possible
  end
  
  #find out what is the maximum possible spring constant for the current model
  def find_spring_upper_limit(minimum = 0)
    highest_possible = minimum
    last_tested = minimum
    to_test = 10000
    diff = to_test - last_tested
    
    until (diff.abs < 100 or highest_possible>=10000)
      @spring.spring_constant = to_test
      stable = model_stable?
      last_tested = to_test
      if (stable)
        highest_possible = to_test
        to_test = last_tested + (diff.abs/2)
      else
        to_test = last_tested - (diff.abs/2)
      end
      diff = to_test - last_tested
    end
    
    highest_possible
  end
  
  #find out what is the maximum possible spring constant for the current model
  def find_spring_lower_limit(maximum = 10000)
    lowest_possible = maximum
    last_tested = maximum
    to_test = 0
    diff = to_test - last_tested
    
    until (diff.abs < 100 or lowest_possible<=0)
      @spring.spring_constant = to_test
      stable = model_stable?
      last_tested = to_test
      if (stable)
        lowest_possible = to_test
        to_test = last_tested - (diff.abs/2)
      else
        to_test = last_tested + (diff.abs/2)
      end
      diff = to_test - last_tested
    end
    
    lowest_possible
  end
  
  #tests if the model is breaking in the first x seconds, output: boolean (stable/ not broken)
  def model_stable?(time_span = 3)
    @simulation.simulate_headless_for(time_span)
    #puts(@simulation.broken? ? "model broken" : "model stable")
    stable = (not @simulation.broken?)
    reset_simulation    
    
    stable
  end
end
