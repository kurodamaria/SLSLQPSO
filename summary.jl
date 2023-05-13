using XLSX
using DataFrames
using Printf
using GLMakie
using Statistics

# Make summaries of benchmark data

# Open all the benchmark data, store the file handlers in a dictionary
benchmark_data = Dict(:qpso => XLSX.openxlsx("benchmark_qpso.xlsx"),
					  :θqpso => XLSX.openxlsx("benchmark_θqpso.xlsx"),
					  :wqpso => XLSX.openxlsx("benchmark_wqpso.xlsx"),
					  :gaqpso => XLSX.openxlsx("benchmark_gaqpso.xlsx"),
					  :slslqpso => XLSX.openxlsx("benchmark_slslqpso.xlsx"))

# Create summary.xlsx if it does not exist
begin
    if !isfile("summary.xlsx")
        XLSX.openxlsx("summary.xlsx", mode = "w") do xf
        end
    end
end

# Summary for experiment 1
simple_functions = [
	"sphere", "sphere64", "rosenbrock", "rastrigin", "ackley", "schwefel",
	"levy", "trid", "zakharov", "stybtang",
]

# 1. Summary the performance of slslqpso on simple problems
begin XLSX.openxlsx("summary.xlsx", mode = "wr") do xf
	sheetname = "slslqpso on simple problems"
	if XLSX.hassheet(xf, "Sheet1")
		XLSX.rename!(xf["Sheet1"], sheetname)
	elseif !XLSX.hassheet(xf, sheetname)
		XLSX.addsheet!(xf, sheetname)
	end

	sheet = xf[sheetname]
	# set header for the sheet
	sheet["A1"] = "Function"
	sheet["B1"] = "Median fe_count"
	sheet["C1"] = "Mean fitness"
	sheet["D1"] = "Std fitness"
	sheet["E1"] = "Success count"
	for (i, func) in enumerate(simple_functions)
		sheet["A$(i + 1)"] = func
		data = DataFrame(XLSX.gettable(benchmark_data[:slslqpso][func]))
		sheet["B$(i + 1)"] = median(data[!, :fe_count])
		sheet["C$(i + 1)"] = mean(data[!, :fitness])
		sheet["D$(i + 1)"] = std(data[!, :fitness])
		sheet["E$(i + 1)"] = count(x -> x == "YES", data[!, :success])
	end
end end

