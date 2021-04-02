using Distributed
using DiffEqBase
using OrdinaryDiffEq

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


function find_equilibrium_spring_elongations(g)
    g = deepcopy(g)
    vertices(g) .|> v -> set_prop!(g, v, :active_user, false)   
    length_corrections = zeros(ne(g))

    for _ in 1:100
        eom = Simulator.get_equations_of_motion(g) 
        u0 = Simulator.get_inital_conditions(g)
        params = Simulator.get_simulation_parameters(g)
        
        ode_problem = ODEProblem( eom, u0, (0.0, 0.2), params)
        sol = solve(ode_problem, TRBDF2(), save_everystep=false)
        
        for (i, e) in enumerate(edges(g))
            if get_prop(g, e, :type) != "spring"
                continue
            end
            
            displacement(v_id) = sol[v_id*6-5:v_id*6-3, end]
            velocity(v_id) = sol[v_id*6-2:v_id*6, end]
            scalar_projection(v, r) = dot(v, (r ./ norm(r)))
            
            v⃗_source = velocity(e.src)
            v⃗_dest = velocity(e.dst)
            r⃗ = displacement(e.src) .- displacement(e.dst)
            v⃗ = (scalar_projection(v⃗_source, r⃗) .- scalar_projection(v⃗_dest, r⃗))

            # TODO consider other alternatives
            # - steady state solve the system and then measure the forces and calculate the spring length analytically assuming linarity
            # - AD solve the system and GradientDescent to the right spring length

            length_correction = - v⃗ /10
            length_corrections[i] = length_correction
            
            set_prop!(g, e, :length, get_prop(g, e, :length) + length_correction)

            display(plot(sol'))
        end
        error = sum(abs.(length_corrections))
        @info error, length_corrections
        if error < 0.01
            break
        end
        yield()
    end

    return TrussFab.springs(g) .|> e -> get_prop(g, e, :length)
end
