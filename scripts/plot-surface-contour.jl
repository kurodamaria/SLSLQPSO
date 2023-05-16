# Plot surface and contour plots of test functions

using SLSLQPSO
using GLMakie

# Create the save directory if it doesn't exist
begin if !isdir("images")
	mkdir("images")
end end

# Setup plot themes
begin
	# Use black theme because it's cool
	set_theme!(theme_black())
	# Disable inline
	Makie.inline!(false)
end

# This function is used to compute the matrix of function values based on the two vectors of x and y values
function compute_z_matrix(f, x, y)
	m = length(x)
	n = length(y)
	z = zeros(m, n)
	for i ∈ 1:m
		for j ∈ 1:n
			z[i, j] = f([x[i], y[j]])
		end
	end
	return z
end

# Test compute_z_matrix on rosenbrock function
begin
	f = rosenbrock
	x = LinRange(-5, 5, 100)
	y = LinRange(-5, 5, 100)
	z = log10.(compute_z_matrix(f, x, y))

	surface(x, y, z)
end

# Functions of interest
# 1. rosenbrock represents unimodal functions
# 2. schwefel represents multimodal functions
# 3. cec2020_f1, cec2020_f3, cec2020_f9 are functions SLSL-QPSO didn't take lead.
functions_of_interest = [
	("log10 rosenbrock", (x) -> log10(rosenbrock(x)), -5, 10),
	("schwefel", schwefel, -500, 500),
	("log10 cec2020_f1", (x) -> log10(cec2020_f1(x)), -100, 100),
	("log10 cec2020_f3", (x) -> log10(cec2020_f3(x)), -100, 100),
	("log10 cec2020_f9", (x) -> log10(cec2020_f9(x)), -100, 100),
]

begin
	figure = Figure(resolution = (1500, 2000))
	display(figure)
	# Create a grid layout
	layout = GridLayout(2, 2)
	# Add the layout to the figure
	figure[1, 1] = layout

	# Iterate over the functions
	for (i, (name, f, lb, ub)) in enumerate(functions_of_interest)
		# Compute the matrix of function values
		x = LinRange(lb, ub, 110)
		y = LinRange(lb, ub, 110)
		z = compute_z_matrix(f, x, y)
		# Create a surface plot
		ax1 = Axis3(layout[i, 1], title = "$name surface")
		ax2 = Axis(layout[i, 2], title = "$name surface top-down")
		ax3 = Axis(layout[i, 3], title = "$name contour")

		surface!(layout[i, 1], x, y, z)
		surface!(layout[i, 2], x, y, z)
		contour!(layout[i, 3], x, y, z)
	end

	save("images/surface-contour.png", figure)
end
