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

number_preprocessing(val::Float64) = round(val, digits=5)

ROUTER = HTTP.Router()

simulation_fps = 30
current_simulation_task = nothing
current_model = nothing
get_client_ids = []

# --- Actual Simulation ---

function async_simulation()
    global current_model
    global simulated_model_hash
    global current_simulation_task
    global client_ids

    parsed_structure = TrussFab.import_trussfab_json(current_model)
    client_ids = get_prop(parsed_structure, :original_index_keys)

    # abort current simulation to free system ressources and obtain lock
    if current_simulation_task !== nothing && !istaskdone(current_simulation_task)
        schedule(current_simulation_task, InterruptException(), error=true)
    end

    simulation_duration = if haskey(current_model, "simulation_duration")
        current_model["simulation_duration"]
    else
        5.0
    end

    current_simulation_task = @async begin
        @info "start simulation"
        TrussFab.run_simulation(parsed_structure, tspan=(0.01, simulation_duration), fps=simulation_fps)
    end
    nothing
end


# --- converting simulation data to json objects ---

function simulationResultToCustomTableArray(simulation_result)
    # TODO get rid of this mapping array by using the :id field in the vertices directly
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
        push!(result, vcat(ts, time_sample) .|> number_preprocessing)
    end
    return result
end

function get_user_stats_object(simulation_result, client_node_id)
    function get_max(array)
        max_value, max_index = findmax(array)
        return Dict("value" => max_value, "index" => max_index)
    end

    function row_to_response(row)
        return (row .|> number_preprocessing) |> r -> Dict("time" => r[1], "x" => r[2], "y" => r[3], "z" => r[3])
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

    async_simulation()
    
    simulation_result = try
        fetch(current_simulation_task)
    catch e
        if e isa TaskFailedException && e.task.exception isa InterruptException
            @warn "simulation aborted"
            return HTTP.Response(500)
        else
            rethrow()
        end 
    end

    # TODO calculate for all age groups
    user_stats = Dict(
        "data" => simulationResultToCustomTableArray(simulation_result),
        # c_id := client_node_id
        "user_stats" => Dict(user["id"] => get_user_stats_object(simulation_result, user["id"]) for user in current_model["mounted_users"])
    )


    # TODO Insert Optimization here
    g = TrussFab.import_trussfab_json(current_model)
    spring_constants = TrussFab.springs(g) .|> edge -> Dict(get_prop(g, edge, :id) => get_prop(g, edge, :spring_stiffness))
    
    response_data = Dict(
        "optimized_spring_constants" => spring_constants,
        "simulation_results" => Dict(
            "3" => user_stats,
            "6" => user_stats,
            "12" => user_stats
        )
    )
    return HTTP.Response(200, JSON.json(response_data))
end
HTTP.register!(ROUTER, "POST", "/update_model", update_model)

# --- http server ---

# run warm up in the background such that user can already interact
# task is compute-bound therefore @async/co-routines wont do
import Base.Threads.@spawn
@spawn TrussFab.warm_up()
function serve()
    if !isempty(ARGS) && tryparse(Int, ARGS[1]) !== nothing
        port = parse(Int, ARGS[1])
    else
        port = 8085
    end
    HTTP.serve(ROUTER, ip"0.0.0.0", port, verbose=true)
end

import TrussFab
serve()
nothing

