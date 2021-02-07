using NetworkDynamics
using LightGraphs
using OrdinaryDiffEq
using LinearAlgebra
using MetaGraphs
using DiffEqBase

# using Revise
# import TrussFab

# using ForwardDiff

# TODO human actuation / actuate with x power
# TODO reimplement heuristics from the paper
# TODO interactivity
# TODO gorund collision detection
# TODO simulate strucute such that it damps away
# TODO test dragon

# TODO write paper tech sections
# TOD ask Thijs for recordings
# TODO plot pca'ed phase plot with vector field 

# TODO checkout whether a different linear solver offers speedup
# https://diffeq.sciml.ai/stable/features/linear_nonlinear/

# TODO equilibrium initiazation

# TODO find out how to get acceleration without adding it to the state
# TODO make a nice dataframe from the solution that is properly traversable 
# TODO take a closer look at NetworkDynamics

# TODO implement user & trace

c_stiff = 1e6
d_stiff = 1e6
d = 100.0
m = 10.0
grav = [0, 0, -9.81]
# unstreched_length = 0.65
actuation_ratio = -0.1

function spring_force_from_displacement_vector(r, c, unstreched_length)
    return @views r * (1 - (unstreched_length ./ norm(r))) * c
end

function get_equations_of_motion(g)
    displacement = v -> @views [v[1],v[2],v[3]]
    # displacement = v -> @views v[1:3]
    velocity = v -> @views [v[4], v[5], v[6]]
    
    @inline Base.@propagate_inbounds function springedge!(e, vertex_src, vertex_dst, params, t)
        v_source = velocity(vertex_src)
        v_dest = velocity(vertex_dst)
        c, unstreched_length = params
        
        r = displacement(vertex_src) - displacement(vertex_dst)
        scalar_projection = v -> dot(v, (r ./ norm(r)))
        
        spring_force = spring_force_from_displacement_vector(r, c, unstreched_length)
        damping_force = (scalar_projection(v_source) .- scalar_projection(v_dest)) * r ./ norm(r) * d
        
        e .= @views spring_force + damping_force
        nothing
    end
    
    @inline Base.@propagate_inbounds function vector_sum(array, n=3)
        reduce((acc, elem) -> acc .+ elem, array, init=zeros(n))
        # accumulate(+, array, dims=n)
    end
    
    @inline Base.@propagate_inbounds function massvertex!(dv, v, edges_src, edges_dst, p, t)
        velocity(v) = @views [v[4], v[5], v[6]]

        actuation_acceleration = velocity(v) * actuation_ratio
        acceleration =  (((vector_sum(edges_dst) - vector_sum(edges_src)) / m) + grav) .+ actuation_acceleration
        dv .= @views [velocity(v)..., acceleration...]
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

    nd_vertecies = map(get_vetex_function, vertices(g))
    nd_edges =  [StaticEdge(f! = springedge!, dim = 3) for x in range(1, stop=ne(g))]
    nd = network_dynamics(nd_vertecies, nd_edges, g.graph)
    
    ### Simulation
    function nd_wrapper!(dx, x, p, t)
        # converting the parameter vector to a vector of tuples is nessecary, because we are required to have one 
        # vector in optimization but actually want to map 2 parameters to any edge
        nd(dx, x, (nothing, p), t)
    end

    return nd_wrapper!
end

function get_inital_conditions(g)
    return map(v -> vcat(get_prop(g, v, :init_pos), zeros(3)), vertices(g)) |> Iterators.flatten |> collect
end

function get_initial_parameters(g)
    function param_vec_for_edge(e)
        c = get_prop(g, e, :type) == "spring" ?  get_prop(g, e, :spring_stiffness) : c_stiff 
        l = get_prop(g, e, :length)
        return (c,l)
        # return c
    end
    return map(param_vec_for_edge, edges(g))
end

function run_simulation(g, fps=30)
    tspan = (0., 10.)
    u0 = get_inital_conditions(g)

    ode_problem = ODEProblem(
        get_equations_of_motion(g),
        u0,
        tspan,
        get_initial_parameters(g)
    )

    return @time solve(ode_problem, Rodas3(), abstol=1e-4, saveat=range(tspan..., step=1/fps));
end

function run_steady_state(g)
    tspan = (0., 10.)
    u0 = get_inital_conditions(g)

    ode_problem = ODEProblem(
        get_equations_of_motion(g),
        u0,
        tspan,
        get_initial_parameters(g)
    )

    return @time solve(ode_problem, DynamicSS(Tsit5()));
end


function get_initial_parameters2(g, ks = [1,2,3])
    current_k_index = 1
    function param_vec_for_edge(e)
        l = get_prop(g, e, :length)
        if get_prop(g, e, :type) == "spring"
            c = ks[current_k_index]
            current_k_index = current_k_index + 1
            return (c, l)
        else 
            return (c_stiff, l)
        end
    end
    return map(param_vec_for_edge, edges(g))
end

function run_simulation2(ks)
    tspan = (0., 5.)
    u0 = get_inital_conditions(g)
    params = get_initial_parameters2(g, ks)
    ode_problem = ODEProblem(
        get_equations_of_motion(g),
        # for ForwardDiff to work, make sure that state variables are also duals if params are duals
        # u0 .|> ForwardDiff.Dual{Float64},
        u0,
        tspan,
        params
    )

    return @time solve(ode_problem, Rodas3(), abstol=1e-3, reltol=1e-1);
end


