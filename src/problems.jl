using HardTestProblems

export sphere, sphere64, rastrigin, ackley, levy, schwefel, trid, zakharov, rosenbrock, stybtang, cec2020_f1, cec2020_f2, cec2020_f3, cec2020_f4, cec2020_f5, cec2020_f6, cec2020_f7, cec2020_f8, cec2020_f9, cec2020_f10

function sphere(x::Vector{Float64})
	return sum(x .^ 2)
end

function sphere64(x::Vector{Float64})
	return sum((x .- 64) .^ 2)
end

function rastrigin(x::Vector{Float64})
	A = 10
	n = length(x)
	return A * n + sum(x .^ 2 .- A * cos.(2 * pi * x))
end

# There are some numerical erros due to the representation of the floating numbers
# So the minimum is not exactly 0 at (0, 0, ..., 0)
# Since we are testing 50-dimensional problems,
# we can just minus ackley(fill(0, 50)) (which is 0.000000000000000444089209850062616169452667236328125) to force the minimum to be 0 at 50-dimension.
function ackley(x::Vector{Float64})
	a = 20
	b = 0.2
	c = 2 * pi
	d = length(x)
	sum1 = sum(x .^ 2)
	sum2 = sum(cos.(c * x))
	term1 = -a * exp(-b * sqrt(sum1 / d))
	term2 = -exp(sum2 / d)
	return term1 + term2 + a + exp(1) - 0.000000000000000444089209850062616169452667236328125
end


function levy(x::Vector{Float64})
	n = length(x)
	z = 1 .+ (x .- 1) ./ 4
	sum1 = sum((z[1:end-1] .- 1) .^ 2 .* (1 .+ 10 * sin.(pi * z[1:end-1] .+ 1) .^ 2))
	sum2 = (z[end] - 1)^2
	return pi / n * (10 * sin(pi * z[1])^2 + sum1 + sum2) + sum((x .- 1) .^ 2 .* (1 .+ sin.(2 * pi * x) .^ 2))
end


# There are some numerical erros due to the representation of the floating numbers
# So the minimum is not exactly 0 at (420.9687, 420.9687, ..., 420.9687)
# Since we are testing 50-dimensional problems,
# we can just minus schwefel(fill(420.9687, 50)) (which is 0.0006363918728311546146869659423828125) to force the minimum to be 0 at 50-dimension.
function schwefel(x::Vector{Float64})
	n = length(x)
	return 418.9829 * n - sum(x .* sin.(sqrt.(abs.(x)))) - 0.0006363918728311546146869659423828125
end

function trid(x::Vector{Float64})
	n = length(x)
	m = -n * (n + 4) * (n - 1) / 6
	return sum((x .- 1) .^ 2) - sum(x[2:end] .* x[1:end-1]) - m
end

function zakharov(x::Vector{Float64})
	n = length(x)
	s2 = sum(0.5 * (1:n) .* x)
	return sum(x .^ 2) + s2^2 + s2^4
end


function rosenbrock(x::Vector{Float64})
	n = length(x)
	return sum(100 * (x[2:end] .- x[1:end-1] .^ 2) .^ 2 .+ (x[1:end-1] .- 1) .^ 2)
end

# For the same reason as ackley and schwefel,
# we can just minus stybtang(fill(0, 50)) (which is -39.16599 * 50) to force the minimum to be 0 at 50-dimension.
function stybtang(x::Vector{Float64})
	n = length(x)
	return sum(x .^ 4 .- 16 * x .^ 2 .+ 5 * x) ./ 2 - (-39.16599 * n) - -0.00878518856961818528361618518829345703125
end

function cec2020_f1(x)
    return HardTestProblems.cec2020_f1(x) - get_cec2020_minimum(1)
end

function cec2020_f2(x)
    return HardTestProblems.cec2020_f2(x) - get_cec2020_minimum(2)
end

function cec2020_f3(x)
    return HardTestProblems.cec2020_f3(x) - get_cec2020_minimum(3)
end

function cec2020_f4(x)
    return HardTestProblems.cec2020_f4(x) - get_cec2020_minimum(4)
end

function cec2020_f5(x)
    return HardTestProblems.cec2020_f5(x) - get_cec2020_minimum(5)
end

function cec2020_f6(x)
    return HardTestProblems.cec2020_f6(x) - get_cec2020_minimum(6)
end

function cec2020_f7(x)
    return HardTestProblems.cec2020_f7(x) - get_cec2020_minimum(7)
end

function cec2020_f8(x)
    return HardTestProblems.cec2020_f8(x) - get_cec2020_minimum(8)
end

function cec2020_f9(x)
    return HardTestProblems.cec2020_f9(x) - get_cec2020_minimum(9)
end

function cec2020_f10(x)
    return HardTestProblems.cec2020_f10(x) - get_cec2020_minimum(10)
end