module TrussFab
    using JSON
    using LightGraphs
    using GraphPlot
    using MetaGraphs
    using LinearAlgebra

    export import_trussfab_file
    export import_trussfab_json
    export run_simulation

    const node_weight = 0.4  # kg

    # include("./simulator.jl")
    # Usage 
    # g = import_trussfab_file("./test_models/seesaw_3.json")
    # masses = map(a -> get_prop(g, a, :m), vertices(g))
    # gplot(g)
    # get_prop(g, 2, :init_pos)

    function import_trussfab_file(path, filter_trivially_fixed_edges=true)
        json = JSON.parsefile(path)
        return import_trussfab_json(json, filter_trivially_fixed_edges)
    end

    # filter_trivially_fixed_edges removes edges that connect two fixed nodes
    # (are removed by default as they dont contribute to simulation results)
    function import_trussfab_json(json::Dict{String, Any}, filter_trivially_fixed_edges=true)
        nodeCount = length(json["nodes"])
        g = MetaGraphs.MetaGraph(nodeCount)

        clientNodeIds = fill(0, nodeCount)
        convertNodeId(nodeId) = findfirst(id -> id == nodeId, clientNodeIds)

        for (nodeIndex, node) in enumerate(json["nodes"])
            fixed = !isempty(node["pods"]) && Bool(node["pods"][1]["is_fixed"])

            clientNodeIds[nodeIndex] = node["id"]
            set_prop!(g, nodeIndex, :id, node["id"])
            set_prop!(g, nodeIndex, :m, node["added_mass"] + node_weight)
            set_prop!(g, nodeIndex, :fixed, fixed)
            set_prop!(g, nodeIndex, :init_pos, [node["x"], node["y"], node["z"]] / 1e3)
        end

        for edge in json["edges"]
            graph_edge = Edge(convertNodeId(edge["n1"]), convertNodeId(edge["n2"]))
            # filter out edges that connect two fixed vertecies
            if (!filter_trivially_fixed_edges || (! (get_prop(g, graph_edge.src, :fixed) && (get_prop(g, graph_edge.dst, :fixed)))))
                add_edge!(g, graph_edge)
                set_prop!(g, graph_edge, :id, edge["id"])
                set_prop!(g, graph_edge, :type, edge["type"])
                l = norm(get_prop(g, convertNodeId(edge["n1"]), :init_pos) - get_prop(g, convertNodeId(edge["n2"]), :init_pos))
                set_prop!(g, graph_edge, :length, l)
                set_prop!(g, graph_edge, :wight, l)
                set_prop!(g, graph_edge, :spring_stiffness, edge["type"] == "spring" ? 1e4 : Inf)
            end
        end
        set_prop!(g, :original_index_keys, clientNodeIds)
        return g
    end
end
