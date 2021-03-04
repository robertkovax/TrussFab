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
g = TrussFab.import_trussfab_file("src/julia/test_models/bird.json", false)
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
offset_index = (i, o) -> (i-1)*o +1

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
    R = zeros(ne(g), nv(g)*3)
    for (i, e) in enumerate(edges(g))
        tuple = get_prop(g, e.src, :init_pos) - get_prop(g, e.dst, :init_pos)
        # println("tuple=",tuple)
        R[i, offset_index(e.src, 3):offset_index(e.src, 3)+2] = tuple
        R[i, offset_index(e.dst, 3):offset_index(e.dst, 3)+2] = -tuple
    end

    # add boundry conditions ie. set fixed nodes
    for fixed_vertex in filter(n -> get_prop(g, n, :fixed), vertices(g))
        # new_row = (1:nv(g) .|> i -> i == fixed_vertex ? [1,0,0] : zeros(3)) |> Iterators.flatten |> Iterators.collect
        # show(new_row)
        new_row=zeros(nv(g)*3)
        new_row[3*(fixed_vertex-1)+1]=1
        R = vcat(R, new_row')
        new_row=zeros(nv(g)*3)
        new_row[3*(fixed_vertex-1)+2]=1
        R = vcat(R, new_row')
        new_row=zeros(nv(g)*3)
        new_row[3*(fixed_vertex-1)+3]=1
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

nv(g)

function get_symmetric_rigidity_matrix(g)
    R = get_rigidity_matrix(g)
    # return transpose(R) * R
    return transpose(R) * R
end

plot_matrix = m -> heatmap(m, color = :greys)


R = get_rigidity_matrix(g)
test_rigidity(g)
# println("R=",R)
# println("rank=",rank(R))
Rs = get_symmetric_rigidity_matrix(g)
# println("Rs=",Rs)
println("eigen value=",eigvals(Rs))
eigen_vectors=eigvecs(Rs)
# println("eigen vector=",eigen_vectors)
@time n = nullspace(Rs)

gplot(g)
plot_matrix(R)
plot_matrix(Rs)
plot_matrix(eigen_vectors)
plot_matrix(n)
# plot_matrix(eigvecs(Rs))
row_1=eigen_vectors[1,:]
row_2=eigen_vectors[2,:]
print(dot(row_1,row_2))