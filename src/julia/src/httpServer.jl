# TODO REFACTOR
# TODO get snake case and camel case straight
# TODO fix mapping for server and client ids
# TODO make handling of global variables nicer somehow

using HTTP
using Sockets
using JSON
using Revise
import TrussFab
using CSV
using MetaGraphs
const ROUTER = HTTP.Router()

users = Dict()
current_structure = nothing
current_simulation_task = nothing
simulated_structure_hash = 0

function asyncSimulation()
    global current_simulation_task
    global simulated_structure_hash
    global current_structure

    # apply user data
    for (client_node_id, user_mass) in users
        println(parse(Int, client_node_id))
        # TODO push logic of getting forgein variables down to endpoint
        server_node_id = findfirst(e -> e == parse(Int, client_node_id), get_prop(current_structure, :original_index_keys))
        # TODO make this compliant to the mounted_users format from the file export
        # TODO make this an interface for a TrussFab struct to have tidy coupling
        set_prop!(current_structure, server_node_id, :m, user_mass)
    end

    if hash(current_structure) == simulated_structure_hash
        # the previous simulation already addressed this combination of structure and users
        return
    end

    simulated_structure_hash = hash(current_structure)

    # abort current simulation to free system ressources and obtain lock
    if current_simulation_task !== nothing && !istaskdone(current_simulation_task)
        # TODO investiage why sometimes it cant abort a running simulation
        schedule(current_simulation_task, InterruptException(), error=true)
        # try
        #     wait(current_simulation_task)
        # catch TaskFailedException
        #     println("aborted simulation")
        # end
    end
    
    current_simulation_task = @async begin
        TrussFab.run_simulation(current_structure, 20, 3)
    end
    nothing
end


function updateModel(req::HTTP.Request)
    json_structure = JSON.parse(String(req.body))
    global last_request = json_structure
    
    global current_structure = TrussFab.import_trussfab_json(json_structure)
    asyncSimulation()
    
    return HTTP.Response(200, "ok")
end

HTTP.@register(ROUTER, "POST", "/update_model", updateModel)

function updateSpringConstants(req::HTTP.Request)
    set_spring(src_vertex, dst_vertex, k) = set_prop!(current_structure, src_vertex, dst_vertex, :spring_stiffness, k)
    # TODO implement
    return HTTP.Response(200, "ok")
end
HTTP.@register(ROUTER, "POST", "/update_spring_constants", updateSpringConstants)


function updateMountedUsers(req::HTTP.Request)
    global current_structure
    global users
    # Example Request {"node_id": weight_in_kg }
    # {"8": 0.12, "9": 50, "10": 0.12, "11": 50}
    users = JSON.parse(String(req.body))

    asyncSimulation()
    return HTTP.Response(200, "ok")
end

HTTP.@register(ROUTER, "PATCH", "/update_mounted_users", updateMountedUsers)


function getSimulationResult(req::HTTP.Request)
    function simulationResultToCustomTableArray(simulation_result)
        # TODO make interface nicer with custom type or MetaGraph indexing
        get_client_ids() = get_prop(current_structure, :original_index_keys)
        symbols_generation_for_vertex(vertex_name, variable_name) = ("node_" * vertex_name * "." * variable_name * "[") .* string.(1:3) .* "]"
        get_symbols(client_ids) = map(id -> symbols_generation_for_vertex(string(id), "r_0"), client_ids) |> Iterators.flatten |> Iterators.collect
        get_header() = vcat("time", get_symbols(get_client_ids()))
        result = []

        push!(result, get_header())
        for (i, ts) in enumerate(simulation_result.t)
            time_sample = []
            # only get every second triple (those are the positions)
            for (j, val) in enumerate(simulation_result[i])
                if (j - 1) % 6 < 3
                    push!(time_sample, val)
                end
            end
            push!(result, vcat(ts, time_sample))
        end
        return result
    end

    return fetch(current_simulation_task) |>
        simulationResultToCustomTableArray |> 
        (data) -> JSON.json(Dict("data" => data)) |> 
        (data) ->  HTTP.Response(200, data)    
end
HTTP.@register(ROUTER, "GET", "/get_hub_time_series_with_force_vector", getSimulationResult)


function getUserStats(req::HTTP.Request)
    global current_structure

    println(req.target)
    clientNodeId = replace(HTTP.URIs.splitpath(req.target)[2], "?" => "") # /user_stats/10?, get 10
    # TODO fix index mapping (maybe start doing it properly)
    serverNodeId = findfirst(e -> e == parse(Int, clientNodeId), get_prop(current_structure, :original_index_keys))
    simulation_result = fetch(current_simulation_task)

    velocities = [simulation_result.t simulation_result[serverNodeId*6-2:serverNodeId*6, :]']

    thin_out = iter -> Iterators.filter(t -> t[1] % 1 == 1, enumerate(iter)) .|> t -> t[2]

    response = Dict(
        "period" => 10,
        "max_acceleration" => Dict("value" => 100, "index" => 1),
        "max_velocity" => Dict("value" => 100, "index" => 1),
        "time_velocity" => eachrow(velocities) .|> row -> Dict("time" => row[1], "x" => row[2], "y" => row[3], "z" => row[3]),
        # TODO calculate proper accelerations
        "time_acceleration" => eachrow(velocities) .|> row -> Dict("time" => row[1], "x" => row[2], "y" => row[3], "z" => row[3])
    )

    return HTTP.Response(200, JSON.json(response))
end
HTTP.@register(ROUTER, "GET", "/get_user_stats/*", getUserStats)

@async begin
    TrussFab.warm_up()
end

HTTP.serve(ROUTER, ip"0.0.0.0", 8080, verbose=true)
nothing
