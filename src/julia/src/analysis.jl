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
    # go through timeseries -> set start point 
    # -> advance as long as next vector is further away from start than previous one
    # -> when this is not the case anymore the path is considered one amplitude
    # -> check  whether this amplitued exceeds the currently longest amplitude
    # ↺ for entire time series
    largest_aplitude = 0
    largest_aplitude_start_index = nothing
    largest_aplitude_end_index = nothing
    timeseries = sol[vertex_id*6-5:vertex_id*6-3, :]

    start_pos = nothing
    start_index = nothing
    prev_pos = nothing
    current_amplitude_length = 0

    for (index, pos) in enumerate(eachcol(timeseries))
        if start_pos === nothing
            start_pos = pos
            start_index = index
        elseif prev_pos === nothing
            current_amplitude_length = norm(start_pos - pos)
            prev_pos = pos
        elseif norm(start_pos - pos) < norm(start_pos - prev_pos)
            # terminal condition
            if largest_aplitude < current_amplitude_length
                largest_aplitude = current_amplitude_length
                largest_aplitude_start_index = start_index
                largest_aplitude_end_index = index
            end
            start_pos = nothing
            prev_pos = nothing
        else
            current_amplitude_length += norm(prev_pos - pos)
            prev_node = pos
        end
    end
    return largest_aplitude, (largest_aplitude_start_index, largest_aplitude_end_index)
end

function get_acceleration(velocities, fps)
    result = similar(velocities)
    for i in 2:length(velocities)
        result[i] = velocities[i-1] - velocities[i]
    end
    result[1] = 0
    return result ./ fps
end