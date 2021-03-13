using OrdinaryDiffEq
using DiffEqBase


using LinearAlgebra
using LightGraphs
using Plots
using Revise
using GraphPlot
import TrussFab
using MetaGraphs
using StaticArrays
using Rotations
using NetworkDynamics


Point = AbstractArray{Float64,1}

struct PointMass
    pos::Point
    mass::Float64
end 

struct Line
    offset::Point
    normal::Point
end

struct RigidGroup
    rotation_axis::Line
    point_masses::AbstractVector{PointMass}
end

g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

nodelabel = 1:nv(g)
gplot(g, nodelabel=nodelabel)

rigid_groups = [6:10, 11:20]
rigid_groups_rotation_axes = [[(1,0,0)], [(0,1,0)]]


@inline function distance(point::Point, line::Line)
    return norm(cross(point .- line.offset, line.normal)) / norm(line.normal)
end

@inline Base.@propagate_inbounds function float_sum(array)
    if isempty(array)
        return zero(Float64)
    else
        return sum(array)
    end
end

function get_rigid_group_ode(rotation_axis::Line, point_masses::AbstractVector{PointMass})

    function rotate(point, angle)
        return UnitQuaternion(AngleAxis(angle, rotation_axis.normal...)) * point
    end

    function get_torque(force_vec, pos, angle)
        torque_vec = cross(force_vec, rotate(pos, angle))
        return sign(dot(torque_vec, rotation_axis.normal)) * norm(torque_vec)
    end

    gravity = [0.0, 0.0, -9.81]
    damping_coefficent = 10.0
    intertia = sum(point_masses .|> p::PointMass -> p.mass * distance(p.pos, rotation_axis)^2)

    # TODO figure out how undirected nodes are handled here
    # TODO pull position handling also here

    f! = (dstate, state, e_src, e_dst, params, t) -> begin
        θ, ω = state  # in radians
        get_src_anchor(e) = @views [e[1], e[2], e[3]]
        get_dst_anchor(e) = @views [e[4], e[5], e[6]]
        get_direction(e) = get_src_anchor(e) .- get_dst_anchor(e) ./ norm(get_src_anchor(e) .- get_dst_anchor(e))
        get_force(e) = @views e[7]
        
        τ_src_spring = float_sum([get_torque(get_force(e) .* get_direction(e), get_src_anchor(e), θ) for e in e_src])
        τ_dst_spring = float_sum([-get_torque(get_force(e) .* get_direction(e), get_dst_anchor(e), θ) for e in e_dst])
        τ_gravity = float_sum([get_torque(point_mass.mass * gravity, point_mass.pos, θ) for point_mass in point_masses])
        τ_friction = - damping_coefficent * ω

        τ = τ_src_spring + τ_dst_spring + τ_gravity + τ_friction
        α = τ ./ intertia
        dstate .= [ω, α]
        nothing
    end
    return ODEVertex(f! = f!, dim=2)
end

function get_spring_ode(src_point_mass::PointMass, src_rotation_axis::Line, dst_point_mass::PointMass, dst_rotation_axis::Line)
    # TODO spring damping
    src_angle_to_vector(angle) = UnitQuaternion(AngleAxis(angle, src_rotation_axis.normal...)) * src_point_mass.pos
    dst_angle_to_vector(angle) = UnitQuaternion(AngleAxis(angle, dst_rotation_axis.normal...)) * dst_point_mass.pos

    f! = (e, vertex_src, vertex_dst, params, t) -> begin
        damping_coefficent =  10.0

        c, unstreched_length = params
        
        src_pos = src_angle_to_vector(vertex_src[1])
        dst_pos = dst_angle_to_vector(vertex_dst[1])
        r⃗ = src_pos .- dst_pos
        
        f_spring =  (norm(r⃗) - unstreched_length) * c
        
        e .= [src_pos..., dst_pos..., f_spring]
        nothing
    end

    return StaticEdge(f! = f!, dim=7)
end
rot_axis = Line([0.0,0.0,0.0],[1.0,0.0,0.0])
rigid_group_ode1 = get_rigid_group_ode(rot_axis, [PointMass([1.0,2.0,3.0] ,10),PointMass([1.0,2.0,30.0] ,1), PointMass([1.0,2.0,1.0], 5)])
rigid_group_ode2 = get_rigid_group_ode(rot_axis, [PointMass([1.0,2.0,-3.0] ,2),PointMass([-1.0,2.0,15.0] ,10), PointMass([1.0,2.0,1.0], 5)])
spring_connector = get_spring_ode(PointMass([1.0,2.0,1.0], 5), rot_axis, PointMass([1.1,2.1,1.1], 5), rot_axis)

function nd_wrapper!(dx, x, p, t)
    nd(dx, x, (nothing, p), t)
end

N = 2
u0 = zeros(N*2)
g = LightGraphs.Graph(N)
add_edge!(g, 1, 2)
nd_vertecies = [rigid_group_ode1, rigid_group_ode2]
nd_edges = [spring_connector]
nd = network_dynamics(nd_vertecies, nd_edges, g, parallel=false)

params = [(c, 0.1)]
ode_problem = ODEProblem(nd_wrapper!, u0, (0.0, 10.), params)

@time sol = solve(ode_problem, Rodas3(), [] );

display(plot(sol'))

function run_benchmark()
    a = ones(2)
    b = ones(2)
    @time one_dof_rigid_group(a, b, [ones(7)], [ones(7).*10], (
        Line([0.0,0.0,0.0],[1.0,0.0,0.0]),
        [PointMass([1.0,2.0,3.0] ,10), PointMass([1.0,2.0,1.0], 5)])
        )
end