using NetworkDynamics
using LightGraphs
using Plots
using OrdinaryDiffEq
using LinearAlgebra

using Revise
import TrussFab

g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

c_stiff = 1e6
d = 1000.0
m = 10.0
grav = [0, 0, -9.81]
m_fixture = 1e6

unpack_displacement = v -> @views [v[1],v[2],v[3]]
unpack_velocity = v -> @views [v[4], v[5], v[6]]

function diffusionedge!(e, v_s, v_d, p, t)
    r_source = unpack_displacement(v_s)
    r_dest = unpack_displacement(v_d)
    v_source = unpack_velocity(v_s)
    v_dest = unpack_velocity(v_d)
    c_, l_ = p
    
    scalar_projection = v -> dot(v ,(r ./ norm(r)))

    r = r_source - r_dest
    spring_force = r * (1 - (l_ / norm(r))) * c_
    damping_force = (scalar_projection(v_source) - scalar_projection(v_dest)) * r / norm(r) * d

    e .= spring_force + damping_force
    nothing
end


function diffusionvertex!(dv, v, e_s, e_d, p, t)
    r_displacement = unpack_displacement(v)
    v_velocity = unpack_velocity(v)

    fsum = (array) -> reduce((acc, elem) -> acc + elem, array, init=zeros(3))
    a_acceleration =  ((fsum(e_d) - fsum(e_s)) / m) + grav

    dv .= @views [v_velocity..., a_acceleration...]
    nothing
end

# Constructing the NetworkDynamics graph
function get_vetex_function(vertex_index)
    if get_prop(g, vertex_index, :fixed)
        fixed_state_vector = vcat(get_prop(g, vertex_index, :init_pos), zeros(3))
        # return ODEVertex(f! = staticvertex!, dim=6)
        return StaticVertex(f! = f! = (e, v_s, v_d, p, t) -> e .= fixed_state_vector, dim = 6)
    else
        return ODEVertex(f! = diffusionvertex!, dim=6)
    end
end

nd_vertecies = map(get_vetex_function, vertices(g))
nd_edges =  [StaticEdge(f! = diffusionedge!, dim = 3) for x in range(1, stop=ne(g))]
nd = network_dynamics(nd_vertecies, nd_edges, g)

### Simulation
function nd_wrapper!(dx, x, p, t)
  nd(dx, x, (nothing, p), t)
end

function param_vec_for_edge(e)
    c = get_prop(g, e, :type) == "spring" ?  get_prop(g, e, :spring_stiffness) : c_stiff 
    l = get_prop(g, e, :length)
    return (c,l)
end

u0 = map(v -> vcat(get_prop(g, v, :init_pos), zeros(3)), vertices(g)) |> Iterators.flatten |> collect

tspan = (0., 5.)
params = map(param_vec_for_edge, edges(g))
ode_prob = ODEProblem(nd_wrapper!, u0, tspan, params)

@time sol = solve(ode_prob, Rodas3(), abstol=1e-3, progress=true);

plot(sol[1, :], sol[2, :], sol[3, :])
plot(sol[19, :], sol[20, :], sol[21, :])
plot(transpose(sol[19:19, :]))

sol[1, :]

function plot_vertex(index)
    start_index = (index - 1) * 6
    plot!(sol[start_index+1, :], sol[start_index + 2, :], sol[start_index + 3, :])
end

for v in vertices(g)
    plot_vertex(v)
end

plot_vertex(8)
