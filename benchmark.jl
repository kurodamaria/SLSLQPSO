using XLSX
using DataFrames
using Distributed
using Statistics

# To use this file simply include("benchmark.jl") in the REPL after activating the project environment

# Add enough workers
if nprocs() < Sys.CPU_THREADS
	addprocs(Sys.CPU_THREADS - nprocs(), exeflags = "--project")
end

@everywhere using SLSLQPSO

# The first benchmark on simple problems
problem_specs = [
	# tag, function, lb, ub, dimension
	("sphere", sphere, -100, 100, 50),
	("sphere64", sphere64, -100, 100, 50),
	("rosenbrock", rosenbrock, -100, 100, 50),
	("rastrigin", rastrigin, -100, 100, 50),
	("ackley", ackley, -35, 35, 50),
	("levy", levy, -100, 100, 50),
	("schwefel", schwefel, -500, 500, 50),
	("trid", trid, -2500, 2500, 50),
	("zakharov", zakharov, -5, 10, 50),
	("stybtang", stybtang, -100, 100, 50),
]

# Firstly, we run the benchmark on the simple problems on slslqpso to setup the baseline for other algorithms
begin
	runs = 100
	fe_cap = 8000000
	max_iters = 500000
	tolerance = 10e-8

	mode = "w"

	if isfile("benchmark_slslqpso.xlsx")
		mode *= "r"
	end

	XLSX.openxlsx("benchmark_slslqpso.xlsx", mode = mode) do xf
		if mode == "w"
			XLSX.rename!(xf[1], problem_specs[1][1])
		end
		for (tag, func, lb, ub, dim) in problem_specs
			results = @distributed (vcat) for t in 1:runs
				gbest, gbest_fitness, fe_count, iter_count = slslqpso(func, lb, ub, dim; fe_cap = fe_cap, max_iters = max_iters, tolerance = tolerance)
				[gbest_fitness, fe_count, gbest_fitness <= tolerance ? "YES" : "NO"]
			end

			df = DataFrame(:fitness => results[1:3:end],
						   :fe_count => results[2:3:end],
						   :success => results[3:3:end])

			println(df)

			sheetname = tag
			if !XLSX.hassheet(xf, sheetname)
				XLSX.addsheet!(xf, sheetname)
			end
			sheet = xf[sheetname]
			XLSX.writetable!(sheet, df)
		end
	end
end

# Find baselines
median_fe_caps = begin
	filename = "benchmark_slslqpso.xlsx"

	caps = []

	XLSX.openxlsx(filename) do xf
		for (tag, func, lb, ub, dim) in problem_specs
			sheetname = tag
			sheet = xf[sheetname]
			df = DataFrame(XLSX.gettable(sheet))
			push!(caps, median(df[!, :fe_count]))
		end
	end

	caps
end

# Benchmark peer algorithms with baselines
peer_algorithms = [
# ("qpso", qpso),
# ("θqpso", θqpso),
# ("wqpso", wqpso),
	("gaqpso", gaqpso)
]

begin
	runs = 100
	tolerance = 10e-8

	for (tag, algo) in peer_algorithms
		save_file = "benchmark_$tag.xlsx"
		mode = "w"

		if isfile(save_file)
			mode *= "r"
		end

		XLSX.openxlsx(save_file, mode = mode) do xf
			if mode == "w"
				XLSX.rename!(xf[1], problem_specs[1][1])
			end

			for (i, spec) in enumerate(problem_specs)
				tag, func, lb, ub, dim = spec

				fe_cap = median_fe_caps[i]

				# For fairness, the max_iters is calculated from the fe_cap, because the max_iters is required to calculate CE
				max_iters = Int(ceil(fe_cap / dim))

				results = @distributed (vcat) for t in 1:runs
					gbest, gbest_fitness, fe_count, iter_count = algo(func, lb, ub, dim; fe_cap = fe_cap, max_iters = max_iters, tolerance = tolerance)
					[gbest_fitness, fe_count, gbest_fitness <= tolerance ? "YES" : "NO"]
				end

				df = DataFrame(:fitness => results[1:3:end],
							   :fe_count => results[2:3:end],
							   :success => results[3:3:end])

				println(df)

				sheetname = tag
				if !XLSX.hassheet(xf, sheetname)
					XLSX.addsheet!(xf, sheetname)
				end
				sheet = xf[sheetname]
				XLSX.writetable!(sheet, df)
			end
		end
	end
end

# Experiment 2: Compare the performance of slslqpso and gaqpso on the CEC 2020 benchmark
begin
	algorithms = [
		("qpso", qpso),
		("θqpso", θqpso),
		("wqpso", wqpso),
		("gaqpso", gaqpso),
		("slslqpso", slslqpso),
	]

	problems = [
		("cec2020_f1", cec2020_f1),
		("cec2020_f2", cec2020_f2),
		("cec2020_f3", cec2020_f3),
		("cec2020_f4", cec2020_f4),
		("cec2020_f5", cec2020_f5),
		("cec2020_f6", cec2020_f6),
		("cec2020_f7", cec2020_f7),
		("cec2020_f8", cec2020_f8),
		("cec2020_f9", cec2020_f9),
		("cec2020_f10", cec2020_f10),
	]

	runs = 100
	fe_cap = 1000000
	max_iters = Int(ceil(fe_cap / 50))

	for (algo_tag, algo) in algorithms
		save_file = "benchmark_$algo_tag.xlsx"

		mode = "w"
		if isfile(save_file)
			mode *= "r"
		end

		XLSX.openxlsx(save_file, mode = mode) do xf
			for (problem_tag, problem) in problems
				println("Running $algo_tag on $problem_tag")
				results = @distributed (vcat) for t in 1:runs
					if algo == slslqpso
						max_iters = Int(ceil(fe_cap / 25))
					else
						max_iters = Int(ceil(fe_cap / 50))
					end
					gbest, gbest_fitness, fe_count, iter_count = algo(problem, -100, 100, 50; fe_cap = fe_cap, max_iters = max_iters, tolerance = 10e-8)
					[gbest_fitness, fe_count, gbest_fitness <= 10e-8 ? "YES" : "NO"]
				end

				df = DataFrame(:fitness => results[1:3:end],
							   :fe_count => results[2:3:end],
							   :success => results[3:3:end])

				println(df)

				sheetname = problem_tag
				if !XLSX.hassheet(xf, sheetname)
					XLSX.addsheet!(xf, sheetname)
				end
				sheet = xf[sheetname]
				XLSX.writetable!(sheet, df)
			end
		end
	end
end
