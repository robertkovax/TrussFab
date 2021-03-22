# TODO send 500 errors when there is an exception

using HTTP
using Sockets
using JSON
using Revise
import TrussFab
using CSV
using MetaGraphs
using LightGraphs
using LinearAlgebra

number_preprocessing(val::Float64) = round(val, digits=5)

ROUTER = HTTP.Router()

simulation_fps = 30
current_tasks = []
age_groups = [3, 6, 12]


# --- Task Management & Helpers ---

function abort_all_running_tasks()
    global current_tasks
    # abort current simulation to free system ressources and obtain lock
    while !isempty(current_tasks)
        task = pop!(current_tasks)
        if !istaskdone(task)
            schedule(task, InterruptException(), error=true)
        end
    end
end

function get_simulation_duration(client_request_obj)
    return if haskey(client_request_obj, "simulation_duration")
        client_request_obj["simulation_duration"]
    else
        5.0
    end
end

function get_simulation_task(client_request_obj, age)
    g = TrussFab.import_trussfab_json(client_request_obj)
    simulation_duration = get_simulation_duration(client_request_obj)
    TrussFab.set_age!(g, convert(Float64, age))

    simulation_task = @task begin
        @info "start simulation $(objectid(current_task()))"
        solution = fetch(@spawnat :any TrussFab.run_simulation(g, tspan=(0.01, simulation_duration), fps=simulation_fps))
        @info "finished simulation $(objectid(current_task()))"
        return solution
    end

    push!(current_tasks, simulation_task)
    return simulation_task
end


# --- converting simulation data to json objects ---

function simulation_result_to_custom_table_array(simulation_result, client_ids)
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

function get_user_stats_object(simulation_result, client_ids, client_node_id)
    function get_max(array)
        max_value, max_index = findmax(array)
        return Dict("value" => max_value, "index" => max_index)
    end

    function row_to_response(row)
        return (row .|> number_preprocessing) |> r -> Dict("time" => r[1], "x" => r[2], "y" => r[3], "z" => r[3])
    end

    server_node_id = findfirst(e -> e == client_node_id, client_ids)

    velocities = [simulation_result.t simulation_result[server_node_id*6-2:server_node_id*6, :]']
    acceleration = TrussFab.get_acceleration(velocities, simulation_fps)
    amplitude_length, (amplitude_start, amplitude_end) = TrussFab.get_amplitude(simulation_result, server_node_id)

    return Dict(
        "period" => 1 / TrussFab.get_dominant_frequency(simulation_result, server_node_id),
        "max_velocity" => (velocities |> eachrow .|> norm) |> get_max,
        "time_velocity" => eachrow(velocities) .|> row_to_response,
        "max_acceleration" => (acceleration |> eachrow .|> norm) |> get_max,
        "time_acceleration" => eachrow(acceleration) .|> row_to_response,
        "largest_amplitude" => Dict( "start" => amplitude_start, "end" => amplitude_end, "physical_length" => amplitude_length)
    )
end


# --- endpoints ---

function update_model(req::HTTP.Request)
    client_request_obj = JSON.parse(String(req.body))

    @info "updated model"

    abort_all_running_tasks()
    
    
    g = TrussFab.import_trussfab_json(client_request_obj)
    client_ids = vertices(g) .|> v -> get_prop(g, v, :id)
    
    # TODO calculate for all age groups
    function get_user_stats(simulation_result)
        return Dict(
            "data" => simulation_result_to_custom_table_array(simulation_result, client_ids),
            # c_id := client_node_id
            "user_stats" => Dict(user["id"] => get_user_stats_object(simulation_result, client_ids, user["id"]) for user in client_request_obj["mounted_users"])
            )
        end
        
    user_stats_per_age_group = try 
        asyncmap(age -> begin
            task = get_simulation_task(client_request_obj, age)
            schedule(task)
            sim_result = fetch(task)
            get_user_stats(sim_result)
        end, age_groups, ntasks=3)
    catch e
        if e isa TaskFailedException && e.task.exception isa InterruptException
            @warn "simulation aborted $(objectid(e.task))"
            return HTTP.Response(500)
        else
            rethrow()
        end 
    end

    # TODO Insert Optimization here
    spring_constants = TrussFab.springs(g) .|> edge -> Dict(get_prop(g, edge, :id) => get_prop(g, edge, :spring_stiffness))
    
    response_data = Dict(
        "optimized_spring_constants" => spring_constants,
        "simulation_results" => Dict(zip(age_groups, user_stats_per_age_group))
    )
    return HTTP.Response(200, JSON.json(response_data))
end
HTTP.register!(ROUTER, "POST", "/update_model", update_model)

# --- http server ---

# run warm up in the background such that user can already interact
# task is compute-bound therefore @async/co-routines wont do
function serve()
    if !isempty(ARGS) && tryparse(Int, ARGS[1]) !== nothing
        port = parse(Int, ARGS[1])
    else
        port = 8085
    end
    HTTP.serve(ROUTER, ip"0.0.0.0", port, verbose=true)
end
serve()
nothing
