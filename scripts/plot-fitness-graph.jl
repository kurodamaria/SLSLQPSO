# Plot fitness graph of 3 functions:
# 1. rosenbrock
# 2. Schwefel
# 3. Trid

# With fixed number of function evaluations: 8000000

using GLMakie

begin
    # Use black theme because it's cool
    set_theme!(theme_black())
    # Disable inline
    Makie.inline!(false)
end

begin
    figure = Figure(resolution=(1200, 1500))
    display(figure)

    surface_gd = figure[1, 1] = GridLayout()
    fitness_gd = figure[2, 1] = GridLayout()

    # The number of fes
    fes = 8000000
    # fes = 1000000

    # (tag, fn, lb, ub, d (50 by default), contour_fn)
    # contour_fn for rosenbrock is log10(rosenbrock), for others it is the function itself
    functions = [
        ("Rosenbrock", rosenbrock, -100, 100, 50, (x) -> log10(rosenbrock(x)), -5, 5),
        ("Schwefel", schwefel, -500, 500, 50, schwefel, -500, 500),
        ("Trid", trid, -2500, 2500, 50, (x) -> log10(trid(x)), -3, 3)
    ]

    # Create grids
    # Plot a top-down view of the function
    for (i, (tag, fn, lb, ub, d, contour_fn, contour_lb, contour_ub)) in enumerate(functions)
        local axis = Axis(surface_gd[1, i], title="2-D $tag | Top-Down View", xlabel="x1", ylabel="x2")

        local x = LinRange(contour_lb, contour_ub, 110)
        local y = LinRange(contour_lb, contour_ub, 110)
        local z = [contour_fn([x[i], y[j]]) for i ∈ eachindex(x), j ∈ eachindex(y)]
        surface!(axis, x, y, z)


        # Optimize 
        fitness_record = slslqpso(fn, lb, ub, d; fe_cap = fes)[1]

        local fitness_axis = Axis(fitness_gd[i, 1], title="50-D $tag | Optimization Process | Log10 (Global Fitness) | Number of FEs Used $(length(fitness_record))", xlabel="Number of function evaluations", ylabel="Fitness")

        lines!(fitness_axis, log10.(fitness_record), color=:cyan)
        # xlims!(axis, lb, ub)
        # ylims!(axis, lb, ub)
    end

    rowsize!(figure.layout, 1, Auto(0.3))

    save("images/fitness-graph.png", figure, px_per_unit = 2)

    figure

    # Plot a graph of the fitness of the particle

end