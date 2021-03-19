# TODO get termonology straight:
# spring_stiffness == k == c == spring_stiffness_k
# node == vertex (probably should be 'node' everywhere, sinc that what it's called on the client)
# init_pos => initial_position
# m => mass
# type should be a :symbol, not a string
# actuation_power == excitement

module TrussFab
    using JSON
    using LightGraphs
    using GraphPlot
    using MetaGraphs
    using LinearAlgebra

    using Reexport

    export import_trussfab_file, import_trussfab_json, run_simulation, warm_up, set_stiffness!
    export set_weight!, set_actuation!, weight, power, set_age!
    export TrussGraph
    
    include("./analysis.jl")
    export get_frequency_spectrum, get_dominant_frequency, get_amplitude, get_peridoicity, get_acceleration
    
    include("./Simulator.jl")
    @reexport using .Simulator
    
    TrussGraph = MetaGraph
    
    function springs(g::TrussGraph)
        [e for e in edges(g) if get_prop(g, e, :type) == "spring"]
    end
    
    function users(g::TrussGraph)
        [v for v in vertices(g) if get_prop(g, v, :active_user)]
    end
    
    function set_stiffness!(g::TrussFab.TrussGraph, ks::AbstractArray{Float64, 1})
        ks2 = [ks...]
        for e in edges(g)
            if get_prop(g, e, :type) == "spring"
                set_prop!(g, e, :spring_stiffness, pop!(ks2))
            end
        end
    end
    
    function set_weight!(g, m)
        for v in TrussFab.users(g)
            set_prop!(g, v, :m, m)
        end
    end
    
    function set_actuation!(g, watts)
        for v in TrussFab.users(g)
            set_prop!(g, v, :actuation_power, watts)
        end
    end
    
    function set_age!(g::TrussGraph, age::Float64)
        TrussFab.set_weight!(g, TrussFab.weight(age))
        TrussFab.set_actuation!(g, TrussFab.power(age))
    end
    
    function weight(age)
        2.75 * (age-3) + 15
    end
    
    function power(age)
        7 * (age-3) + 30
    end
    
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
    const base_node_weight = 0.4 # kg
    function import_trussfab_json(json::Dict{String, Any}, filter_trivially_fixed_edges=true)
        nodeCount = length(json["nodes"])
        g = MetaGraphs.MetaGraph(nodeCount)
               
        for (server_node_index, node) in enumerate(json["nodes"])
            fixed = !isempty(node["pods"]) && Bool(node["pods"][1]["is_fixed"])
            added_mass = haskey(node, "added_mass") ? node["added_mass"] : 0
            
            set_prop!(g, server_node_index, :id, node["id"])
            set_prop!(g, server_node_index, :m, added_mass + base_node_weight)
            set_prop!(g, server_node_index, :fixed, fixed)
            set_prop!(g, server_node_index, :active_user, false)
            set_prop!(g, server_node_index, :init_pos, [node["x"], node["y"], node["z"]] / 1e3)
        end
        
        convert_node_id(client_node_id) = findfirst(v -> client_node_id == get_prop(g, v, :id), vertices(g))
        for edge in json["edges"]
            src_node = convert_node_id(edge["n1"])
            dst_node = convert_node_id(edge["n2"])
            # filter out edges that connect two fixed vertecies
            if (!filter_trivially_fixed_edges || (! (get_prop(g, src_node, :fixed) && (get_prop(g, dst_node, :fixed)))))
                add_edge!(g, src_node, dst_node)
                set_prop!(g, src_node, dst_node, :id, edge["id"])
                set_prop!(g, src_node, dst_node, :type, edge["type"])
                set_prop!(g, src_node, dst_node, :length, norm(get_prop(g, convert_node_id(edge["n1"]), :init_pos) - get_prop(g, convert_node_id(edge["n2"]), :init_pos)))

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
            server_vertex_id = convert_node_id(user_obj["id"])
            set_prop!(g, server_vertex_id, :m, mass + get_prop(g, server_vertex_id, :m))
            set_prop!(g, server_vertex_id, :active_user, true)
            set_prop!(g, server_vertex_id, :actuation_power, user_obj["excitement"])
        end

        return g
    end
end
