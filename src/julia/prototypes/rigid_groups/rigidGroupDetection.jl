using DataStructures: counter, inc!, reset!
include("./trussfab_parser.jl")

# advanced
fixed_nodes = Set(filter(v -> get_prop(g, v, :fixed), vertices(g)))

most_connected_vertex = 0

function get_rigid_group(start_set)
    while true
        connection_counter = counter(Int)

        for node in rigid_group
            nei = filter(v -> !( v in rigid_group ), neighbors(g, node))
            map(v -> inc!(connection_counter, v), nei)
        end

        most_connected_vertex = sort(vertices(g), by=(v -> -connection_counter[v]))[1]

        if connection_counter[most_connected_vertex] < 3
            return rigid_group
        else
            # TODO: immediatley add all components that have more than 2 connection
            push!(rigid_group, most_connected_vertex)
        end
    end
end

get_rigid_group(fixed_nodes)


#----



using LinearAlgebra
# g = parseTrussFile("./test_models/sketchup_tetrahedron.json")
g = parseTrussFile("./test_models/seesaw_3.json")

function test_rigidity(g)
    R = zeros(ne(g) * 3, nv(g))
    for (i, e) in enumerate( edges(g))
        ia = (i - 1) *3 +1
        tuple = get_prop(g, e.src, :init_pos) - get_prop(g, e.dst, :init_pos)
        R[ia:ia+2, e.src] = tuple
        R[ia:ia+2, e.dst] = -tuple
    end
    println(rank(R))
    return rank(R) == 3
end

triangles(g)

@time test_rigidity(g)
a = Int[1 ]
gplot(g)
# for v in vertices(g)
#     for vn in neighbors(g, v)
#         for v in neighbors(g, vn)
#             cycle = [v]
#         nei = filter(v -> !( v in rigid_group ), )
