# SIMDVectors

[![Build Status](https://travis-ci.org/KristofferC/SIMDVectors.jl.svg?branch=master)](https://travis-ci.org/KristofferC/SIMDVectors.jl)

This is currently an experimental package that uses the PR [#15244](https://github.com/JuliaLang/julia/pull/15244) to create a stack allocated fixed size vector which supports SIMD operations. For this package to work, the branch above needs to be used and julia needs to be started with the `-O3` flag.

A `SIMDVector` can be created by for example using `load(SIMDVector{N}, v, offset=0)` where `N` is the length of the vector, `v` is vector to load data from and `offset` is an offset into `v` where to start loading data:

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

This looks like a normal `Vector` but internally the data is packed such that vectorized instructions are used when operators are performed on and between `SIMDVector`'s. If the length of the vector are such that not all numbers fit in vector registers, scalar operations are performed on the rest.

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

## Promotions

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

## User defined number types

`SIMDVector`'s' should gracefully handle arbitrary julia number types. This makes it so that a `SIMDVector` can be used even if you are unsure what data it will hold.

```jl
julia> a = load(SIMDVector{4}, big(rand(12))); # Load Big floats into a SIMDVector

julia> a+a # Works fine
4-element SIMDVectors.SIMDVector{0,0,4,BigFloat}:
 2.531343636343290626200541737489402294158935546875000000000000000000000000000000e-01
 3.366090705330369026171410951064899563789367675781250000000000000000000000000000e-01
 1.697265196033196144043131425860337913036346435546875000000000000000000000000000
 1.206431829930139532081057041068561375141143798828125000000000000000000000000000
```



## TODO

- A lot