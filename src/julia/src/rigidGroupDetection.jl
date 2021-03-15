using MetaGraphs
using LightGraphs
using Revise
using LinearAlgebra
using GraphPlot
include("TrussFab.jl")
# import TrussFab
using Plots
using GraphPlot

# relies on vertecies having for n vertecies 1:n as lables for vertecies
# g = TrussFab.import_trussfab_file("src/julia/test_models/chair.json", false)
g = TrussFab.import_trussfab_file("src/julia/test_models/dragon.json", false)
# g = TrussFab.import_trussfab_file("src/julia/test_models/seesaw_3.json", false)
# g = TrussFab.import_trussfab_file("src/julia/test_models/simple_seesaw.json", false)
# g = TrussFab.import_trussfab_file("src/julia/test_models/sketchup_tetrahedron.json", false)
# remove_spring_edges!(g)
gplot(g)

function remove_spring_edges!(g)
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            rem_edge!(g, e)
        end
    end
end
# relies on vertecies having for n vertecies 1:n as lables for vertecies
# g = TrussFab.import_trussfab_file("src/julia/test_models/seesaw_3.json")
# g = TrussFab.import_trussfab_file("src/julia/test_models/sketchup_tetrahedron.json")

remove_spring_edges!(g)
gplot(g)


# in Cpp et al one would just do i*3 but julia uses indexing starting with one.
# so it has to be offset this way otherwise, the first index would be i * 3 = 1 * 3 = 3 and not 1
offset_index = (i, o) -> (i - 1) * o + 1

# function get_rigidity_matrix(g)
#     total_fixed=0
#     fixed_nodes=[]
#     for v in vertices(g)
#         if get_prop(g,v,:fixed)
#             total_fixed+=1
#             append!(fixed_nodes,v)
#         end
#     end
#     R = zeros(ne(g)+total_fixed*3, nv(g)*3)
#     for (i, e) in enumerate( edges(g))
#         tuple = get_prop(g, e.src, :init_pos) - get_prop(g, e.dst, :init_pos)
#         R[i, offset_index(e.src, 3):offset_index(e.src, 3)+2] = tuple
#         R[i, offset_index(e.src, 3):offset_index(e.src, 3)+2] = -tuple
#     end
#     print(fixed_nodes)
#     for i in fixed_nodes
#         R[ne(g)+3*(i-1)+1,3*(i-1)+1]=1
#         R[ne(g)+3*(i-1)+2,3*(i-1)+2]=1
#         R[ne(g)+3*(i-1)+3,3*(i-1)+3]=1
#     end
#     return R
# end

function get_rigidity_matrix(g)
    R = zeros(ne(g), nv(g) * 3)
    for (i, e) in enumerate(edges(g))
        tuple = get_prop(g, e.src, :init_pos) - get_prop(g, e.dst, :init_pos)
        # println("tuple=",tuple)
        R[i, offset_index(e.src, 3):offset_index(e.src, 3) + 2] = tuple
        R[i, offset_index(e.dst, 3):offset_index(e.dst, 3) + 2] = -tuple
    end

    # add boundry conditions ie. set fixed nodes
    for fixed_vertex in filter(n -> get_prop(g, n, :fixed), vertices(g))
        # new_row = (1:nv(g) .|> i -> i == fixed_vertex ? [1,0,0] : zeros(3)) |> Iterators.flatten |> Iterators.collect
        # show(new_row)
        new_row = zeros(nv(g) * 3)
        new_row[3 * (fixed_vertex - 1) + 1] = 1
        R = vcat(R, new_row')
        new_row = zeros(nv(g) * 3)
        new_row[3 * (fixed_vertex - 1) + 2] = 1
        R = vcat(R, new_row')
        new_row = zeros(nv(g) * 3)
        new_row[3 * (fixed_vertex - 1) + 3] = 1
        R = vcat(R, new_row')
        # R[ne(g)+3*(i-1)+1,3*(i-1)+1]=1
        # R[ne(g)+3*(i-1)+2,3*(i-1)+2]=1
        # R[ne(g)+3*(i-1)+3,3*(i-1)+3]=1
    end
    return R
end

function test_rigidity(g)
    return rank(get_rigidity_matrix(g)) == nv(g) * 3
end

test_rigidity(g)

function get_rigid_groups(g)
    RV = Any[]
    RG = Any[]
    R = get_rigidity_matrix(g)
    Rs = R' * R
    Vdim = nv(g)
    if rank(Rs) == Vdim * 3
        push!(RG, Array(1:size(Rs)[1]))
        return RG
    else
        n = nullspace(Rs)
        nullspace_ids = (sum(reshape((sum(abs.(n) .> 1e-10, dims=2)) .> 1e-10, (3, :)), dims=1)) .> 0
        push!(RG, .!nullspace_ids)
        push!(RV, zeros(Vdim * 3))
    end
    Rl = R
    while sum(nullspace_ids) > 0
        if rank(Rs) == Vdim * 3 - 1
            n = nullspace(Rs)
            rigid_group_ids = (sum(reshape((sum(abs.(n) .> 1e-10, dims=2)) .> 1e-10, (3, :)), dims=1)) .> 0
            push!(RG, rigid_group_ids)
            eigen_vector = eigvecs(Rs)[:,1]
            push!(RV, eigen_vector)
            fix_id = findfirst(rigid_group_ids)[2]
            new_row = zeros(Vdim * 3)
            new_row[3 * (fix_id - 1) + 1] = 1
            new_row[3 * (fix_id - 1) + 2] = 1
            new_row[3 * (fix_id - 1) + 3] = 1
            R = vcat(R, new_row')
            nullspace_ids = nullspace_ids - rigid_group_ids

            Rl = R

        else
            rigid_group_ids = (sum(reshape((sum(abs.(n) .> 1e-10, dims=2)) .> 1e-10, (3, :)), dims=1)) .> 0
            fix_id = findfirst(rigid_group_ids)[2]
            new_row = zeros(Vdim * 3)
            new_row[3 * (fix_id - 1) + 1] = 1
            new_row[3 * (fix_id - 1) + 2] = 1
            new_row[3 * (fix_id - 1) + 3] = 1
            Rl = vcat(Rl, new_row')
        end
        Rs = Rl' * Rl
    end
    return [RG,RV]
end

nv(g)

function get_symmetric_rigidity_matrix(g)
    R = get_rigidity_matrix(g)
    # return transpose(R) * R
    return transpose(R) * R
end

plot_matrix = m -> heatmap(m, color=:greys)


R = get_rigidity_matrix(g)
Rs = R' * R
# println("eigen value=",eigvals(Rs))
eigen_vectors = eigvecs(Rs)
# # println("eigen vector=",eigen_vectors)
# @time n = nullspace(Rs)

gplot(g)
plot_matrix(R)
plot_matrix(Rs)
plot_matrix(eigen_vectors)
plot_matrix(n)
# print(eigen_vectors[:,1])
(RG, RV) = get_rigid_groups(g)
