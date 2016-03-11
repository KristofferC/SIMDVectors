# SIMDVectors

[![Build Status](https://travis-ci.org/KristofferC/SIMDVectors.jl.svg?branch=master)](https://travis-ci.org/KristofferC/SIMDVectors.jl)

This is currently an experimental package to exploit the PR [#15244](https://github.com/JuliaLang/julia/pull/15244) to create a stack allocated fixed size vector which supports SIMD operations. For this package to work, the branch above need to be used and julia need to be started with the `-O3` flag.

Create a `SIMDVector` by using `load(SIMDVector{N}, v, offset=0)` where `N` is the length of the vector, `v` is the vector to load data from and `offset` is an offset into `v` where to start loading data:

```jl
julia> s_vec = load(SIMDVector{7}, rand(12))
7-element SIMDVectors.SIMDVector{3,2,1,Float64}:
  VecElement{Float64}(0.998235)
  VecElement{Float64}(0.463173)
  VecElement{Float64}(0.0642392)
  VecElement{Float64}(0.626504)
  VecElement{Float64}(0.672788)
  VecElement{Float64}(0.510326)
 0.851211
```

Here we created a vector with six `VecElements` and one number. Each of these `VectorElements` are internally packed two and two so that the 128 bit registers are used when operations are performed.

If we instead load a `Float32` array:

```jl
julia> s_vec = load(SIMDVector{9}, rand(Float32, 12))
7-element SIMDVectors.SIMDVector{1,4,3,Float32}:
  VecElement{Float32}(0.460927)
  VecElement{Float32}(0.921905)
  VecElement{Float32}(0.624384)
  VecElement{Float32}(0.369023)
  VecElement{Float32}(0.222655)
  VecElement{Float32}(0.459265)
  VecElement{Float32}(0.472598)
  VecElement{Float32}(0.527452)
 0.197042
```

we instead pack four `VecElements` together so once again the 128 bit registers are used.

Operators between `SIMDVectors` generate vectorized instructions for the packed `VecElements` and scalar instructions for the rest that don't fit in a vector register:

```jl

julia> s_vec_a = load(SIMDVector{9}, rand(Float32, 12))

julia> s_vec_b = load(SIMDVector{9}, rand(Float32, 12))


julia> @code_native s_vec_a + s_vec_b
.
    vaddps  (%rdx), %xmm0, %xmm0   # One packed add for the first set of four VecElements
    vaddps  16(%rdx), %xmm1, %xmm1 # Second packed adds for second set of four VecElements
    vmovss  32(%rsi), %xmm2        # xmm2 = mem[0],zero,zero,zero
    vaddss  32(%rdx), %xmm2, %xmm2 # One scalar add for the rest
.
```

# TODO

A lot.