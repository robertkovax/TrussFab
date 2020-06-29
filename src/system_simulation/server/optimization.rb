class Optimization

  # This function approximates a optimum (= the biggest spring constant that makes the spring still stay in the angle
  # constrains) by starting with a very low spring constant (which leads to a very high oscillation => high angle delta)
  # and approaches the optimum by approaching with different step sizes (= resolutions of the search), decreasing the
  # step size as soon as the spring constant is not valid anymore and thus approximating the highest valid spring
  # constant.
  def constant_for_constrained_angle(allowed_angle_delta = Math::PI / 2.0, spring_id = 25, initial_constant = 500)
    # steps which the algorithm uses to approximate the valid spring constant
    # TODO: I moved this method from simulation runner so if we want to use it at some point in the future again we need
    # TODO: to adjust it.
    angle_filter = @angles_for_springs[spring_id]
    step_sizes = [1500, 1000, 200, 50, 5]
    constant = initial_constant
    step_size = step_sizes.shift
    keep_searching = true
    abort_threshold = 50_000
    while keep_searching
      # puts "Current k: #{constant} Step size: #{step_size}"
      @constants_for_springs[spring_id] = constant
      run_simulation(angle_filter)
      if !angle_valid(read_csv, allowed_angle_delta)
        # increase spring constant to decrease angle delta
        constant += step_size
      elsif !step_sizes.empty?
        # go back last step_size
        constant -= step_size
        # reduce step size and continue
        step_size = step_sizes.shift
        # make sure we don't exceed the sample space
        constant = initial_constant if constant < initial_constant
      else
        # we reached smallest step size and found a valid spring constant, so we're done
        keep_searching = false
      end

      keep_searching = false if constant >= abort_threshold
    end

    constant
  end

  def angle_valid(data, max_allowed_delta = Math::PI / 2.0)
    data = data.map { |data_sample| data_sample[1].to_f }
    # remove initial data point since it's only containing the column header
    data.shift

    delta = data.max - data.min
    puts "delta: #{delta} maxdelta: #{max_allowed_delta} max: #{data.max}, min: #{data.min}, "
    delta < max_allowed_delta
  end



end
