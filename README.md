# SIMDVectors

[![Build Status](https://travis-ci.org/KristofferC/SIMDVectors.jl.svg?branch=master)](https://travis-ci.org/KristofferC/SIMDVectors.jl)

This is currently an experimental package that uses the PR [#15244](https://github.com/JuliaLang/julia/pull/15244) to create a stack allocated fixed size vector which supports SIMD operations. For this package to work, the branch above need to be used and julia need to be started with the `-O3` flag.

Create a `SIMDVector` by using `load(SIMDVector{N}, v, offset=0)` where `N` is the length of the vector, `v` is the vector to load data from and `offset` is an offset into `v` where to start loading data:

```jl
julia> v = load(SIMDVector{7}, rand(12))
7-element SIMDVectors.SIMDVector{3,2,1,Float64}:
 0.0333167
 0.52255
 0.171032
 0.667967
 0.832219
 0.586471
```

This looks like a normal `Vector` but internally the data is packed such that vectorized instructions are used when operators are performed on and between `SIMDVector`'s. If the length of the vector are such that not all numbers fit in the vector registers, scalar operations are performed on the rest.

```jl

julia> va = load(SIMDVector{9}, rand(Float32, 12));

julia> vb = load(SIMDVector{9}, rand(Float32, 12));


julia> @code_native va + vb
...
    vaddps  (%rdx), %xmm0, %xmm0   # One packed add for the first set of four VecElements
    vaddps  16(%rdx), %xmm1, %xmm1 # Second packed adds for second set of four VecElements
    vmovss  32(%rsi), %xmm2
    vaddss  32(%rdx), %xmm2, %xmm2 # One scalar add for the rest
...
```

Operators between two different types will convert like normal vectors:

```jl
julia> va = load(SIMDVector{9}, rand(Float64, 12));

julia> vb = load(SIMDVector{9}, rand(Float32, 12));

julia> va + vb
9-element SIMDVectors.SIMDVector{4,2,1,Float64}:
 0.648343
 1.02155
 0.676522
 0.92291
 1.14035
 1.46949
 0.599293
 1.1952
 1.02997
```

# TODO

A lot.