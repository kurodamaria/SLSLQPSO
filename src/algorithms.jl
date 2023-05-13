using Statistics
using Distributions
export qpso, wqpso, gaqpso, θqpso, slslqpso

# bound the value of x to [lb, ub] by logistic map random numbers
function chaotic_bound(x, lb, ub)
	# docstring for chaotic_bound
	"""
	Bound the value of x to [lb, ub] by logistic map random numbers
		x: value to be bounded
		lb: lower bound (< 0)
		ub: upper bound (> 0)
	"""

	# precheck the range of lb and ub
	if lb >= 0 || ub <= 0
		error("lb must be less than 0, and ub must be greater than 0")
	end

	# Calculate the chaotic map random number
	r = sin(pi * rand() - pi / 2)

	if x < lb
		return lb * r
	elseif x > ub
		return ub * r
	else
		return x
	end
end

function qpso(f, lb, ub, d; num_particles = 50, tolerance = 10e-8, fe_cap = Inf64, max_iters = Inf64)
	# docstring for qpso
	"""
	Quantum-behaved Particle Swarm Optimization (QPSO) algorithm.
		f: function to be optimized
		lb: lower bound of the search space
		ub: upper bound of the search space
		d: dimension of the search space
		num_particles: number of particles
		tolerance: tolerance of the algorithm
		fe_cap: maximum number of function evaluations
		max_iters: maximum number of iterations
	"""

	# Uniformly generate particles
	particles = rand(Uniform.(lb, ub), d, num_particles)

	# Initialize the personal best positions
	pbests = copy(particles)

	# Initialize the personal best fitness
	pbest_fitnesses = fill(Inf64, num_particles)

	# Initialize the global best position
	gbest = zeros(d)

	# Initialize the global best fitness
	gbest_fitness = Inf64

	# Record the number of function evaluations, and the number of iterations
	fe_count = 0
	iter_count = 0

	# Enter the main loop
	@inbounds while iter_count <= max_iters
        iter_count = iter_count + 1

		# Calculate fitness for each particle and update pbests and gbest
		for pidx in 1:num_particles
			# Calculate the fitness of the particle
			fitness = f(particles[:, pidx])

			# Update the personal best position and fitness
			if fitness < pbest_fitnesses[pidx]
				pbests[:, pidx] = particles[:, pidx]
				pbest_fitnesses[pidx] = fitness
				# Update the global best position and fitness
				if fitness < gbest_fitness
					gbest = particles[:, pidx]
					gbest_fitness = fitness
				end
			end

			# Update the number of function evaluations
			fe_count += 1

			# If the number of function evaluations exceeds the cap, or the tolerance is reached, return the result
			if fe_count >= fe_cap || gbest_fitness <= tolerance
				return gbest, gbest_fitness, fe_count, iter_count
			end
		end

		# Calculate the mean best
		mean_best = mean(pbests, dims = 2)

		# Calculate the ce coefficient
		α = (1.0 - 0.5) * (max_iters - iter_count) / max_iters + 0.5

		# Update the position of each particle
		for pidx in 1:num_particles
			for didx in 1:d
				# Calculate the local attractor
				ψ = rand()
				pl = ψ * pbests[didx, pidx] + (1 - ψ) * gbest[didx]

				u = rand()

				# Update the position
				if rand() > 0.5
					particles[didx, pidx] = pl + α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				else
					particles[didx, pidx] = pl - α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				end

				# bound to search space
				particles[didx, pidx] = chaotic_bound(particles[didx, pidx], lb, ub)
			end
		end
	end

	# Return the result
	return gbest, gbest_fitness, fe_count, iter_count
end

