# Plot scatter and histogram of the chaotic random numbers

using GLMakie

begin
	# Use black theme because it's cool
	set_theme!(theme_black())
	# Disable inline
	Makie.inline!(false)
end

begin
	# Create figure
	figure = Figure(resolution = (1200, 400))
	display(figure)

	num_numbers = 7000

	chaotic_numbers = sin.(π * rand(2, num_numbers) .- π / 2)

	# scatter the chaotic numbers
	axis_scatter = Axis(figure[1, 1], title="scatter of 2d independent logistic random numbers", xlabel = "x1", ylabel = "x2")
	scatter!(axis_scatter, chaotic_numbers[1, :], chaotic_numbers[2, :], color = :cyan, markersize = 10, marker = '+')

	# histogram of the first dimension
	axis_hist1 = Axis(figure[1, 2], title="histogram of x1", xlabel="value", ylabel="frequency")
	hist!(axis_hist1, chaotic_numbers[1, :], color=:cyan, bins = 50)

	# histogram of the second dimension
	axis_hist2 = Axis(figure[1, 3], title="histogram of x2", xlabel="value", ylabel="frequency")
	hist!(axis_hist2, chaotic_numbers[2, :], color=:cyan, bins = 50)

    save("./images/chaotic-bound.png", figure)
end
