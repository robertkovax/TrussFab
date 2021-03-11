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

g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")

nodelabel = 1:nv(g)
gplot(g, nodelabel=nodelabel)

rigid_groups = [6:10, 11:20]
rigid_groups_rotation_axes = [[(1,0,0)], [(0,1,0)]]


@inline function distance(point::Point, line::Line)
    return norm(cross(point .- line.offset, line.normal)) / norm(line.normal)
end

@inline function intertia(rotation_axis::Line, point_masses::AbstractArray{PointMass, 1})
    return sum(point_masses .|> p::PointMass -> p.mass * distance(p.pos, rotation_axis)^2)
end

@inline Base.@propagate_inbounds function float_sum(array)
    if isempty(array)
        return zero(Float64)
    else
        return sum(array)
    end
end

@inline Base.@propagate_inbounds function springedge!(e, vertex_src, vertex_dst, params, t)
    d_spring =  20.0

    v⃗_source = velocity(vertex_src)
    v⃗_dest = velocity(vertex_dst)
    c, unstreched_length = @views params
    r⃗ = displacement(vertex_src) .- displacement(vertex_dst)
    
    f⃗_spring = spring_force_from_displacement_vector(r⃗, c, unstreched_length)
    f⃗_damping = (scalar_projection(v⃗_source, r⃗) .- scalar_projection(v⃗_dest, r⃗)) * r⃗ ./ norm(r⃗) * d_spring
    
    e .= f⃗_spring .+ f⃗_damping
    nothing
end

function one_dof_rigid_group(dstate, state, e_src, e_dst, params, t)
    θ, ω = state  # in radians
    # rotation_axis::Line, point_masses::AbstractArray{PointMass, 1} = @views params
    rotation_axis::Line, point_masses::AbstractArray{PointMass, 1} = get_parameters()
    # TODO radius to line instead of point
    get_src_anchor(e) = @views e[1:3]
    get_dst_anchor(e) = @views e[4:6]
    get_direction(e) = e[1:3] - e[4:6] ./ norm(e[1:3] .- e[4:6])
    get_force(e) = @views e[7]
    
    gravity = [0.0, 0.0, -9.81]
    damping_coefficent = 10.0
    
    function rotate(point::Point)
        return UnitQuaternion(AngleAxis(θ, rotation_axis.normal...)) * point
    end

    function get_torque(force_vec, pos) 
        torque_vec = cross(force_vec, rotate(pos))
        return sign(dot(torque_vec, rotation_axis.normal)) * norm(torque_vec)
    end

    τ = float_sum([get_torque(get_force(e) .* get_direction(e), get_src_anchor(e)) for e in e_src]) +
        float_sum([-get_torque(get_force(e) .* get_direction(e), get_dst_anchor(e)) for e in e_dst]) +
        float_sum([get_torque(point_mass.mass * gravity, point_mass.pos) for point_mass in point_masses]) +
        - damping_coefficent * ω

    α = τ ./ intertia(rotation_axis, point_masses)
    dstate .= [ω, α]
    nothing
end

function get_parameters()
    return ( Line([0.0,0.0,0.0],[1.0,0.0,0.0]), [PointMass([1.0,2.0,3.0] ,10),PointMass([1.0,2.0,30.0] ,1), PointMass([1.0,2.0,1.0], 5)])
end

u0 = zeros(3)

g = LightGraphs.Graph(1)
nd_vertecies = [ODEVertex(f! = one_dof_rigid_group, dim=2)]
nd_edges = []
nd = network_dynamics(nd_vertecies, nd_edges, g, parallel=false)

ode_problem = ODEProblem( nd, u0, (0.0, 100.))

sol = @time solve(ode_problem, Rodas3(), [] );

plot(sol')
nothing

function run_benchmark()
    a = ones(2)
    b = ones(2)
    @time one_dof_rigid_group(a, b, [ones(7)], [ones(7).*10], (
        Line([0.0,0.0,0.0],[1.0,0.0,0.0]),
        [PointMass([1.0,2.0,3.0] ,10), PointMass([1.0,2.0,1.0], 5)])
        )
end