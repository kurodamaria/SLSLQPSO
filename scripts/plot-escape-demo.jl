# Demonstrates how reinitialization helps escape from the local minimum
using GLMakie
using Distributions
using SLSLQPSO

begin
    Makie.inline!(false)
    set_theme!(theme_black())
end

begin
    figure = Figure(resolution = (1600, 800))
    display(figure)

    # set the number of particles
    num_particles = 200

    # set the local optimum and global optimum
    local_optimum = [-420.9054, -420.9054]
    global_optimum = [420.9054, 420.9054]

    # Generate random personal bests around the local optimum
    personal_bests = hcat(rand(Normal(local_optimum[1], 20), num_particles), rand(Normal(local_optimum[2], 20), num_particles))

    # Generate random particles around the local optimum
    particles = hcat(rand(Normal(local_optimum[1], 20), num_particles), rand(Normal(local_optimum[2], 20), num_particles))

    # Create two subfigure:
    # cyan plus sign: particles
    # red circle: personal bests
    # green circle: local optimum
    # yellow star: global optimum

    # 1. The left subfigure shows the particles and their personal bests, as well as the local optimum.
    ax_left = Axis(figure[1, 1], xlabel = "x1", ylabel = "x2", title = "This layer converged to a local optimum ...")

    # Plot a contour of rastrigin
    x = LinRange(-500, 500,  100)
    y = LinRange(-500, 500,  100)
    z = [schwefel([x[i], y[j]]) for i in eachindex(x), j in eachindex(y)]
    contour!(ax_left, x, y, z)

    # plot the particles as cyan plus signs
    scatter!(ax_left, particles[:, 1], particles[:, 2], markersize = 20,  marker='+', color = :cyan, label = "particles")
    scatter!(ax_left, personal_bests[:, 1], personal_bests[:, 2], markersize = 15,  marker='o', color = :red, label = "personal bests")
    scatter!(ax_left, local_optimum[1], local_optimum[2], markersize = 35,  marker='o', color = :green, label = "local optimum")
    scatter!(ax_left, global_optimum[1], global_optimum[2], markersize = 40,  marker='*', color = :yellow, label = "global optimum")

    # Fix xlim and ylim
    xlims!(ax_left, -500, 500)
    ylims!(ax_left, -500, 500)
    axislegend(ax_left, position=:rb)

    # 2. The right subfigure shows the reinitialized particles and their personal bests, as well as the local optimum.
    ax_right = Axis(figure[1, 2], xlabel = "x1", ylabel = "x2", title = "... but this layer escaped 😎")
    # Reinitialize the particles by uniformly sampling from the range [-5,5]
    particles = rand(Uniform(-500.0, 500.0), num_particles, 2)
    contour!(ax_right, x, y, z)
    scatter!(ax_right, particles[:, 1], particles[:, 2], markersize = 20,  marker='+', color = :cyan, label = "particles")
    scatter!(ax_right, personal_bests[:, 1], personal_bests[:, 2], markersize = 15,  marker='o', color = :red, label = "personal bests")
    scatter!(ax_right, local_optimum[1], local_optimum[2], markersize = 35,  marker='o', color = :green, label = "local optimum")
    scatter!(ax_right, global_optimum[1], global_optimum[2], markersize = 40,  marker='*', color = :yellow, label = "global optimum")
    # Fix xlim and ylim
    xlims!(ax_right, -500, 500)
    ylims!(ax_right, -500, 500)
    axislegend(ax_right, position=:rb)

    save("images/escape-demo.png", figure)

end