function ground_collision_loss(sol)
    result = 0
    for (i, col) in enumerate(eachcol(sol))
        if (i % 6 == 3)
            result = result + (filter(val -> sign(val) == -1, col) |> sum |> abs)
        end
    end
    result
end


function loss(ks)
    run_simulation2(ks) |> ground_collision_loss
end

nothing

# plot(run_simulation2([1, 2, 3]))

# sol = run_simulation2([10])

# k_sweep = [0:10...]  * 3e3

# sweep_space = Iterators.product(k_sweep, k_sweep) |> Iterators.collect
# optimize_space = sweep_space .|> ks -> loss([ks[1], ks[2], 1e4])
# optimize_space = sweep_space.|> ks -> sum(ks)

# my_cg = cgrad([:blue, :red])
# f = (x,y) -> optimize_space[x,y]
# plot([1:11...], [1:11...], f, st=:surface,c=my_cg,camera=(30,30))
# optimize_space[x,y]
# plot()

# using GraphRecipes
# graphplot(g)
# plot(optimize_space)

# Iterators.product(k_sweep, k_sweep) .|> println
# k_sweep
# res = k_sweep .|> k -> loss([k, k, k])
# plot(res)


# ForwardDiff.gradient(loss, [0.0])
# using Optim
# options = Optim.Options(g_tol = 1e-6, iterations = 50, store_trace = true, show_trace = true)
# res = optimize(loss, [100.0], GradientDescent(), options, autodiff=:forward)
# Optim.minimizer(res)
# Opt

# using ForwardDiff
# plot_matrix(m) = heatmap(m, color = :greys, yflip = true)

# function get_matrices(g)
#     range3(i) = (i-1)*3+1:(i-1)*3+3
#     vertexID2matrixIndex(vid) = findfirst(x-> x == vid, vertex_matrix_pos_map)
    
#     isfixed(vid) = get_prop(g, vid, :fixed)
    
#     # TODO move to own function    
#     vertex_matrix_pos_map = vertices(g) |> vertices -> filter(m -> !get_prop(g, m, :fixed), vertices) 
#     masses = vertex_matrix_pos_map |>  vertices -> map(a -> get_prop(g, a, :m) * ones(3), vertices) |> Iterators.flatten |> Iterators.collect
#     M = Diagonal(masses)

#     K = zeros(Float64, size(M)... )
    
#     for e in edges(g)
#         displacement_original = get_prop(g, e.src, :init_pos) - get_prop(g, e.dst, :init_pos) 
#         spring_stiffness = get_prop(g, e, :spring_stiffness)
#         l = get_prop(g, e, :length)
#         if spring_stiffness == Inf
#             spring_stiffness = c_stiff
#         end

#         spring_force(r) = spring_force_from_displacement_vector(r, spring_stiffness, l)
#         jac = ForwardDiff.jacobian(spring_force, displacement_original)
#         jac2 = ForwardDiff.jacobian(spring_force, -displacement_original)
        
#         if !isfixed(e.src)
#             K[e.src |> vertexID2matrixIndex |> range3, e.src |> vertexID2matrixIndex |> range3] += jac
#         end

#         if !isfixed(e.dst)
#             K[e.dst |> vertexID2matrixIndex |> range3, e.dst |> vertexID2matrixIndex |> range3] += jac2
#         end
        
#         if !isfixed(e.src) && !isfixed(e.dst)
#             # TODO use Symmertic type for K and simplify these lines
#             K[e.src |> vertexID2matrixIndex |> range3, e.dst |> vertexID2matrixIndex |> range3] -= jac
#             K[e.dst |> vertexID2matrixIndex |> range3, e.src |> vertexID2matrixIndex |> range3] -= jac2
#         end
#     end
#     return (M, K)
# end

# M, K = get_matrices(g)
# K |> plot_matrix

# plot_matrix(K)
# λ, v = eigen(inv(M) * K)

# freqs = sqrt.(λ) / (2*pi)
# scatter(freqs)
# freqs

# plot_matrix(v)
# scatter(sort(v[:, 1]))

# TODO simulate different eigenmodes by applying displacements to the strcture as initial conditions
# TODO plot displacement

nothing

# using DiffEqSensitivity
# using Flux: ADAM
# using DiffEqFlux
# σ = get_initial_parameters(g)
# u0 = get_inital_conditions(g)
# probflux = ODEProblem(get_equations_of_motion(g), u0, tspan, σ)

# function predict(p)
#   ## default sensealg is InterpolatingAdjoint
#   solve(probflux, Tsit5(), p = p, saveat=tspan[1]:.01:tspan[end], sensealg=ForwardDiffSensitivity())
# end

# losses = [+Inf]

# function loss(p)
#   pred = predict(p)[7:7, :]
#   # converge to 0 as fast as possible
#   # println(pred[6:8, :])
#   loss = sqrt(sum(abs2, pred))
#   loss, pred
# end

# cb = function (p, l, pred) # callback function to observe training
#   print(l)
#   print(", ")
#   # println(" params = ", σ )
# #   display(plot(pred[18, :], pred[19, :], pred[20, :]))
#     display(pred)
#   return false
# end

# cb(σ, loss(σ)...)

# # A crucial thing to realize is that sciml_train works best with Arrays of parameters
# # We optimize for optimal local diffusion constants
# res = DiffEqFlux.sciml_train(loss, σ, ADAM(3), cb = cb, maxiters=300)
# res
# res.minimizer
# #res = DiffEqFlux.sciml_train(loss, σ, BFGS(), cb = cb)


# ### Next Steps

# # round shaped phase space plot
# # trusscilator JSON file importer 
