module Simulator
    using NetworkDynamics
    using LightGraphs
    using OrdinaryDiffEq
    using LinearAlgebra
    using MetaGraphs
    using DiffEqBase
    using DiffEqCallbacks

    export run_simulation

    c_stiff = 1e6
    gravity = [0, 0, -9.81]

    # The Dirac function is a 'infinitely' large and 'infinitely' short impulse at x=0 
    # https://en.wikipedia.org/wiki/Dirac_delta_function
    # as a approaches 0, the function will become more 'extreme'
    dirac_delta = (x, a) -> 1 / (a * √π) * exp(1)^(-(x/a)^2)
    dirac_impulse = (t) -> dirac_delta(t, 1/20)
    # Test out how the function looks like in the first second
    # (-0.5:0.01:0.5 .|> x -> dirac_delta(x, 1/20)) |> plot

    function spring_force_from_displacement_vector(r, c, unstreched_length)
        return @views r * (1 - (unstreched_length ./ norm(r))) * c
    end

    function get_equations_of_motion(g, with_dirac=false)
        displacement = v -> @views [v[1],v[2],v[3]]
        velocity = v -> @views [v[4], v[5], v[6]]

        
        @inline Base.@propagate_inbounds function springedge!(e, vertex_src, vertex_dst, params, t)
            d_spring =  20.0

            v⃗_source = velocity(vertex_src)
            v⃗_dest = velocity(vertex_dst)
            c, unstreched_length = params
            r⃗ = displacement(vertex_src) - displacement(vertex_dst)

            scalar_projection = v -> dot(v, (r⃗ ./ norm(r⃗)))
            
            f⃗_spring = spring_force_from_displacement_vector(r⃗, c, unstreched_length)
            f⃗_damping = (scalar_projection(v⃗_source) .- scalar_projection(v⃗_dest)) * r⃗ ./ norm(r⃗) * d_spring
            
            e .= @views f⃗_spring + f⃗_damping
            nothing
        end

        @inline Base.@propagate_inbounds function rodedge!(e, vertex_src, vertex_dst, params, t)
            v_source = velocity(vertex_src)
            v_dest = velocity(vertex_dst)
            r = displacement(vertex_src) - displacement(vertex_dst)

            d_rod = 1e6

            scalar_projection = v -> dot(v, (r ./ norm(r)))
            damping_force = (scalar_projection(v_source) .- scalar_projection(v_dest)) * r ./ norm(r) * d_rod
            
            e .= @views damping_force
            nothing
        end
        
        
        @inline Base.@propagate_inbounds function vector_sum(array, n=3)
            reduce((acc, elem) -> acc .+ elem, array, init=zeros(n))
            # accumulate(+, array, dims=n)
        end
        
        @inline Base.@propagate_inbounds function massvertex!(dstate, state, edges_src, edges_dst, p, t)
            m, actuation_power = p
            v⃗ = velocity(state)

            intertia = (vector_sum(edges_dst) - vector_sum(edges_src)) ./ m
            
            a⃗ = intertia .+ gravity
            
            if actuation_power > 0.0 && norm(v⃗) > 0.01
                actuaction_force = actuation_power .* v⃗ ./ norm(v⃗)
                a⃗ = a⃗ .+ (actuaction_force ./ m)
                # a⃗ = a⃗ .+ dirac_impulse(t)
            end

            dstate .= @views [v⃗; a⃗]
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

    function get_simulation_parameters(g, actuation_power=0., c_stiff=c_stiff)
        param_vec_for_edge(e) = begin
            c = get_prop(g, e, :type) == "spring" ?  get_prop(g, e, :spring_stiffness) : c_stiff 
            l = get_prop(g, e, :length)
            return (c,l)
        end

        param_vec_for_vertex(v) = begin 
            if (get_prop(g, v, :active_user))
                return (get_prop(g, v, :m), actuation_power)
            else
                return (get_prop(g, v, :m), 0)
            end
        end
    
        return (vertices(g) .|> param_vec_for_vertex, edges(g) .|> param_vec_for_edge)
    end


    function run_simulation(g; fps=30, actuation_power=0., tspan=(0., 5.))
        u0 = get_inital_conditions(g)

        ode_problem = ODEProblem(
            get_equations_of_motion(g),
            u0,
            tspan,
            get_simulation_parameters(g, actuation_power)
        )

        # make sure that the simulation can be aborted using InterruptException
        # TODO figure out why this triggers twice as much as it's suppoose to (mind the 2; should be 1) 
        check_interrupt_callback = FunctionCallingCallback((_, _, _) -> yield())
        
        return @time solve(ode_problem,
            TRBDF2(),
            abstol=1e-2,
            reltol=1e-2,
            saveat=1/fps,
            # save_everystep=false,  # the simulation result is implicitly saved whenever a callback is triggered
            callback=check_interrupt_callback
        );
    end
end