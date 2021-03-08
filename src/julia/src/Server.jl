# TODO REFACTOR
# TODO get snake case and camel case straight
# TODO fix mapping for server and client ids
# TODO make handling of global variables nicer somehow

# TODO reduce JSON number precision to have smaller json responses and faster parsing time
# TODO send 500 errors when there is an exception

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
get_client_ids = []
spring_constants_override = nothing

# --- Actual Simulation ---

function asyncSimulation()
    global current_model
    global simulated_model_hash
    global current_simulation_task
    global client_ids

    if spring_constants_override !== nothing
        # TODO implement spring constants override
        @warn "WARNING: There are spring constants that the client set that are not part of the simulation. #NotYetImplemented $(spring_constants_override)"
    end

    parsed_structure = TrussFab.import_trussfab_json(current_model)
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


# --- converting simulation data to json objects ---

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

function get_user_stats_object(simulation_result, client_node_id)
    function get_max(array)
        max_value, max_index = findmax(array)
        return Dict("value" => max_value, "index" => max_index)
    end

    function row_to_response(row)
        return Dict("time" => row[1], "x" => row[2], "y" => row[3], "z" => row[3])
    end
    
    server_node_id =  findfirst(e -> e == client_node_id, client_ids)

    velocities = [simulation_result.t simulation_result[server_node_id*6-2:server_node_id*6, :]']
    acceleration = get_acceleration(velocities, simulation_fps)
    amplitude_length, (amplitude_start, amplitude_end) = get_amplitude(simulation_result, server_node_id)

    return Dict(
        "period" => 1 / get_dominant_frequency(simulation_result, server_node_id),
        "max_velocity" => (velocities |> eachrow .|> norm) |> get_max,
        "time_velocity" => eachrow(velocities) .|> row_to_response,
        "max_acceleration" => (acceleration |> eachrow .|> norm) |> get_max,
        "time_acceleration" => eachrow(acceleration) .|> row_to_response,
        "largest_amplitude" => Dict( "start" => amplitude_start, "end" => amplitude_end, "physical_length" => amplitude_length)
    )
end


# --- endpoints ---

function update_model(req::HTTP.Request)
    global current_model
    current_model = JSON.parse(String(req.body))

    @info "updated model"

    asyncSimulation()
    simulation_result = fetch(current_simulation_task)
    return HTTP.Response(200, JSON.json(Dict(
        "data" => simulationResultToCustomTableArray(simulation_result),
         # c_id := client_node_id
        "user_stats" => Dict(user["id"] => get_user_stats_object(simulation_result, user["id"]) for user in current_model["mounted_users"])
    )))
end
HTTP.register!(ROUTER, "POST", "/update_model", update_model)

# --- http server ---

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

