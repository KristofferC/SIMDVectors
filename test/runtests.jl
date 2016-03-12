using SIMDVectors
using Base.Test

# VecRegister
for T in (Float32, Float64)
	a1 = rand(T)
	a2 = rand(T)
	v_ele = VecRegister((VecElement(a1), VecElement(a2)))
	for f in (sin, cos, exp)
		f_v_ele = f(v_ele)
		@test f(v_ele[1]) == f(a1)
		@test f(v_ele[2]) == f(a2)
	end
end

# SIMDVector
LENGTH = 11
for T in (Float32, Float64)
	vals = rand(T, LENGTH)
	vals2 = rand(T, LENGTH)
	s_vec = load(SIMDVector{LENGTH}, vals)
	s_vec2 = load(SIMDVector{LENGTH}, vals2)
	for f in (sin, cos, exp)
		f_s_vec = f(s_vec)
		@test f_s_vec[1] == f(vals[1])
		@test f_s_vec[end] == f(vals[end])
	end

	for f in (+, -, .*, ./)
		binary_s_vec = f(s_vec, s_vec2)
		binary_vec = f(vals, vals2)
		@test binary_s_vec[1] == binary_vec[1]
		@test binary_s_vec[end] == binary_vec[end]
	end
end

