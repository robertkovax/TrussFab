module TrussFab
    using JSON
    using LightGraphs
    using GraphPlot
    using MetaGraphs
    using LinearAlgebra

    using Reexport

    export import_trussfab_file
    export import_trussfab_json
    export run_simulation
    export warm_up

    const base_node_weight = 0.4 # kg

    include("./Simulator.jl")
    @reexport using .Simulator
    
    # Usage 
    # g = import_trussfab_file("./test_models/seesaw_3.json")
    # masses = map(a -> get_prop(g, a, :m), vertices(g))
    # gplot(g)
    # get_prop(g, 2, :init_pos)

    function warm_up()
        g = import_trussfab_file("./test_models/seesaw_3.json")
        run_simulation(g)
    end

    function import_trussfab_file(path, filter_trivially_fixed_edges=true)
        json = JSON.parsefile(path)
        return import_trussfab_json(json, filter_trivially_fixed_edges)
    end

    # filter_trivially_fixed_edges removes edges that connect two fixed nodes
    # (are removed by default as they dont contribute to simulation results)
    function import_trussfab_json(json::Dict{String, Any}, filter_trivially_fixed_edges=true)
        nodeCount = length(json["nodes"])
        g = MetaGraphs.MetaGraph(nodeCount)

        clientNodeIds = get.(json["nodes"], "id", nothing)
        convertNodeId(nodeId) = findfirst(id -> id == nodeId, clientNodeIds)

        for (server_node_index, node) in enumerate(json["nodes"])
            fixed = !isempty(node["pods"]) && Bool(node["pods"][1]["is_fixed"])
            added_mass = haskey(node, "added_mass") ? node["added_mass"] : 0 

            clientNodeIds[server_node_index] = node["id"]
            set_prop!(g, server_node_index, :id, node["id"])
            set_prop!(g, server_node_index, :m, added_mass + base_node_weight)
            set_prop!(g, server_node_index, :fixed, fixed)
            set_prop!(g, server_node_index, :active_user, false)
            set_prop!(g, server_node_index, :init_pos, [node["x"], node["y"], node["z"]] / 1e3)
        end

        for edge in json["edges"]
            src_node = convertNodeId(edge["n1"])
            dst_node = convertNodeId(edge["n2"])
            # filter out edges that connect two fixed vertecies
            if (!filter_trivially_fixed_edges || (! (get_prop(g, src_node, :fixed) && (get_prop(g, dst_node, :fixed)))))
                add_edge!(g, src_node, dst_node)
                set_prop!(g, src_node, dst_node, :id, edge["id"])
                set_prop!(g, src_node, dst_node, :type, edge["type"])
                set_prop!(g, src_node, dst_node, :length, norm(get_prop(g, convertNodeId(edge["n1"]), :init_pos) - get_prop(g, convertNodeId(edge["n2"]), :init_pos)))

                if edge["type"] == "spring"
                    set_prop!(g, src_node, dst_node, :spring_stiffness,  edge["spring_parameter_k"])
                end
            end
        end


        for v in vertices(g)
            # TODO actually discard them (had trouble befor with MetaGraphs)
            if isempty(neighbors(g, v))
                set_prop!(g, v, :fixed, true)
            end
        end 

        # assign user massses
        for user_obj in json["mounted_users"]
            mass = user_obj["weight"]
            server_vertex_id = convertNodeId(user_obj["id"])
            set_prop!(g, server_vertex_id, :m, mass + get_prop(g, server_vertex_id, :m))
            set_prop!(g, server_vertex_id, :active_user, true)
        end

        set_prop!(g, :original_index_keys, clientNodeIds)
        return g
    end
end
