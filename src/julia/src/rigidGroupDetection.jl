using MetaGraphs
using LightGraphs
using Revise
using LinearAlgebra
using GraphPlot
using Plots
using GraphPlot

function get_rigid_groups(g::MetaGraph)
    g2 = deepcopy(g)
    remove_spring_edges!(g2)
    rigidity_groups_bitvectors, tangent_vectors = get_rigid_groups_with_movement_vectors(g2)
    return rigidity_groups_bitvectors
end

function remove_spring_edges!(g)
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            rem_edge!(g, e)
        end
    end
end

function get_rigidity_matrix(g)
    R = zeros(ne(g), nv(g) * 3)

    for (i, e) in enumerate(edges(g))
        tuple = get_prop(g, e.src, :init_pos) - get_prop(g, e.dst, :init_pos)
        R[i, (e.src * 3 - 2):(e.src * 3)] = tuple
        R[i, (e.dst * 3 - 2):(e.dst * 3)] = -tuple
    end

    # add boundry conditions ie. set fixed nodes
    for fixed_vertex in filter(n -> get_prop(g, n, :fixed), vertices(g))
        new_row = zeros(nv(g) * 3)
        new_row[3 * fixed_vertex - 2] = 1
        R = vcat(R, new_row')
        new_row = zeros(nv(g) * 3)
        new_row[3 * fixed_vertex - 1] = 1
        R = vcat(R, new_row')
        new_row = zeros(nv(g) * 3)
        new_row[3 * fixed_vertex] = 1
        R = vcat(R, new_row')
    end
    return R
end

function test_rigidity(g)
    return rank(get_rigidity_matrix(g)) == nv(g) * 3
end

function get_rigid_groups_with_movement_vectors(g)
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
            new_row[3 * fix_id - 2] = 1
            new_row[3 * fix_id - 1] = 1
            new_row[3 * fix_id - 0] = 1
            R = vcat(R, new_row')
            nullspace_ids = nullspace_ids - rigid_group_ids

            Rl = R
        else
            rigid_group_ids = (sum(reshape((sum(abs.(n) .> 1e-10, dims=2)) .> 1e-10, (3, :)), dims=1)) .> 0
            fix_id = findfirst(rigid_group_ids)[2]
            new_row = zeros(Vdim * 3)
            new_row[3 * fix_id - 2] = 1
            new_row[3 * fix_id - 1] = 1
            new_row[3 * fix_id - 0] = 1
            Rl = vcat(Rl, new_row')
        end
        Rs = Rl' * Rl
    end
    return [RG,RV]
end

# # relies on vertecies having for n vertecies 1:n as lables for vertecies
# # g = TrussFab.import_trussfab_file("src/julia/test_models/chair.json", false)
# g = TrussFab.import_trussfab_file("src/julia/test_models/dragon.json", false)
# # g = TrussFab.import_trussfab_file("src/julia/test_models/seesaw_3.json", false)
# # g = TrussFab.import_trussfab_file("src/julia/test_models/simple_seesaw.json", false)
# # g = TrussFab.import_trussfab_file("src/julia/test_models/sketchup_tetrahedron.json", false)
# # remove_spring_edges!(g)
# gplot(g)

# nv(g)


# plot_matrix = m -> heatmap(m, color=:greys)


# R = get_rigidity_matrix(g)
# Rs = R' * R
# # println("eigen value=",eigvals(Rs))
# eigen_vectors = eigvecs(Rs)
# # # println("eigen vector=",eigen_vectors)
# # @time n = nullspace(Rs)

# gplot(g)
# plot_matrix(R)
# plot_matrix(Rs)
# plot_matrix(eigen_vectors)
# plot_matrix(n)
# # print(eigen_vectors[:,1])
# (RG, RV) = get_rigid_groups(g)
