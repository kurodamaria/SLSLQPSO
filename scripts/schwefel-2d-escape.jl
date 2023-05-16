using GLMakie
using Statistics
using Distributions
using Printf
using SLSLQPSO

begin
	Makie.inline!(false)
	set_theme!(theme_black())
end

@inbounds begin
	fig = Figure(resolution = (1920, 960))
	display(fig)

	# QPSO and SLSL-QPSO titles
	qpso_title = Observable("QPSO")
	slsl_qpso_title = Observable("SLSL-QPSO")

	qpso_ax = Axis(fig[1, 1], title = qpso_title)
	slsl_qpso_ax = Axis(fig[1, 2], title = slsl_qpso_title)

	# Shared configurations
	num_particles = 50
	max_iterations = 3000
	f = schwefel
	fmin = -0.0006109361978587912744842469692230224609375
	# fmin = 0
	lb = -500.0
	ub = 500.0
	α1 = 1.0
	α2 = 0.5
	threshhold = 0.01
	# The number of trails
	N = 100

	# Plot contour of the target function on both qpso_ax and slsl_qpso_ax
	X = lb:1:ub
	Y = lb:1:ub
	z = Vector{Real}()
	for x in X, y in Y
		push!(z, f([x, y]) - fmin)
	end
	z = reshape(z, length(X), length(Y))
	contour!(qpso_ax, X, Y, z)
	contour!(slsl_qpso_ax, X, Y, z)

	# SLSL-QPSO configurations
	num_layers = 20
	max_iterations_per_layer = 50 # set small for demonstration
	current_iterations_in_layer = 0
	current_layer = 1
	living_interval = [1, num_layers]
	gbest_fitnesses = zeros(num_layers)

	# QPSO particle swarm
	qpso_particles = Observable(rand(Uniform(lb, ub), 2, num_particles))
	qpso_pbest = Observable(zeros(2, num_particles))
	qpso_pbest_fitness = fill(Inf64, num_particles)
	qpso_gbest = Observable(zeros(2, 1))
	qpso_gbest_fitness = Inf64
	# Scatter QPSO swarm, marker should be larger, maybe 34
	scatter!(qpso_ax, qpso_particles, color = (:cyan, 0.6), markersize = 34, marker = '+', label = "particles")
	scatter!(qpso_ax, qpso_pbest, color = :red, markersize = 34, marker = 'o', label = "pbest")
	scatter!(qpso_ax, qpso_gbest, color = :green, markersize = 24, marker = 'o', label = "gbest")

	# SLSL-QPSO particle swarm
	slsl_qpso_particles = Observable(rand(Uniform(lb, ub), 2, num_particles))
	slsl_qpso_pbest = Observable(zeros(2, num_particles))
	slsl_qpso_pbest_fitness = fill(Inf64, num_particles)
	slsl_qpso_gbest = Observable(zeros(2, 1))
	slsl_qpso_gbest_fitness = Inf64
	# Scatter SLSL-QPSO swarm, marker should be larger, maybe 34
	scatter!(slsl_qpso_ax, slsl_qpso_particles, color = (:cyan, 0.6), markersize = 34, marker = '+', label = "particles")
	scatter!(slsl_qpso_ax, slsl_qpso_pbest, color = :red, markersize = 34, marker = 'o', label = "pbest")
	scatter!(slsl_qpso_ax, slsl_qpso_gbest, color = :green, markersize = 34, marker = 'o', label = "gbest")
	# record the count of success (how many time the algorithm reach threshold) of qpso and slsl-qpso
	qpso_success = 0
	slsl_qpso_success = 0

	for i in 1:N
		sleep_time = 0.001

		if i != 1
			# Reinitialize QPSO and SLSL-QPSO
			qpso_particles[] = rand(Uniform(lb, ub), 2, num_particles)
			qpso_pbest[] = zeros(2, num_particles)
			qpso_pbest_fitness = fill(Inf64, num_particles)
			qpso_gbest[] = zeros(2, 1)
			qpso_gbest_fitness = Inf64
			slsl_qpso_particles[] = rand(Uniform(lb, ub), 2, num_particles)
			slsl_qpso_pbest[] = zeros(2, num_particles)
			slsl_qpso_pbest_fitness = fill(Inf64, num_particles)
			slsl_qpso_gbest[] = zeros(2, 1)
			slsl_qpso_gbest_fitness = Inf64
			current_layer = 1
			current_iterations_in_layer = 0

			# reset the background color
			qpso_ax.backgroundcolor = :black
			slsl_qpso_ax.backgroundcolor = :black
		end

		# Enter the optimization loop
		for t in 1:max_iterations
			if rand() > 0.6
				sleep(sleep_time)
			end

			current_iterations_in_layer = current_iterations_in_layer + 1

			# If reached max layer iterations, reinitialize the swarm
			if current_iterations_in_layer > max_iterations_per_layer
				if rand() > 0.5
					slsl_qpso_pbest_fitness = fill(Inf64, num_particles)
				end
				gbest_fitnesses[current_layer:end] .= slsl_qpso_gbest_fitness
				current_iterations_in_layer = 0
				current_layer = (current_layer + 1) % num_layers
				if current_layer == 0
					current_layer = num_layers
				end
				slsl_qpso_particles[] = rand(Uniform(lb, ub), 2, num_particles)

				if current_layer == 1
					slsl_qpso_pbest_fitness = fill(Inf64, num_particles)
					# Update the living interval; the sign is either 0 or -1
					# -1 means the next layer is improved compared to the previous layer
					# 0 means the next layer is not improved compared to the previous layer
					diff = sign.(gbest_fitnesses[2:end] .- gbest_fitnesses[1:(end - 1)])

					# Find the beginning of the next living interval
					index = findfirst(isequal(-1), diff)

					# If the there is no improved layer, the beginning of the next living interval is the first layer
					# and destory the pbests too.
					if isnothing(index)
						index = 1
						slsl_qpso_pbest_fitness = fill(Inf64, num_particles)
					end

					# Update the beginning of the next living interval
					living_interval[1] = index

					# Find the end of the next living interval
					index = findlast(isequal(-1), diff)

					# If the there is no improved layer, the end of the next living interval is the last layer
					# and destory the pbests too.
					if isnothing(index)
						index = num_layers - 1
						slsl_qpso_pbest_fitness = fill(Inf64, num_particles)
					end
					living_interval[2] = index + 1
				end
			end

			qpso_α = (α1 - α2) * (max_iterations - t) / max_iterations + α2

			# Calculate fitness of QPSO and SLSL-QPSO and update pbest and gbest
			for i in 1:num_particles
				x = qpso_particles[][1, i]
				y = qpso_particles[][2, i]

				fitness = f([x, y]) - fmin
				if fitness < qpso_pbest_fitness[i]
					qpso_pbest_fitness[i] = fitness
					qpso_pbest[][:, i] = qpso_particles[][:, i]
					if fitness < qpso_gbest_fitness
						qpso_gbest_fitness = fitness
						qpso_gbest[][:, 1] = qpso_particles[][:, i]
					end
				end

				x = slsl_qpso_particles[][1, i]
				y = slsl_qpso_particles[][2, i]

				fitness = f([x, y]) - fmin
				if fitness < slsl_qpso_pbest_fitness[i]
					slsl_qpso_pbest_fitness[i] = fitness
					slsl_qpso_pbest[][:, i] = slsl_qpso_particles[][:, i]
					if fitness < slsl_qpso_gbest_fitness
						slsl_qpso_gbest_fitness = fitness
						slsl_qpso_gbest[][:, 1] = slsl_qpso_particles[][:, i]
					end
				end
			end

			# check the global fitness, if less than threshold, set the axis' background to green
			if qpso_gbest_fitness < threshhold
				qpso_ax.backgroundcolor = (:green, 0.3)
				# acclelerate the speed
				sleep_time = 0.001
			end
			if slsl_qpso_gbest_fitness < threshhold
				slsl_qpso_ax.backgroundcolor = (:green, 0.3)
				# acclelerate the speed
				sleep_time = 0.001
			end

			# if both reached the threshold, break the loop
			if qpso_gbest_fitness < threshhold && slsl_qpso_gbest_fitness < threshhold
				break
			end

			# Update title informations for QPSO
			qpso_title[] = @sprintf("QPSO: Iteration %d, fitness = %.10e; success count = %d / %d (%.2f)", t, qpso_gbest_fitness, qpso_success, N, qpso_success/N)

			# Notify the update of pbest and gbest to Makie
			notify(qpso_pbest)
			notify(qpso_gbest)
			notify(slsl_qpso_pbest)
			notify(slsl_qpso_gbest)

			# Calculate mean best
			qpso_mean_best = mean(qpso_pbest[], dims = 2)

			# Update particles by each dimension
			for pidx in 1:num_particles

				for didx in 1:2
					# Calculate the local attractor
					ψ = rand()
					local_attractor = ψ * qpso_pbest[][didx, pidx] + (1 - ψ) * qpso_gbest[][didx, 1]

					u = rand()
					if rand() > 0.5
						qpso_particles[][didx, pidx] = local_attractor + qpso_α * abs(qpso_mean_best[didx] - qpso_particles[][didx, pidx]) * log(1 / u)
					else
						qpso_particles[][didx, pidx] = local_attractor - qpso_α * abs(qpso_mean_best[didx] - qpso_particles[][didx, pidx]) * log(1 / u)
					end
					qpso_particles[][didx, pidx] = clamp(qpso_particles[][didx, pidx], lb, ub)
				end
			end


			# Update title information for SLSL-QPSO, including layer info
			slsl_qpso_title[] = @sprintf("SLSL-QPSO: Iteration %d, layer %d, fitness = %.10e; success count = %d / %d (%.2f)", t, current_layer, slsl_qpso_gbest_fitness, slsl_qpso_success, N, slsl_qpso_success/N)

			# Levy mutate on the slsl_qpso_gbest
			lmgbest = zeros(2)
			for didx in 1:2
				if rand(Bernoulli(1 / 2))
					lmgbest[didx, 1] = slsl_qpso_gbest[][didx, 1] + (rand() - 0.5) * rand(Levy(0, max_iterations - t + 1))
					# lmgbest[didx, 1] = slsl_qpso_gbest[][didx, 1] + rand(Cauchy(0, 0.2))
					lmgbest[didx, 1] = clamp(lmgbest[didx, 1], lb, ub)
				else
					lmgbest[didx, 1] = slsl_qpso_gbest[][didx, 1]
				end
			end
			# calculate fitness of lmgbest, if better replace gbest
			fitness = f(lmgbest) - fmin
			if fitness < slsl_qpso_gbest_fitness
				slsl_qpso_gbest_fitness = fitness
				slsl_qpso_gbest[][:, 1] = lmgbest
			end

			# Calculate the mean best
			slsl_qpso_mean_best = mean(slsl_qpso_pbest[], dims = 2)

			# Calculate α for slslqpso
			slslqpso_α1 = α1 - α2 * (current_layer - 1) / num_layers
			slslqpso_α2 = α1 - α2 * current_layer / num_layers
			slslqpso_α = (slslqpso_α1 - slslqpso_α2) * (max_iterations_per_layer - current_iterations_in_layer) / max_iterations_per_layer + slslqpso_α2

			# Update particles by each dimension
			for pidx in 1:num_particles
				# For a low chance, the particle will perform a straight flight to its pbest
				if rand(Bernoulli(0.1))
                    tpidx = rand(1:num_particles)
                    for didx in 1:2
                        slsl_qpso_particles[][didx, pidx] = rand(Normal(slsl_qpso_pbest[][didx, tpidx], 0.05))
                    end
					continue
				end
				for didx in 1:2
					# Calculate the local attractor
					ψ = rand()
					local_attractor = ψ * slsl_qpso_pbest[][didx, pidx] + (1 - ψ) * slsl_qpso_gbest[][didx, 1]

					u = rand()
					if rand() > 0.5
						slsl_qpso_particles[][didx, pidx] = local_attractor + slslqpso_α * abs(slsl_qpso_mean_best[didx] - slsl_qpso_particles[][didx, pidx]) * log(1 / u)
					else
						slsl_qpso_particles[][didx, pidx] = local_attractor - slslqpso_α * abs(slsl_qpso_mean_best[didx] - slsl_qpso_particles[][didx, pidx]) * log(1 / u)
					end
					slsl_qpso_particles[][didx, pidx] = clamp(slsl_qpso_particles[][didx, pidx], lb, ub)
				end
			end

			notify(qpso_particles)
			notify(slsl_qpso_particles)
		end
		# if the fitness never reach the threshold, set the background to red and wait for 3 second to start next run
		if qpso_gbest_fitness >= threshhold
			qpso_ax.backgroundcolor = (:red, 0.3)
		else
			# record success
			qpso_success = qpso_success + 1
		end
		if slsl_qpso_gbest_fitness >= threshhold
			slsl_qpso_ax.backgroundcolor = (:red, 0.3)
		else
			# record success
			slsl_qpso_success = slsl_qpso_success + 1
		end
		sleep(3)
	end
end
