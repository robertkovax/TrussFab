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
using LinearAlgebra

include("./analysis.jl")

ROUTER = HTTP.Router()

simulation_fps = 25
current_simulation_task = nothing
current_model = nothing
simulated_model_hash = 0
get_client_ids = []
spring_constants_override = nothing
users = []

# current_model

# using Plots
# parsed_structure = TrussFab.import_trussfab_json(current_model)
# sol = TrussFab.run_simulation(parsed_structure, actuation_power=0.0)
# plot(sol)
# current_model["spring_constants"]
# parsed_structure


function asyncSimulation()
    global current_model
    global simulated_model_hash
    global current_simulation_task
    global client_ids
    global users

    if hash((current_model, users)) == simulated_model_hash
        # the previous simulation already addressed this combination of structure and users
        return
    end

    if spring_constants_override !== nothing
        # TODO implement spring constants override
        @warn "WARNING: There are spring constants that the client set that are not part of the simulation. #NotYetImplemented $(spring_constants_override)"
    end

    simulated_structure_hash = hash((current_model, users))

    this_current_model = deepcopy(current_model)
    this_current_model["mounted_users"] = users

    parsed_structure = TrussFab.import_trussfab_json(this_current_model)
    client_ids = get_prop(parsed_structure, :original_index_keys)

    # (optimistically) abort current simulation to free system ressources and obtain lock
    if current_simulation_task !== nothing && !istaskdone(current_simulation_task)
        schedule(current_simulation_task, InterruptException(), error=true)
    end

    current_simulation_task = @async begin
        @info "start simulation"
        TrussFab.run_simulation(parsed_structure, actuation_power=50.0, tspan=(0.01, 5), fps=simulation_fps)
    end
    nothing
end

function updateModel(req::HTTP.Request)
    global current_model
    current_model = JSON.parse(String(req.body))
    current_model["mounted_users"] = []

    @info "updated model"

    asyncSimulation()
    return HTTP.Response(200, "ok")
end

HTTP.register!(ROUTER, "POST", "/update_model", updateModel)

function updateSpringConstants(req::HTTP.Request)
    # set_spring(src_vertex, dst_vertex, k) = set_prop!(current_structure, src_vertex, dst_vertex, :spring_stiffness, k)
    # TODO implement
    global spring_constants_override
    spring_constants_override = JSON.parse(String(req.body))
    return HTTP.Response(200, "ok")
end
HTTP.register!(ROUTER, "POST", "/update_spring_constants", updateSpringConstants)


function updateMountedUsers(req::HTTP.Request)
    global current_model
    global users
    # Example Request {"node_id": weight_in_kg }
    # {"8": 0.12, "9": 50, "10": 0.12, "11": 50}
    users = []

    for user in JSON.parse(String(req.body))
        client_node_id::String, weight::Float64 = user
        push!(users, Dict("id" => parse(Int, client_node_id), "weight" => weight))
    end
    @info "updated users"

    asyncSimulation()
    return HTTP.Response(200, "ok")
end
HTTP.register!(ROUTER, "PATCH", "/update_mounted_users", updateMountedUsers)

function getSimulationResult(req::HTTP.Request)
    global client_ids
    function simulationResultToCustomTableArray(simulation_result)
        # TODO make interface nicer with custom type or MetaGraph indexing
        symbols_generation_for_vertex(vertex_name, variable_name) = ("node_" * vertex_name * "." * variable_name * "[") .* string.(1:3) .* "]"
        get_symbols(client_ids2) = map(id -> symbols_generation_for_vertex(string(id), "r_0"), client_ids2) |> Iterators.flatten |> Iterators.collect
        get_header() = vcat("time", get_symbols(client_ids))
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
HTTP.register!(ROUTER, "GET", "/get_hub_time_series_with_force_vector", getSimulationResult)


function getUserStats(req::HTTP.Request)
    function get_max(array)
        max_value, max_index = findmax(array)
        return Dict("value" => max_value, "index" => max_index)
    end

    function row_to_response(row)
        return Dict("time" => row[1], "x" => row[2], "y" => row[3], "z" => row[3])
    end

    global client_ids
    client_node_id = parse(Int, replace(HTTP.URIs.splitpath(req.target)[2], "?" => "")) # /user_stats/10?, get 10
    server_node_id =  findfirst(e -> e == client_node_id, client_ids)
    # TODO fix index mapping (maybe start doing it properly)
    simulation_result = fetch(current_simulation_task)

    velocities = [simulation_result.t simulation_result[server_node_id*6-2:server_node_id*6, :]']
    acceleration = get_acceleration(velocities, simulation_fps)
    amplitude_length, (amplitude_start, amplitude_end) = get_amplitude(simulation_result, server_node_id)

    response = Dict(
        "period" => 1 / get_dominant_frequency(simulation_result, server_node_id),
        "max_velocity" => (velocities |> eachrow .|> norm) |> get_max,
        "time_velocity" => eachrow(velocities) .|> row_to_response,
        "max_acceleration" => (acceleration |> eachrow .|> norm) |> get_max,
        "time_acceleration" => eachrow(acceleration) .|> row_to_response,
        "largest_amplitude" => Dict( "start" => amplitude_start, "end" => amplitude_end, "physical_length" => amplitude_length)
    )
    @info response["largest_amplitude"]
    return HTTP.Response(200, JSON.json(response))
end
HTTP.register!(ROUTER, "GET", "/get_user_stats/*", getUserStats)

# run warm up in the background such that user can already interact
# task is compute-bound therefore @async/co-routines wont do
import Base.Threads.@spawn
@spawn TrussFab.warm_up()
function serve()
    if tryparse(Int, ARGS[1]) !== nothing
        port = parse(Int, ARGS[1])
    else
        port = 8085
    end
    HTTP.serve(ROUTER, ip"0.0.0.0", port, verbose=true)
end

import TrussFab
serve()
nothing
