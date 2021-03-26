using HTTP
using Sockets
using JSON
using Revise
import TrussFab
using CSV
using MetaGraphs
using LightGraphs
using LinearAlgebra
using Plots
using Distributed


number_preprocessing(val::Float64) = round(val, digits=5)

ROUTER = HTTP.Router()

simulation_fps = 30
current_futures = []
current_tasks = []
current_request_handler = @async ""
age_groups = [3, 6, 12]

function plot_spectrum(sol, vertex_id, display_node_id, age)
    (freqs, mag_3d) = TrussFab.get_frequency_spectrum2(sol, vertex_id)
    mag_scalar = abs.(sum.(eachcol(mag_3d)))
    time_domain = plot(sol.t, sol[(vertex_id*6-2):(vertex_id*6-0), :]', ylabel="velocity [m/s]", xlabel="simulation time [s]")
    freq_domain = plot(freqs, mag_scalar, xlim=(0, +5), ylabel="magnitude [log10]", xlabel="frequency [Hz]")
    return plot(time_domain, freq_domain, layout=2, title="node $(display_node_id), age group $(age)")
end

function show_user_fft(g, sol, age)
    users = TrussFab.users(g)
    fft_plots = [plot_spectrum(sol, uid, get_prop(g, uid, :id), age) for uid in users]
    display(plot(fft_plots..., layout=(length(users),1)))
end

# --- Task Management & Helpers ---
function abort_all_running_tasks()
    global current_futures
    global current_tasks
    global current_request_handler

    if !istaskdone(current_request_handler)
        schedule(current_request_handler, InterruptException(), error=true)
        fetch(current_request_handler)
    end
    
    while !isempty(current_tasks)
        task::Task = pop!(current_tasks)
        if !istaskdone(task)
            schedule(task, InterruptException(), error=true)
            fetch(task)
        end
    end

    # abort current simulation to free system ressources and obtain lock
    while !isempty(current_futures)
        future::Future = pop!(current_futures)
        @warn "interrupt worker $(future.where)"
        try
            @spawnat future.where throw(InterruptException())
            fetch(future)
        catch e
            if !(e isa InterruptException)
                rethrow()
            end
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

function get_simulation_task(g, simulation_duration=5.0)
    global current_futures
    global current_tasks

    simulation_task = @task begin
        @info "start simulation $(objectid(current_task()))"
        simulation_job_future = @spawnat :any TrussFab.run_simulation(g, tspan=(0.01, simulation_duration), fps=simulation_fps)
        push!(current_futures, simulation_job_future)
        solution = fetch(simulation_job_future)
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


function parse_requested_amplitude(client_request_obj)
    xyz_to_vec(xyz_obj) = [xyz_obj["x"], xyz_obj["y"], xyz_obj["z"]]
    handle_positions = client_request_obj["mounted_users"][1]["handle_positions"][1]
    start_pos = xyz_to_vec(handle_positions[1])
    end_pos = xyz_to_vec(handle_positions[2])
    return norm(start_pos .- end_pos) / 1000
end

# --- endpoints ---

function update_model(req::HTTP.Request)
    try
        global current_request_handler
        client_request_obj = JSON.parse(String(req.body))
        
        abort_all_running_tasks()
        yield()
        
        @info "updated model"
        current_request_handler = current_task()
        
        g = TrussFab.import_trussfab_json(client_request_obj)
        client_ids = vertices(g) .|> v -> get_prop(g, v, :id)
        
        spring_constants = TrussFab.springs(g) .|> edge -> Dict(get_prop(g, edge, :id) => get_prop(g, edge, :spring_stiffness))
        
        function get_user_stats(simulation_result)
            return Dict(
                "data" => simulation_result_to_custom_table_array(simulation_result, client_ids),
                "user_stats" => Dict(user["id"] => get_user_stats_object(simulation_result, client_ids, user["id"]) for user in client_request_obj["mounted_users"])
                )
        end

        user_stats_per_age_group = asyncmap(age -> begin
            g = TrussFab.import_trussfab_json(client_request_obj)
            simulation_duration = get_simulation_duration(client_request_obj)
            if age != 3
                TrussFab.set_age!(g, convert(Float64, age))
            end
            task = get_simulation_task(g, simulation_duration)
            schedule(task, nothing, error=true)
            sim_result = fetch(task)
            get_user_stats(sim_result)
        end, age_groups, ntasks=3)


        response_data = Dict(
            "optimized_spring_constants" => spring_constants,
            "simulation_results" => Dict(zip(age_groups, user_stats_per_age_group))
        )

        return HTTP.Response(200, JSON.json(response_data))
    catch e
        @warn sprint(showerror, e)
        return HTTP.Response(500)
    end
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
