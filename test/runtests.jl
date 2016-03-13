using SIMDVectors
using Base.Test

import SIMDVectors: VecRegister

# SIMDVector
for LENGTH in (2, 5, 11)
	for T in (Float32, Float64, Int32, Int64)
		if T <: Integer
			# Use small numbers to prevent overflows
			vals = rand(T(1):T(10), LENGTH)
			vals2 = rand(T(1):T(10), LENGTH)
		else
			vals = rand(T, LENGTH)
			vals2 = rand(T, LENGTH)
		end
		s_vec = load(SIMDVector{LENGTH}, vals)
		s_vec2 = load(SIMDVector{LENGTH}, vals2)

		println(length(vals))

		store_vec = similar(vals)
		store!(store_vec, s_vec)
		@test store_vec == vals

		println("\nTesting unary functions length = $LENGTH, T = $T")
		for f in SIMDVectors.UNARY_FUNCS
			println(f)
			@eval func = $f
			if !method_exists(func, Tuple{T})
				continue
			end
			local f_s_vec
			try
				f_s_vec = func(s_vec)
			catch e
				(isa(e, DomainError) || isa(e, Base.Math.AmosException)) || rethrow(e)
				continue
			end
			@test f_s_vec[1] === func(vals[1])
			@test f_s_vec[end] === func(vals[end])
		end

		println("\nTesting binary functions length = $LENGTH, T = $T")
		for f in SIMDVectors.BINARY_FUNCS
			@eval func = $f
			println(f)
			if !method_exists(func, Tuple{T, T}) || !method_exists(func, Tuple{Vector{T}, Vector{T}})
				continue
			end
			local binary_s_vec
			local binary_vec
			try
				binary_s_vec = func(s_vec, s_vec2)
				binary_vec = func(vals, vals2)
			catch e
				(isa(e, DomainError) || isa(e, Base.Math.AmosException)) || rethrow(e)
				continue
			end

			@test binary_s_vec[1] === binary_vec[1]
			@test binary_s_vec[end] === binary_vec[end]
		end

		println("\nTesting reductions length = $LENGTH, T = $T")
		for (f, f_scal) in SIMDVectors.REDUCTION_FUNCS
			println(f)
			@eval func = $f
			@test func(s_vec) ≈ func(vals)
		end
	end
end
