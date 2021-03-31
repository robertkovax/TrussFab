module Simulator
    using NetworkDynamics
    using LightGraphs
    using OrdinaryDiffEq
    using LinearAlgebra
    using MetaGraphs
    using DiffEqBase
    using DiffEqCallbacks

    export run_simulation

    const c_stiff = 1e6
    const gravity = [0, 0, -9.81]

    # The Dirac function is a 'infinitely' large and 'infinitely' short impulse at x=0 
    # https://en.wikipedia.org/wiki/Dirac_delta_function
    # as a approaches 0, the function will become more 'extreme'
    dirac_delta = (x, a) -> 1 / (a * √π) * exp(1)^(-(x/a)^2)
    dirac_impule_magnitude = 500 #N
    dirac_impulse = (t) -> dirac_delta(t, 1/50) * dirac_impule_magnitude/10
    # Test out how the function looks like in the first second
    # (-0.5:0.01:0.5 .|> x -> dirac_delta(x, 1/20)) |> plot

    function spring_force_from_displacement_vector(r, c, unstreched_length)
        return @views r .* (1 .- (unstreched_length ./ norm(r))) .* c
    end

    function get_equations_of_motion(g, with_dirac=false)
        @inline Base.@propagate_inbounds function displacement(v)
            @views [v[1],v[2],v[3]]
        end

        @inline Base.@propagate_inbounds function velocity(v)
           @views [v[4], v[5], v[6]]
        end
        
        @inline Base.@propagate_inbounds function scalar_projection(v, r)
            @views dot(v, (r ./ norm(r)))
        end
        
        @inline Base.@propagate_inbounds function vector_sum(array, n=3)
            reduce((acc, elem) -> acc .+ elem, array, init=zeros(n))
        end

        @inline Base.@propagate_inbounds  function are_pointing_in_same_direction(vec1, vec2)
            norm(vec1 ./ norm(vec1) .- vec2 ./ norm(vec2)) < sqrt(2)
        end

        @inline Base.@propagate_inbounds function springedge!(e, vertex_src, vertex_dst, params, t)
            d_spring = 75.0

            v⃗_source = velocity(vertex_src)
            v⃗_dest = velocity(vertex_dst)
            c, unstreched_length = @views params
            r⃗ = displacement(vertex_src) .- displacement(vertex_dst)
            
            f⃗_spring = spring_force_from_displacement_vector(r⃗, c, unstreched_length)
            f⃗_damping = (scalar_projection(v⃗_source, r⃗) .- scalar_projection(v⃗_dest, r⃗)) * r⃗ ./ norm(r⃗) * d_spring
            
            e .= f⃗_spring .+ f⃗_damping .+ dirac_impulse(t)
            nothing
        end

        @inline Base.@propagate_inbounds function rodedge!(e, vertex_src, vertex_dst, params, t)
            v_source = @views velocity(vertex_src)
            v_dest = @views velocity(vertex_dst)
            r = displacement(vertex_src) .- displacement(vertex_dst)

            d_rod = 1e6

            damping_force = (scalar_projection(v_source, r) .- scalar_projection(v_dest, r)) .* r ./ norm(r) .* d_rod
            
            e .= @views damping_force
            nothing
        end
        
        
        @inline Base.@propagate_inbounds function massvertex!(dstate, state, edges_src, edges_dst, p, t)
            m, actuation_power = @views p
            v⃗ = @views velocity(state)

            edge_acceleration = (vector_sum(edges_dst) - vector_sum(edges_src)) ./ m
            
            dstate[1:3] .= @views v⃗ 
            dstate[4:6] .= @views if actuation_power > 0.0 && norm(v⃗) > 0.01 && are_pointing_in_same_direction(dstate[1:3], dstate[4:6])
                max_applied_force = 500 #N
                actuaction_force = 2.0 * actuation_power ./ norm(v⃗)
                capped_actuation_force = sign(actuaction_force) * min(abs(actuaction_force), max_applied_force)
                
                # edge_acceleration .+ gravity .+ dirac_impulse(t)
                edge_acceleration .+ gravity .+ (capped_actuation_force .* v⃗ ./ norm(v⃗) ./ m)
            else
                edge_acceleration .+ gravity
            end
            nothing
        end
            
        # Constructing the NetworkDynamics graph
        function get_vetex_function(vertex_index)
            if get_prop(g, vertex_index, :fixed)
                fixed_state_vector = vcat(get_prop(g, vertex_index, :init_pos), zeros(3))
                vertex_name = "node_" * string(get_prop(g, vertex_index, :id))
                return NetworkDynamics.StaticVertex(f! = f! = (e, v_s, v_d, p, t) -> e .= fixed_state_vector, dim = 6)
            else
                return NetworkDynamics.ODEVertex(f! = massvertex!, dim=6)
            end
        end

        function get_edge_function(edge_index)
            if  get_prop(g, edge_index, :type) == "spring"
                return StaticEdge(f! = springedge!, dim = 3)
            else
                # return StaticEdge(f! = springedge!, dim = 3)
                return StaticEdge(f! = rodedge!, dim = 3)
            end
        end

        nd_vertecies = vertices(g) .|> get_vetex_function
        nd_edges =  edges(g) .|> get_edge_function
        nd = network_dynamics(nd_vertecies, nd_edges, g.graph, parallel=false)

        ### Simulation
        function nd_wrapper!(dx, x, p, t)
            # converting the parameter vector to a vector of tuples is nessecary, because we are required to have one 
            # vector in optimization but actually want to map 2 parameters to any edge
            nd(dx, x, (p[1], p[2]), t)
        end

        return nd_wrapper!
    end

    function get_inital_conditions(g)
        return map(v -> vcat(get_prop(g, v, :init_pos), zeros(3)), vertices(g)) |> Iterators.flatten |> collect
    end

    function get_simulation_parameters(g)
        to_float(x) = convert(Float64, x)
        
        param_vec_for_edge(e) = begin
            c = get_prop(g, e, :type) == "spring" ?  get_prop(g, e, :spring_stiffness) |> to_float : c_stiff |> to_float
            l = get_prop(g, e, :length) |> to_float
            return (c,l)
        end

        param_vec_for_vertex(v) = begin 
            if (get_prop(g, v, :active_user))
                return (get_prop(g, v, :m) |> to_float, get_prop(g, v, :actuation_power) |> to_float)
            else
                return (get_prop(g, v, :m)|> to_float, 0.0)
            end
        end
    
        return (vertices(g) .|> param_vec_for_vertex, edges(g) .|> param_vec_for_edge)
    end

    function run_simulation(g; fps=30, tspan=(0., 10.))
        u0 = get_inital_conditions(g)
        params = get_simulation_parameters(g)

        ode_problem = ODEProblem( get_equations_of_motion(g), u0, tspan, params )

        # make sure that the simulation can be aborted using InterruptException
        # TODO figure out why this triggers twice as much as it's suppoose to (mind the 2; should be 1) 
        check_interrupt_callback = FunctionCallingCallback((_, _, _) -> yield())
        
        return @time solve(ode_problem,
            TRBDF2(),
            abstol=5e-1,
            reltol=1e-1,
            saveat=1/fps,
            # save_everystep=false,  # the simulation result is implicitly saved whenever a callback is triggered
            callback=check_interrupt_callback
        );
    end
end