function wqpso(f, lb, ub, d; num_particles = 50, tolerance = 10e-8, fe_cap = Inf64, max_iters = Inf64)
	# docstring for wqpso
	"""
	Weighted Quantum-behaved Particle Swarm Optimization (WQPSO) algorithm.
		f: function to be optimized
		lb: lower bound of the search space
		ub: upper bound of the search space
		d: dimension of the search space
		num_particles: number of particles
		tolerance: tolerance of the algorithm
		fe_cap: maximum number of function evaluations
		max_iters: maximum number of iterations
	"""

	# Uniformly generate particles
	particles = rand(Uniform.(lb, ub), d, num_particles)

	# WQPSO requires to record the fitness of each particle
	swarm_fit = zeros(num_particles)

	# Initialize the personal best positions
	pbests = copy(particles)

	# Initialize the personal best fitness
	pbest_fitnesses = fill(Inf64, num_particles)

	# Initialize the global best position
	gbest = zeros(d)

	# Initialize the global best fitness
	gbest_fitness = Inf64

	# Record the number of function evaluations, and the number of iterations
	fe_count = 0
	iter_count = 0

	# Enter the main loop
	@inbounds while iter_count <= max_iters

        iter_count = iter_count + 1
		# Calculate fitness for each particle and update pbests and gbest
		for pidx in 1:num_particles
			# Calculate the fitness of the particle
			fitness = f(particles[:, pidx])
			# Record the fitness of the particle
			swarm_fit[pidx] = fitness

			# Update the personal best position and fitness
			if fitness < pbest_fitnesses[pidx]
				pbests[:, pidx] = particles[:, pidx]
				pbest_fitnesses[pidx] = fitness
				# Update the global best position and fitness
				if fitness < gbest_fitness
					gbest = particles[:, pidx]
					gbest_fitness = fitness
				end
			end

			# Update the number of function evaluations
			fe_count += 1

			# If the number of function evaluations exceeds the cap, or the tolerance is reached, return the result
			if fe_count >= fe_cap || gbest_fitness <= tolerance
				return gbest, gbest_fitness, fe_count, iter_count
			end
		end

		# Calculate the weighted mean best
		weights = zeros(num_particles)
		cnt = 0
		for pidx ∈ sortperm(swarm_fit)
			weights[pidx] = (1.5 - 0.5) * (num_particles - cnt) / num_particles + 0.5
			cnt += 1
		end
		mean_best = mean(pbests .* weights, dims = 2)

		# Calculate the ce coefficient
		α = (1.0 - 0.5) * (max_iters - iter_count) / max_iters + 0.5

		# Update the position of each particle
		for pidx in 1:num_particles
			for didx in 1:d
				# Calculate the local attractor
				ψ = rand()
				pl = ψ * pbests[didx, pidx] + (1 - ψ) * gbest[didx]

				u = rand()

				# Update the position
				if rand() > 0.5
					particles[didx, pidx] = pl + α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				else
					particles[didx, pidx] = pl - α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				end

				# bound to search space
				particles[didx, pidx] = chaotic_bound(particles[didx, pidx], lb, ub)
			end
		end
	end
end

# QPSO with gaussian distributed local attractor point
function gaqpso(f, lb, ub, d; num_particles = 50, tolerance = 10e-8, fe_cap = Inf64, max_iters = Inf64)
	# docstring for gaqpso
	"""
	Gaussian-distributed Attractor Quantum-behaved Particle Swarm Optimization (GAQPSO) algorithm.
		f: function to be optimized
		lb: lower bound of the search space
		ub: upper bound of the search space
		d: dimension of the search space
		num_particles: number of particles
		tolerance: tolerance of the algorithm
		fe_cap: maximum number of function evaluations
		max_iters: maximum number of iterations
	"""

	# Uniformly generate particles
	particles = rand(Uniform.(lb, ub), d, num_particles)

	# Initialize the personal best positions
	pbests = copy(particles)

	# Initialize the personal best fitness
	pbest_fitnesses = fill(Inf64, num_particles)

	# Initialize the global best position
	gbest = zeros(d)

	# Initialize the global best fitness
	gbest_fitness = Inf64

	# Record the number of function evaluations, and the number of iterations
	fe_count = 0
	iter_count = 0

	# Enter the main loop
	@inbounds while iter_count <= max_iters

        iter_count = iter_count + 1
		# Calculate fitness for each particle and update pbests and gbest
		for pidx in 1:num_particles
			# Calculate the fitness of the particle
			fitness = f(particles[:, pidx])

			# Update the personal best position and fitness
			if fitness < pbest_fitnesses[pidx]
				pbests[:, pidx] = particles[:, pidx]
				pbest_fitnesses[pidx] = fitness
				# Update the global best position and fitness
				if fitness < gbest_fitness
					gbest = particles[:, pidx]
					gbest_fitness = fitness
				end
			end

			# Update the number of function evaluations
			fe_count += 1

			# If the number of function evaluations exceeds the cap, or the tolerance is reached, return the result
			if fe_count >= fe_cap || gbest_fitness <= tolerance
				return gbest, gbest_fitness, fe_count, iter_count
			end
		end

		# Calculate the mean best
		mean_best = mean(pbests, dims = 2)
		# Calculate the ce coefficient
		α = (1.0 - 0.5) * (max_iters - iter_count) / max_iters + 0.5
		# Update the position of each particle
		for pidx in 1:num_particles
			for didx in 1:d
				# Calculate the local attractor
				ψ = rand()
				pl = ψ * pbests[didx, pidx] + (1 - ψ) * gbest[didx]

				# Calculate the gaussian distributed local attractor point
				pgl = rand(Normal(pl, abs(mean_best[didx] - pbests[didx, pidx])))

				# Update the position
				u = rand()
				if rand() > 0.5
					particles[didx, pidx] = pgl + α* abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				else
					particles[didx, pidx] = pgl - α* abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				end

				# bound to search space
				particles[didx, pidx] = chaotic_bound(particles[didx, pidx], lb, ub)
			end
		end
	end

	# Return the result
	return gbest, gbest_fitness, fe_count, iter_count
