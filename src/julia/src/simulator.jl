using NetworkDynamics
using LightGraphs
using Plots
using OrdinaryDiffEq
using LinearAlgebra
using Profile
using Revise
using PProf
using MetaGraphs
import TrussFab

c_stiff = 1e6
d = 1000.0
m = 10.0
grav = [0, 0, -9.81]
m_fixture = 1e6

function get_equations_of_motion(g)

    displacement = v -> @views [v[1],v[2],v[3]]
    velocity = v -> @views [v[4], v[5], v[6]]
    
    function springedge!(e, vertex_src, vertex_dst, params, t)
        v_source = velocity(vertex_src)
        v_dest = velocity(vertex_dst)
        c, unstreched_length = params
        
        r = displacement(vertex_src) - displacement(vertex_dst)
        
        scalar_projection = v -> dot(v, (r ./ norm(r)))
    
        spring_force = r * (1 - (unstreched_length ./ norm(r))) * c
        damping_force = (scalar_projection(v_source) .- scalar_projection(v_dest)) * r ./ norm(r) * d
    
        e .= @views spring_force + damping_force
        nothing
    end
    
    function vector_sum(array, n=3)
        reduce((acc, elem) -> acc .+ elem, array, init=zeros(n))
        # accumulate(+, array, dims=n)
    end
    
    function massvertex!(dv, v, edges_src, edges_dst, p, t)
        acceleration =  ((vector_sum(edges_dst) - vector_sum(edges_src)) / m) + grav
        dv .= @views [velocity(v)..., acceleration...]
        nothing
    end
    
    # Constructing the NetworkDynamics graph
    function get_vetex_function(vertex_index)
        if get_prop(g, vertex_index, :fixed)
            fixed_state_vector = vcat(get_prop(g, vertex_index, :init_pos), zeros(3))
            # return ODEVertex(f! = staticvertex!, dim=6)
            return StaticVertex(f! = f! = (e, v_s, v_d, p, t) -> e .= fixed_state_vector, dim = 6)
        else
            return ODEVertex(f! = massvertex!, dim=6)
        end
    end
    
    nd_vertecies = map(get_vetex_function, vertices(g))
    nd_edges =  [StaticEdge(f! = springedge!, dim = 3) for x in range(1, stop=ne(g))]
    nd = network_dynamics(nd_vertecies, nd_edges, g.graph)
    
    ### Simulation
    function nd_wrapper!(dx, x, p, t)
        # converting the parameter vector to a vector of tuples is nessecary, because we are required to have one 
        # vector in optimization but actually want to map 2 parameters to any edge
        nd(dx, x, (nothing, @views Iterators.partition(p, 2) |> Iterators.collect), t)
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
    end
    return map(param_vec_for_edge, edges(g)) |> Iterators.flatten |> Iterators.collect
end

g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

tspan = (0., 5.)
ode_problem = ODEProblem(
    get_equations_of_motion(g),
    get_inital_conditions(g),
    tspan,
    get_initial_parameters(g)
)

@time sol = solve(ode_problem, Rodas3(), abstol=1e-3, reltol=1e-1);

# @profile sol = solve(ode_problem, Rodas3(), abstol=1e-3, reltol=1e-1, progress=true);
# pprof()

plot(sol[1, :], sol[2, :], sol[3, :])
plot(sol[19, :], sol[20, :], sol[21, :])
plot(transpose(sol[19:19, :]))

sol[1, :]

Iterators.partition([1,2,3,4,5], 2) |> Iterators.collect

function plot_vertex(index)
    start_index = (index - 1) * 6
    plot!(sol[start_index+1, :], sol[start_index + 2, :], sol[start_index + 3, :])
end

for v in vertices(g)
    plot_vertex(v)
end

plot_vertex(8)

using DiffEqSensitivity

using Flux: ADAM
using DiffEqFlux
σ = get_initial_parameters(g)
u0 = get_inital_conditions(g)
probflux = ODEProblem(get_equations_of_motion(g), u0, tspan, σ)

function predict(p)
  ## default sensealg is InterpolatingAdjoint
  solve(probflux, Rodas3(), p = p, saveat=tspan[1]:.01:tspan[end], sensealg=ForwardDiffSensitivity())
end

losses = [+Inf]

function loss(p)
  pred = predict(p)
  # converge to 0 as fast as possible
  # println(pred[6:8, :])
  loss = sqrt(sum(abs2, pred))
  loss, pred
end

cb = function (p, l, pred) # callback function to observe training
  print(l)
  print(", ")
  # println(" params = ", σ )
  display(plot(pred[18, :], pred[19, :], pred[20, :]))
  return false
end

cb(σ, loss(σ)...)

# A crucial thing to realize is that sciml_train works best with Arrays of parameters
# We optimize for optimal local diffusion constants
res = DiffEqFlux.sciml_train(loss, σ, ADAM(3), cb = cb, maxiters=300)
res
res.minimizer
#res = DiffEqFlux.sciml_train(loss, σ, BFGS(), cb = cb)


### Next Steps

# round shaped phase space plot
# trusscilator JSON file importer 
# ground collisions
# interactivity1