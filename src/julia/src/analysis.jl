using FFTW

function fft_on_vertex(sol, vertex_id, fps)
    F1 = fft(sol[vertex_id*6 + 0, :]) |> fftshift
    F2 = fft(sol[vertex_id*6 + 1, :]) |> fftshift
    F3 = fft(sol[vertex_id*6 + 2, :]) |> fftshift
    freqs = fftfreq(length(sol.t), fps) |> fftshift

    mag = log10.(abs.(F1) .+ abs.(F2) .+ abs.(F3))
    return freqs, mag
end

function get_amplitude(sol)
    # go through timeseries -> set start point 
    # -> advance as long as next vector is further away from start than previous one
    # -> when this is not the case anymore the path is considered one amplitude
    # -> check  whether this amplitued exceeds the currently longest amplitude
    # ↺ for entire time series
    vertex_id = 18 +1
    largest_aplitude = 0
    timeseries = sol[vertex_id*6:vertex_id*6+2, :]

    start_node = nothing
    prev_node = nothing
    current_amplitude_length = 0

    for vector in eachcol(timeseries)
        if start_node === nothing
            start_node = vector
        elseif prev_node === nothing
            current_amplitude_length = norm(start_node - vector)
            prev_node = vector
        elseif norm(start_node - vector) < norm(start_node - prev_node)
            # terminal condition
            if largest_aplitude < current_amplitude_length
                largest_aplitude = current_amplitude_length
            end
            start_node = nothing
            prev_node = nothing
        else
            current_amplitude_length += norm(prev_node - vector)
            prev_node = vector
        end
    end
    return largest_aplitude
end

function get_dominant_frequency(sol)
    spectrum = get_frequency(sol, 30, 18+1)
    get_frequency(sol, 30, 20)
    trimmed_spectrum = spectrum[0.2 .< spectrum[:, 1] .< 1.0, :]
    max_mag, index = findmax(trimmed_spectrum[:,2])
    return trimmed_spectrum[index]
end
