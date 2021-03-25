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
using DiffEqCallbacks
include("./rigidGroupDetection.jl")

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

function rotate_vec(axis, point, angle)
    # TODO change the rotate function to sth that does not use StaticArrays / that can do stuff in-place
    return UnitQuaternion(AngleAxis(angle, axis.normal...)) * point
end

function get_rigid_group_ode(rotation_axis::Line, point_masses::AbstractVector{PointMass})


    function get_torque(force_vec, pos, angle)
        torque_vec = cross(force_vec, rotate_vec(rotation_axis, pos, angle))
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

function get_spring_ode(src_point::Point, src_rotation_axis::Line, dst_point::Point, dst_rotation_axis::Line)
    # TODO spring damping
    src_angle_to_vector(angle) = UnitQuaternion(AngleAxis(angle, src_rotation_axis.normal...)) * src_point
    dst_angle_to_vector(angle) = UnitQuaternion(AngleAxis(angle, dst_rotation_axis.normal...)) * dst_point

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


function bitvector_to_poslist(bitvector::AbstractArray{Bool})
    return [i for (i, bool) in enumerate(bitvector) if bool]
end

function run_simulation(g::MetaGraph, tspan=(0.0, 10.), fps=30)
    
    # --- Build new reduced graph ---
    rigid_groups = get_rigid_groups(g)
    rigid_group_point_masses = []
    rigid_group_rotation_axes = []
    reduced_g = Graph(length(rigid_groups))

    ode_vertices = []

    for vertices_in_rigid_group in bitvector_to_poslist.(rigid_groups)
        # TODO get rotation axis
        rot_axis = Line([0.0,0.0,0.0],[1.0,0.0,0.0])
        point_masses = [PointMass(get_prop(g, vertex, :init_pos), get_prop(g, vertex, :m)) for vertex in vertices_in_rigid_group]
        push!(rigid_group_point_masses, point_masses)
        push!(rigid_group_rotation_axes, rot_axis)
        push!(ode_vertices, get_rigid_group_ode(rot_axis, point_masses))
    end
    
    ode_edges = []
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            src_point = Point(get_prop(g, e.src, :init_pos))
            dst_point = Point(get_prop(g, e.dst, :init_pos))
            push!(ode_edges, get_spring_ode(src_point, rigid_group_rotation_axes[e.src], dst_point, rigid_group_rotation_axes[e.dst]))
            add_edge!(reduced_g, findfirst(bitvector -> bitvector[e.src], rigid_groups), findfirst(bitvector -> bitvector[e.dst], rigid_groups))
        end
    end
    
    # --- instantiate the ODE Problem ---
    # two angles for every group
    u0 = zeros(nv(reduced_g)*2)
    nd = network_dynamics(ode_vertices, ode_edges, reduced_g)

    function nd_wrapper!(dx, x, p, t)
        nd(dx, x, (nothing, p), t)
    end
    gplot(reduced_g)
    params = [(1000, 0.6) for _ in ode_edges]
    ode_problem = ODEProblem(nd_wrapper!, u0, tspan, params)

    check_interrupt_callback = FunctionCallingCallback((_, _, _) -> yield())   
    
    return sol = @time solve(ode_problem, TRBDF2(), abstol=5e-1, reltol=1e-1, saveat=1/fps, callback=check_interrupt_callback );
    # --- map simplified state back to vectors ---

    result = zeros(nv(g)*6, length(sol.t))
    # for (row_id, row) in enumerate(eachrow(sol'))
    #     for (vertex_id, state) in enumerate(Iterators.partition(row, 2))
    #         θ, ω = state
    #         rot_axis = rigid_group_rotation_axes[vertex_id]
    #         for point_mass in rigid_group_point_masses[vertex_id]
    #             result[row_id, ] = rotate_vec(rot_axis, point_mass.pos, θ)
    #             result[row_id, ] = rotate_vec(rot_axis, point_mass.pos, ω)
    #         end
    #     end
    # end
    for (vertex_id, state) in enumerate(Iterators.partition(eachcol(sol'), 2))
        θ, ω = state
        rot_axis = rigid_group_rotation_axes[vertex_id]
        # return
        for point_mass in rigid_group_point_masses[vertex_id]
            positions::AbstractArray{Float64, 2} = cat([Array(row...) for row in eachrow(map(angle -> rotate_vec(rot_axis, point_mass.pos, angle), θ))]..., dims=2)
            velocities::AbstractArray{Float64, 2} = cat([Array(row...) for row in eachrow(map(angle -> rotate_vec(rot_axis, point_mass.pos, angle), ω))]..., dims=2)
            # return positions
            result[vertex_id*6 - 5:vertex_id*6 - 3, :] = positions
            result[vertex_id*6 - 2:vertex_id*6 - 0, :] = velocities
        end
    end
    return result
end



g = TrussFab.import_trussfab_file("./test_models/seesaw_3.json")


function get_rotation_axes(g)
    isfixed(g, rigid_group) = length([v for v in vertices(g) if v in rigid_group && get_prop(g, v, :fixed)]) >= 3 
    
    g = deepcopy(g)
    remove_spring_edges!(g )
    rigid_groups = get_rigid_groups(g) .|> bitvector_to_poslist
    
    fixed_group = reduce(∪, filter(r -> isfixed(g, r), rigid_groups))

    free_groups = filter(r -> !isfixed(g, r), rigid_groups)

    intersection_tuples = free_groups .|> r -> reduce(∪, r .|> v -> neighbors(g, v)) ∩ fixed_group
    show(intersection_tuples[1][1])
    get_pos(vertex_id) = get_prop(g, vertex_id, :init_pos)
    return intersection_tuples .|> ps -> Line(Point(get_pos(ps[1])), Point(normalize(get_pos(ps[1]) - get_pos(ps[2]))))
end

get_rotation_axes(g)
Point(ones(3))
rotation_axes = []
# find connecting edges 
for i in 1:length(a)
    for j in i:length(a)
        fixed, free = if isfixed(g, a[i])
            a[i], a[j]
        elseif isfixed(g, a[j])
            a[j], a[i]
        else
            continue
            # throw(ErrorException("unsupported rigid group configuration: currently only moving rigid groups that are mounted to a fixed base are supported"))
        end

        neighbourhood_of_free = reduce(∪, free .|> v -> neighbors(g, v))
        push!(rotation_axes, neighbourhood_of_free ∩ fixed)
    end
end

rotation_axes


a[1] .| a[2] .| a[3]
a[1]
nv(g)
s = run_simulation(g)
plot(s')
nothing


# point_mass = PointMass([1.0,2.0,3.0] ,10)
# rot_axis = Line([0.0,0.0,0.0],[1.0,0.0,0.0])

# reshape(sol, (301, :))
# plot(transpose(sol)[20])
# @time get_rigid_groups(g)

nodelabel = 1:nv(g)
gplot(g, nodelabel=nodelabel)

# function run_example_simulation()
#     rot_axis = Line([0.0,0.0,0.0],[1.0,0.0,0.0])
#     rigid_group_ode1 = get_rigid_group_ode(rot_axis, [PointMass([1.0,2.0,3.0] ,10),PointMass([1.0,2.0,30.0] ,1), PointMass([1.0,2.0,1.0], 5)])
#     rigid_group_ode2 = get_rigid_group_ode(rot_axis, [PointMass([1.0,2.0,-3.0] ,2),PointMass([-1.0,2.0,15.0] ,10), PointMass([1.0,2.0,1.0], 5)])
#     spring_connector = get_spring_ode(Point([1.0,2.0,1.0]), rot_axis, Point([1.1,2.1,1.1]), rot_axis)
    
#     N = 2
#     u0 = zeros(N*2)
#     g = LightGraphs.Graph(N)
#     add_edge!(g, 1, 2)
#     nd_vertecies = [rigid_group_ode1, rigid_group_ode2]
#     nd_edges = [spring_connector]
#     nd = network_dynamics(nd_vertecies, nd_edges, g, parallel=false)
        
#     function nd_wrapper!(dx, x, p, t)
#         nd(dx, x, (nothing, p), t)
#     end
#     params = [(100000, 0.1)]
#     ode_problem = ODEProblem(nd_wrapper!, u0, (0.0, 10.), params)
    
#     return @time solve(ode_problem, TRBDF2(), abstol=5e-1, reltol=1e-1 );
# end

# plot(run_example_simulation()')
# function run_benchmark()
#     a = ones(2)
#     b = ones(2)
#     @time one_dof_rigid_group(a, b, [ones(7)], [ones(7).*10], (
#         Line([0.0,0.0,0.0],[1.0,0.0,0.0]),
#         [PointMass([1.0,2.0,3.0] ,10), PointMass([1.0,2.0,1.0], 5)])
#         )
# end