end

# phase-angle encoded qpso
function θqpso(f, lb, ub, d; num_particles = 50, tolerance = 10e-8, fe_cap = Inf64, max_iters = Inf64)
	# docstring for θQPSO
	"""
	Phase-angle encoded Quantum-behaved Particle Swarm Optimization (θQPSO) algorithm.
		f: function to be optimized
		lb: lower bound of the search space
		ub: upper bound of the search space
		d: dimension of the search space
		num_particles: number of particles
		tolerance: tolerance of the algorithm
		fe_cap: maximum number of function evaluations
		max_iters: maximum number of iterations
	"""

	# Axuliary function to map the particle to the search space
	function map_to_search_space(x)
		lhf = (ub - lb) / 2
		mid = lb + lhf
		return mid .+ lhf .* sin.(x)
	end

	# Uniformly generate particles
	particles = rand(Uniform(-pi / 2, pi / 2), d, num_particles)

	# Initialize the personal best positions
	pbests = copy(particles)

	# Initialize the personal best fitness
	pbest_fitnesses = fill(Inf64, num_particles)

	# Initialize the global best position
	gbest = zeros(d)

	# Initialize the global best fitness
	gbest_fitness = Inf64

	# Record the number of function evaluations, and the number of iterations
	fe_count = 0
	iter_count = 0

	# Enter the main loop
	@inbounds while iter_count <= max_iters
        iter_count = iter_count + 1

		# Calculate fitness for each particle and update pbests and gbest
		for pidx in 1:num_particles
			# Map the particle to the search space
			x = map_to_search_space(particles[:, pidx])

			# Calculate the fitness of the particle
			fitness = f(x)

			# Update the personal best position and fitness
			if fitness < pbest_fitnesses[pidx]
				pbests[:, pidx] = particles[:, pidx]
				pbest_fitnesses[pidx] = fitness
				# Update the global best position and fitness
				if fitness < gbest_fitness
					gbest = particles[:, pidx]
					gbest_fitness = fitness
				end
			end

			# Update the number of function evaluations
			fe_count += 1

			# If the number of function evaluations exceeds the cap, or the tolerance is reached, return the result
			if fe_count >= fe_cap || gbest_fitness <= tolerance
				return map_to_search_space(gbest), gbest_fitness, fe_count, iter_count
			end
		end

		# Calculate the mean best
		mean_best = mean(pbests, dims = 2)

        # Calculate ce
        α = (1.0 - 0.5) * (max_iters - iter_count) / max_iters + 0.5

		# Update the position of each particle
		for pidx in 1:num_particles
			for didx in 1:d
				# Calculate the local attractor
				ψ = rand()
				pl = ψ * pbests[didx, pidx] + (1 - ψ) * gbest[didx]

				# Update the position
				u = rand()
				if rand() > 0.5
					particles[didx, pidx] = pl + α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				else
					particles[didx, pidx] = pl - α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
				end

				# bound to search space
				particles[didx, pidx] = chaotic_bound(particles[didx, pidx], -pi / 2, pi / 2)
			end
		end
	end

	# Return the result
	return map_to_search_space(gbest), gbest_fitness, fe_count, iter_count
end

