module TrussFab

using JSON
using LightGraphs
using GraphPlot
using MetaGraphs
using LinearAlgebra

export import_trussfab_file


# Usage 
# g = import_trussfab_file("./test_models/seesaw_3.json")
# gplot(g)
# get_prop(g, 2, :init_pos)

function import_trussfab_file(path, filter_edges=true)
    json = JSON.parsefile(path)
    g = MetaGraph(length(json["nodes"]))

    for node in json["nodes"]
        fixed = !isempty(node["pods"]) && node["pods"][1]["is_fixed"]
        set_prop!(g, node["id"], :m, node["added_mass"])
        set_prop!(g, node["id"], :fixed, fixed)
        set_prop!(g, node["id"], :init_pos, [node["x"], node["y"], node["z"]] / 1e3)
    end

    for edge in json["edges"]
        graph_edge = Edge(edge["n1"], edge["n2"])
        # filter out edges that connect two fixed vertecies
        if (!filter_edges || (! (get_prop(g, graph_edge.src, :fixed) && (get_prop(g, graph_edge.dst, :fixed)))))
            add_edge!(g, graph_edge)
            set_prop!(g, graph_edge, :id, edge["id"])
            set_prop!(g, graph_edge, :type, edge["type"])
            l = norm(get_prop(g, edge["n1"], :init_pos) - get_prop(g, edge["n2"], :init_pos))
            set_prop!(g, graph_edge, :length, l)

            set_prop!(g, graph_edge, :spring_stiffness, edge["type"] == "spring" ? 1e3 : Inf)

        end
    end
    return g
end

end # module

