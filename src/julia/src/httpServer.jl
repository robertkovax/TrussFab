using HTTP
using Sockets
using JSON
using Revise
import TrussFab
using CSV
using MetaGraphs
const ROUTER = HTTP.Router()

users = []
current_structure = nothing
current_sim_task = nothing

function asyncSimulation()
    # abort current simulation to free system ressources and obtain lock
    if current_sim_task !== nothing && !istaskdone(current_sim_task)
        schedule(current_sim_task, InterruptException(), error=true)
        wait(current_sim_task)
    end

    global current_sim_task = @async begin
        TrussFab.run_simulation(current_structure)
    end
end

function updateModel(req::HTTP.Request)
    json_structure = JSON.parse(String(req.body))
    global last_request = json_structure
    global current_structure = TrussFab.import_trussfab_json(json_structure)
    asyncSimulation()

    return HTTP.Response(200, "ok")
end
HTTP.@register(ROUTER, "POST", "/update_model", updateModel)

function updateSpringConstants()
    set_spring(src_vertex, dst_vertex, k) = set_prop!(current_structure, src_vertex, dst_vertex, :spring_stiffness, k)
    # TODO implement
    return HTTP.Response(200, "ok")
end
HTTP.@register(ROUTER, "POST", "/update_spring_constants", updateSpringConstants)

function updateMountedUsers(req::HTTP.Request)
   # Example Request {"node_id": weight_in_kg }
   #{"8": 0.12, "9": 50, "10": 0.12, "11": 50}
   mounted_users = JSON.parse(String(req.body))
   global users = keys(mounted_users)
   asyncSimulation()
   #TODO run simulation deffered
   return HTTP.Response(200, "ok")
end
HTTP.@register(ROUTER, "POST", "/update_mounted_users", updateMountedUsers)

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

    return fetch(current_sim_task) |>
        simulationResultToCustomTableArray |> 
        (data) -> JSON.json(Dict("data" => data)) |> 
        (data) ->  HTTP.Response(200, data)    
end
HTTP.@register(ROUTER, "GET", "/get_hub_time_series_with_force_vector", getSimulationResult)

function getUserStats(req::HTTP.Request)
    nodeId = HTTP.URIs.splitpath(req.target)[2] # /user_stats/10, get 10
    # fetch(current_sim_task)
    response = Dict(
        "period" => 10,
        "max_acceleration" => 1,
        "max_velocity" => 1,
        "time_velocity" => 1,
        "time_acceleration" => 1
    )
    return HTTP.Response(200, JSON.json(response))
end
HTTP.@register(ROUTER, "GET", "/get_user_stats/*", getUserStats)


HTTP.serve(ROUTER, ip"0.0.0.0", 8080, verbose=true)
nothing
