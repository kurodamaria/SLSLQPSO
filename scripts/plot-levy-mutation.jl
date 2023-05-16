# Plot the trajectory of a particle solely mutated by the levy mutation

using GLMakie
using Distributions
using SLSLQPSO

begin
    # Use black theme because it's cool
    set_theme!(theme_black())
    # Disable inline
    Makie.inline!(false)
end

begin
    # Craete figure
    figure = Figure(resolution = (1600, 800))
    display(figure)


    max_iters = 1000
    # Create axis
    axis = Axis(figure[1, 1], title="Levy Mutation + Chaotic Bound | Number of iterations $max_iters", xlabel="x1", ylabel="x2")


    # Plot a contour of the rastrigin function
    f = schwefel
    lb = -512
    ub = 512
    x = LinRange(lb, ub, 100)
    y = LinRange(lb, ub, 100)
    z = [f([x[i], y[j]]) for i ∈ eachindex(x), j ∈ eachindex(y)]
    contour!(axis, x, y, z)
    xlims!(axis, lb, ub)
    ylims!(axis, lb, ub)

    # Use observable to store the trajectory of the particle
    trajectory = Observable([Point2f(rand(Uniform(lb, ub)), rand(Uniform(lb, ub)))])

    scatter!(axis, trajectory, color = :cyan, markersize = 30, marker='+', label = "Mutated Location")
    lines!(axis, trajectory, color = :lightgreen, linewidth=1, opacity=0.6, label = "Trajectory")

    fitness = Observable([f(Float64[trajectory[][end][1], trajectory[][end][2]])])
    best_fitness = fitness[][1]
    best_fitness_record = zeros(max_iters)
    better_iters = Int[]
    better_iters_value = Float64[]

    # axis2 = Axis(figure[1, 2], title="Fitness", xlabel="iteration", ylabel="fitness")
    ga = figure[1, 2] = GridLayout()
    axis2 = Axis(ga[1, 1], xlabel = "Iteration", ylabel = "Fitness")
    xlims!(axis2, 0, max_iters + 1)
    ylims!(axis2, 0, 2000)
    lines!(axis2, fitness, color = :cyan, label = "Fitness of the particle")

    # gb = figure[2, 1:2] = GridLayout()
    # axis_hist1 = Axis(gb[1, 1])
    # comp1_record = Float64[]
    # axis_hist2 = Axis(gb[1, 2])
    # comp2_record = Float64[]


    for t in 1:max_iters
        np = [0.0, 0.0]
        for didx in 1:2
            if rand(Bernoulli(1/10))
                levy_component = (rand() - 0.5) * rand(Levy(0, max_iters - t + 1))
                np[didx] = trajectory[][end][didx] + levy_component
                # np[didx] = trajectory[][end][didx] + rand(Cauchy(0, 0.2))
            else
                np[didx] = trajectory[][end][didx]
            end
            # bound the particle
            np[didx] = chaotic_bound(np[didx], lb, ub)
        end

        # Update the fitness
        push!(fitness[], f(np))

        if fitness[][end] < best_fitness
            global best_fitness = fitness[][end]
            # scatter!(axis2, t, fitness[][end], color = :lightgreen, markersize = 20, marker='o')
            push!(better_iters, t)
            push!(better_iters_value, fitness[][end])
        end

        # add the new particle to the trajectory
        push!(trajectory[], Point2f(np))
        # Update the plot
        notify.((trajectory, fitness))
        # Sleep
        # sleep(0.01)

        best_fitness_record[t] = best_fitness
    end


    # scatter the start and end points
    scatter!(axis, [trajectory[][1]], color = :red, markersize = 40, marker='o', label = "Start Position")
    scatter!(axis, [trajectory[][end]], color = :yellow, markersize = 40, marker='o', label = "End Position")

    scatter!(axis2, better_iters, better_iters_value, color = :lightgreen, markersize = 20, marker='o', label = "Found Better Global")

    axis3 = Axis(ga[2, 1], xlabel = "Iteration", ylabel = "Fitness")
    lines!(axis3, 1:max_iters, best_fitness_record, color = :lightgreen, label = "Best Fitness")

    axislegend(axis, position = :rt)
    axislegend(axis2, position = :rt)
    axislegend(axis3, position = :rt)

    # save("images/levy-mutation.png", figure)

end