# Short-Lived Swarm Layer QPSO
# Note: num_particles is set to 25 in the paper, because the use of particles is different from the original QPSO
# so there is not need to allocate too many particles
function slslqpso(f, lb, ub, d; num_particles = 25, tolerance = 10e-8, fe_cap = Inf64, max_iters = Inf64, max_layers = 20, max_iters_per_layer = 100)
	# docstring for slslqpso
	"""
	Short-Lived Swarm Layer Quantum-behaved Particle Swarm Optimization (SLSL-QPSO) algorithm.
		f: function to be optimized
		lb: lower bound of the search space
		ub: upper bound of the search space
		d: dimension of the search space
		num_particles: number of particles
		tolerance: tolerance of the algorithm
		fe_cap: maximum number of function evaluations
		max_iters: maximum number of iterations
	"""

	# Initialize the personal best positions
	pbests = zeros(d, num_particles)

	# Initialize the personal best fitness
	pbest_fitnesses = fill(Inf64, num_particles)

	# Initialize the global best position
	gbest = zeros(d)

	# Initialize the global best fitness
	gbest_fitness = Inf64

	# Record the number of function evaluations, and the number of iterations
	fe_count = 0
	iter_count = 0

	# Record the gbest_fitness of each layer
	gbest_fitnesses = zeros(max_layers)

	# Record the living interval of layers
	living_interval = [1, max_layers]

	# Enter the main loop
	@inbounds while iter_count <= max_iters

		# For each living layer
		for layer in living_interval[1]:living_interval[2]
			# Uniformly generate particles
			particles = rand(Uniform(lb, ub), d, num_particles)

			# Calculate the range of CE
			α_ub = 1 - 0.5 * (layer - 1) / max_layers
			α_lb = 1 - 0.5 * layer / max_layers

			# For each iteration
			for layer_iter in 1:max_iters_per_layer
                iter_count = iter_count + 1

                if iter_count > max_iters
                    return gbest, gbest_fitness, fe_count, iter_count - 1
                end

				# Calculate fitness for each particle and update pbests and gbest
				for pidx in 1:num_particles
					# Calculate the fitness of the particle
					fitness = f(particles[:, pidx])

					# Update the personal best position and fitness
					if fitness < pbest_fitnesses[pidx]
						pbests[:, pidx] = particles[:, pidx]
						pbest_fitnesses[pidx] = fitness
						# Update the global best position and fitness
						if fitness < gbest_fitness
							gbest = particles[:, pidx]
							gbest_fitness = fitness
						end
					end

					# Update the number of function evaluations
					fe_count += 1

					# If the number of function evaluations exceeds the cap, or the tolerance is reached, return the result
					if fe_count >= fe_cap || gbest_fitness <= tolerance
						return gbest, gbest_fitness, fe_count, iter_count
					end
				end

				# Levy mutation on gbest
				lgbest = zeros(d)
				for didx in 1:d
					if rand(Bernoulli(1 / d))
						lgbest[didx] = gbest[didx] + (rand() - 0.5) * rand(Levy(0, max_iters - iter_count + 1))
						# lgbest[didx] = gbest[didx] + rand(Cauchy(0, 0.2))
                        # bound to search space
                        lgbest[didx] = chaotic_bound(lgbest[didx], lb, ub)
					else
                        lgbest[didx] = gbest[didx]
					end
				end

                # If the fitness of lgbest is better than gbest, update gbest
                lgbest_fitness = f(lgbest)
                if lgbest_fitness < gbest_fitness
                    gbest = lgbest
                    gbest_fitness = lgbest_fitness
                end

                # Update the number of function evaluations
                fe_count += 1

                # If the number of function evaluations exceeds the cap, or the tolerance is reached, return the result
                if fe_count >= fe_cap || gbest_fitness <= tolerance
                    return gbest, gbest_fitness, fe_count, iter_count
                end


				# Calculate the mean best
				mean_best = mean(pbests, dims = 2)

				# Calculate ce
				α = α_lb + (α_ub - α_lb) * ((max_iters_per_layer - layer_iter) / max_iters_per_layer) ^ 2

				# Update the position of each particle
				for pidx in 1:num_particles
					for didx in 1:d
						# Calculate the local attractor
						ψ = rand()
						pl = ψ * pbests[didx, pidx] + (1 - ψ) * gbest[didx]

						# Update the position
						u = rand()
						if rand() > 0.5
							particles[didx, pidx] = pl + α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
						else
							particles[didx, pidx] = pl - α * abs(mean_best[didx] - particles[didx, pidx]) * log(1 / u)
						end

						# bound to search space
						particles[didx, pidx] = chaotic_bound(particles[didx, pidx], lb, ub)
					end
				end
			end

            gbest_fitnesses[layer:end] .= gbest_fitness
		end

		# Update the living interval; the sign is either 0 or -1
        # -1 means the next layer is improved compared to the previous layer
        # 0 means the next layer is not improved compared to the previous layer
        diff = sign.(gbest_fitnesses[2:end] .- gbest_fitnesses[1:end-1])

        # Find the beginning of the next living interval
		index = findfirst(isequal(-1), diff)

        # If the there is no improved layer, the beginning of the next living interval is the first layer
        # and destory the pbests too.
		if isnothing(index)
			index = 1
			pbest_fitnesses = fill(Inf64, num_particles)
		end

        # Update the beginning of the next living interval
		living_interval[1] = index

        # Find the end of the next living interval
		index = findlast(isequal(-1), diff)

        # If the there is no improved layer, the end of the next living interval is the last layer
        # and destory the pbests too.
		if isnothing(index)
			index = max_layers - 1
			pbest_fitnesses = fill(Inf64, num_particles)
		end
		living_interval[2] = index + 1

        # println("iter_count: ", iter_count, " gbest_fitness: ", gbest_fitness, " living_intervals: ", living_interval)

	end
    return gbest, gbest_fitness, fe_count, iter_count
end
