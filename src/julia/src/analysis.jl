using LinearAlgebra
using FFTW

function get_frequency_spectrum(sol, vertex_id)
    fps = 1/ (sol.t[2] - sol.t[1])

    F1 = fft(sol[vertex_id*6 - 5, :]) |> fftshift
    F2 = fft(sol[vertex_id*6 - 4, :]) |> fftshift
    F3 = fft(sol[vertex_id*6 - 3, :]) |> fftshift
    freqs = fftfreq(length(sol.t), fps) |> fftshift

    mag = log10.(abs.(F1) .+ abs.(F2) .+ abs.(F3))
    return freqs, mag
end

function get_dominant_frequency(sol, vertex_id)
    frequency, magnitude = get_frequency_spectrum(sol, vertex_id)
    _, index = findmax(magnitude[0.2 .< frequency .< 1.0])
    return frequency[0.2 .< frequency .< 1.0][index]
end

function get_amplitude(sol, vertex_id)
    # finds the two points that are furthest apart

    largest_aplitude = 0
    largest_aplitude_start_index = nothing
    largest_aplitude_end_index = nothing
    timeseries = sol[vertex_id*6-5:vertex_id*6 - 4, :]

    for (index1, pos1) in enumerate(eachcol(timeseries))
        for (index2, pos2) in enumerate(eachcol(timeseries))
            if (index1 >= index2)
                continue
            end
            if (norm(pos1 .- pos2) > largest_aplitude)
                largest_aplitude = norm(pos1 .- pos2)
                largest_aplitude_start_index = index1
                largest_aplitude_end_index = index2
            end
        end
    end
    return largest_aplitude, (largest_aplitude_start_index, largest_aplitude_end_index)
end

function get_peridoicity(sol, threshold=0.05, min_timestep_distance=3)
    recurring_time_steps = []
    for i in 1:length(sol.t)
        for j in (i + min_timestep_distance):length(sol.t)
            if i !== j && norm(sol[:, i] - sol[:, j]) < threshold
                push!(recurring_time_steps, (i,j))
            end
        end
    end
    # TODO filter multiple reoccurences
    return recurring_time_steps
end

function get_acceleration(velocities, fps)
    result = similar(velocities)
    for i in 2:length(velocities)
        result[i] = velocities[i-1] - velocities[i]
    end
    result[1] = 0
    return result ./ fps
end