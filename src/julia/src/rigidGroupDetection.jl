using MetaGraphs
using LightGraphs
using Revise
using LinearAlgebra
import TrussFab
using Plots

# relies on vertecies having for n vertecies 1:n as lables for vertecies
g = TrussFab.import_trussfab_file("test_models/sketchup_tetrahedron.json")
remove_spring_edges!(g)

function remove_spring_edges!(g)
    for e in edges(g)
        if get_prop(g, e, :type) == "spring"
            rem_edge!(g, e)
        end
    end
end

# in Cpp et al one would just do i*3 but julia uses indexing starting with one.
# so it has to be offset this way otherwise, the first index would be i * 3 = 1 * 3 = 3 and not 1
offset_index = (i, o) -> (i-1)*o +1

function get_rigidity_matrix(g)
    R = zeros(ne(g), nv(g)*3)
    for (i, e) in enumerate( edges(g))
        tuple = get_prop(g, e.src, :init_pos) - get_prop(g, e.dst, :init_pos)
        R[i, offset_index(e.src, 3):offset_index(e.src, 3)+2] = tuple
        R[i, offset_index(e.src, 3):offset_index(e.src, 3)+2] = -tuple
    end
    return R
end

function test_rigidity(g)
    return rank(get_rigidity_matrix(g)) <= nv(g) * 3 - 3
end

test_rigidity(g)

nv(g)

function get_symmetric_rigidity_matrix(g)
    R = get_rigidity_matrix(g)
    return transpose(R) * R
end

plot_matrix = m -> heatmap(m, color = :greys)

R = get_rigidity_matrix(g)
test_rigidity(g)
rank(R)
Rs = get_symmetric_rigidity_matrix(g)
@time n = nullspace(Rs)

plot_matrix(Rs)
plot_matrix(n)