# 2. The table of name ranking of algorithms on each function
begin XLSX.openxlsx("summary.xlsx", mode = "wr") do xf
	sheetname = "slslqpso vs others sps"

    if XLSX.hassheet(xf, "Sheet1")
        XLSX.rename!(xf["Sheet1"], sheetname)
    elseif !XLSX.hassheet(xf, sheetname)
        XLSX.addsheet!(xf, sheetname)
    end

	sheet = xf[sheetname]

	# set header for the sheet
	sheet["A1"] = "Rank"
	# prefill ranks
	for i in 1:5
		sheet["A$(i + 1)"] = i
	end

	# Now rank the algorithms on each function based on the mean fitness.
	# Sort the algorithms based on the mean fitness. The smaller the mean fitness, the better the algorithm.
	# The best algorithm gets rank 1, the second best gets rank 2, and so on.

	for (i, func) in enumerate(simple_functions)
		# read mean fitness of each algorithm on this function into a list of pairs.
		# for example: [("QPSO", 0.1), ("θ-QPSO", 0.2), ...]
		mean_fitness = [
			("QPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:qpso][func]))[!, :fitness])),
			("θ-QPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:θqpso][func]))[!, :fitness])),
			("WQPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:wqpso][func]))[!, :fitness])),
			("GAQPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:gaqpso][func]))[!, :fitness])),
			("SLSL-QPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:slslqpso][func]))[!, :fitness])),
		]

		# sort the list of pairs based on the second element of each pair (the mean fitness)
		sort!(mean_fitness, by = x -> x[2])

		sheet[1, i + 1] = func
		for j in 1:5
			sheet[j + 1, i + 1] = mean_fitness[j][1]
		end

		# write the sorted list of pairs into the sheet
		# for j in 1:5
		#     sheet["$(j + 1)$(i + 1)"] = mean_fitness[j][1]
		# end
	end
end end

# 3. The table of success counts of algorithms on each function
begin XLSX.openxlsx("summary.xlsx", mode = "wr") do xf
	sheetname = "slslqpso vs others sc"
    if XLSX.hassheet(xf, "Sheet1")
        XLSX.rename!(xf["Sheet1"], sheetname)
    elseif !XLSX.hassheet(xf, sheetname)
        XLSX.addsheet!(xf, sheetname)
    end
	sheet = xf[sheetname]

	# Set header for the sheet
	sheet["A1"] = "Function"
	sheet["B1"] = "QPSO"
	sheet["C1"] = "θ-QPSO"
	sheet["D1"] = "WQPSO"
	sheet["E1"] = "GAQPSO"
	sheet["F1"] = "SLSL-QPSO"

	for (i, func) in enumerate(simple_functions)
		sheet["A$(i + 1)"] = func
		sheet["B$(i + 1)"] = count(x -> x == "YES", DataFrame(XLSX.gettable(benchmark_data[:qpso][func]))[!, :success])
		sheet["C$(i + 1)"] = count(x -> x == "YES", DataFrame(XLSX.gettable(benchmark_data[:θqpso][func]))[!, :success])
		sheet["D$(i + 1)"] = count(x -> x == "YES", DataFrame(XLSX.gettable(benchmark_data[:wqpso][func]))[!, :success])
		sheet["E$(i + 1)"] = count(x -> x == "YES", DataFrame(XLSX.gettable(benchmark_data[:gaqpso][func]))[!, :success])
		sheet["F$(i + 1)"] = count(x -> x == "YES", DataFrame(XLSX.gettable(benchmark_data[:slslqpso][func]))[!, :success])
	end
end end

# 4. The table of mean fitness of algorithms on each function
begin XLSX.openxlsx("summary.xlsx", mode = "wr") do xf
	sheetname = "slslqpso vs others mf"
    if XLSX.hassheet(xf, "Sheet1")
        XLSX.rename!(xf["Sheet1"], sheetname)
    elseif !XLSX.hassheet(xf, sheetname)
        XLSX.addsheet!(xf, sheetname)
    end
	sheet = xf[sheetname]

	# Set header for the sheet
	sheet["A1"] = "Function"
	sheet["B1"] = "QPSO"
	sheet["C1"] = "θ-QPSO"
	sheet["D1"] = "WQPSO"
	sheet["E1"] = "GAQPSO"
	sheet["F1"] = "SLSL-QPSO"

	for (i, func) in enumerate(simple_functions)
		sheet["A$(i + 1)"] = func
		sheet["B$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:qpso][func]))[!, :fitness])
		sheet["C$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:θqpso][func]))[!, :fitness])
		sheet["D$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:wqpso][func]))[!, :fitness])
		sheet["E$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:gaqpso][func]))[!, :fitness])
		sheet["F$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:slslqpso][func]))[!, :fitness])
	end
end end

# Experiment 2
cec2020_functions = [
	"cec2020_f1",
	"cec2020_f2",
	"cec2020_f3",
	"cec2020_f4",
	"cec2020_f5",
	"cec2020_f6",
	"cec2020_f7",
	"cec2020_f8",
	"cec2020_f9",
	"cec2020_f10",
]

# 1. The table of name ranking of algorithms on each cec2020 function based on the mean fitness.
begin XLSX.openxlsx("summary.xlsx", mode = "wr") do xf
	sheetname = "cec2020 name ranking"
    if XLSX.hassheet(xf, "Sheet1")
        XLSX.rename!(xf["Sheet1"], sheetname)
    elseif !XLSX.hassheet(xf, sheetname)
        XLSX.addsheet!(xf, sheetname)
    end
	sheet = xf[sheetname]

	# set header for the sheet
	sheet["A1"] = "Rank"
	# prefill ranks
	for i in 1:5
		sheet["A$(i + 1)"] = i
	end

	# The best algorithm gets rank 1, the second best gets rank 2, and so on.

	for (i, func) in enumerate(cec2020_functions)
		# read mean fitness of each algorithm on this function into a list of pairs.
		# for example: [("QPSO", 0.1), ("θ-QPSO", 0.2), ...]
		mean_fitness = [
			("QPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:qpso][func]))[!, :fitness])),
			("θ-QPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:θqpso][func]))[!, :fitness])),
			("WQPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:wqpso][func]))[!, :fitness])),
			("GAQPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:gaqpso][func]))[!, :fitness])),
			("SLSL-QPSO", mean(DataFrame(XLSX.gettable(benchmark_data[:slslqpso][func]))[!, :fitness])),
		]

		# sort the list of pairs based on the second element of each pair (the mean fitness)
		sort!(mean_fitness, by = x -> x[2])

		sheet[1, i + 1] = func
		for j in 1:5
			sheet[j + 1, i + 1] = mean_fitness[j][1]
		end
	end
end end

# 2. The table of mean fitness of algorithms on each cec2020 function
begin XLSX.openxlsx("summary.xlsx", mode = "wr") do xf
    sheetname = "cec2020 mf"
    if XLSX.hassheet(xf, "Sheet1")
        XLSX.rename!(xf["Sheet1"], sheetname)
    elseif !XLSX.hassheet(xf, sheetname)
        XLSX.addsheet!(xf, sheetname)
    end
    sheet = xf[sheetname]

    # Set header for the sheet
    sheet["A1"] = "Function"
    sheet["B1"] = "QPSO"
    sheet["C1"] = "θ-QPSO"
    sheet["D1"] = "WQPSO"
    sheet["E1"] = "GAQPSO"
    sheet["F1"] = "SLSL-QPSO"

    for (i, func) in enumerate(cec2020_functions)
        sheet["A$(i + 1)"] = func
        sheet["B$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:qpso][func]))[!, :fitness])
        sheet["C$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:θqpso][func]))[!, :fitness])
        sheet["D$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:wqpso][func]))[!, :fitness])
        sheet["E$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:gaqpso][func]))[!, :fitness])
        sheet["F$(i + 1)"] = mean(DataFrame(XLSX.gettable(benchmark_data[:slslqpso][func]))[!, :fitness])
    end
end end