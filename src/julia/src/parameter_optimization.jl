

function tweak_amplitude(g, target_length, simulation_duration=5.0)
    user_vertex_id = TrussFab.users(g)[1]

    # sample spring parameter space 
    spring_stiffnesses = range(1e3, 20e3, length=10)
    solutions = []
    samples = spring_stiffnesses |> collect

    function simulate_with_stiffness(k)
        TrussFab.set_stiffness!(g, fill(k, length(TrussFab.springs(g))))
        return fetch(@spawnat :any TrussFab.run_simulation(g, tspan=(0., simulation_duration), fps=30))
    end

    # sols = SharedArray{Float64,2}((length(times),length(params)))
    solutions = asyncmap(simulate_with_stiffness, spring_stiffnesses, ntasks=100)
    # return solutions
    amplitudes = solutions .|> sol -> TrussFab.get_amplitude(sol, user_vertex_id)[1]
    
    println(amplitudes)
    # discarding lengths that are outside the sampled space
    if target_length < minimum(amplitudes) || target_length > maximum(amplitudes)
        @warn "requested amplitude is outside the achievable range"
    end
    
    
    # doing linear regression here
    # slope = sqrt(spring_stiffnesses.^2 \ amplitudes.^2)
    match_index_pred = findmin(abs.(amplitudes .- target_length))[2]
    spring_siffness_prediction = spring_stiffnesses[match_index_pred] 
    
    @info "guess for spring constant was $(spring_siffness_prediction)"
    
    # subsample the bin / area that matched most closley 
    subsamples = spring_siffness_prediction-500:100.0:spring_siffness_prediction+500
    @info "We will try out: $(subsamples)"
    append!(samples, subsamples |> collect)
    append!(solutions, asyncmap(simulate_with_stiffness, subsamples, ntasks=100))
    amplitudes = solutions .|> sol -> TrussFab.get_amplitude(sol, user_vertex_id)[1]

    # return closest match
    match_index = findmin(abs.(amplitudes .- target_length))[2]
    achieved_length = amplitudes[match_index]
    error = abs(achieved_length - target_length) / target_length
    if !(samples[match_index] in subsamples)
        @warn "spring constant was not selected from the subsampling step"
    end

    # if error > 0.2
    #     throw(ErrorException("No spring configuration within a 15% error was found."))
    # end
    @info "Error for optimization was $(error), achieved length was $(achieved_length)"

    return (samples[match_index], error, solutions[match_index])
end