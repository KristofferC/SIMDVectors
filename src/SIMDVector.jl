immutable SIMDVector{M, N, R, T <: Number} <: AbstractVector{T}
    simd_vecs::NTuple{M, VecRegister{N, T}}
    rest::NTuple{R, T}
end

Base.size{M, N, R}(::SIMDVector{M, N, R}) = (R + M * N,)

# TODO: Try make this more efficient
function Base.getindex{M, N}(v::SIMDVector{M, N}, i::Int)
    @boundscheck checkbounds(v, i)
    if i > M * N
        @inbounds val = v.rest[i - M*N]
        return val
    else
        # TODO, while loop instead of div
        bucket = div(i-1, N) + 1
        @inbounds val = v.simd_vecs[bucket][i - (bucket-1)*N]
        return val
    end
end

function compute_lengths(N, T)
    if T in VECTOR_DATATYPES
        simd_len = div(VEC_REGISTER_SIZE_BITS , sizeof(T) * 8)
    else # Default to store all other types in the rest field which is a normal tuple
        simd_len = 0
    end

    if simd_len == 0
        rest = N
        buckets = 0
    else
        rest = Int(N % simd_len)
        buckets = div(N - rest, simd_len)
    end

    return simd_len, rest, buckets
end



@generated function load{N}(::Type{SIMDVector{N}}, data, offset::Int = 0)
    T = eltype(data)
    simd_len, rest, buckets = compute_lengths(N, T)

    simd_array_create_expr = Expr(:tuple)
    if simd_len != 0
        for i in 1:simd_len:N-rest
            exp_simd_ele = Expr(:call, :VecRegister)
            push!(exp_simd_ele.args, Expr(:tuple, [:(VecElement(data[$j + offset])) for j in i:simd_len+i-1]...))
            push!(simd_array_create_expr.args, exp_simd_ele)
        end
    end

    rest_array_create_expr = Expr(:tuple, [:(data[$j + offset]) for j in (N-rest+1):N]...)

    return quote
        @assert $N + offset <= length(data)
        @inbounds simd_tup =  $simd_array_create_expr
        @inbounds rest = $rest_array_create_expr
        SIMDVector{$buckets, $simd_len, $rest, $T}(simd_tup, rest)
    end
end

function store!{M, N, R, T}(data, v::SIMDVector{M,N,R,T}, offset::Int = 0)
    @assert length(data) + offset >= M*N + R
    c = 1 + offset
    #@inbounds
    for i in 1:M
        simd_element = v.simd_vecs[i]
        @simd for j in 1:N
            data[c] = simd_element[j]
            c += 1
        end
    end

    @simd for i in 1:R
        @inbounds data[c] = v.rest[c]
        c += 1
    end
    return data
end


# Elementwise unary functions
for f in UNARY_FUNCS
    tuple_f_string = symbol(string(f) * "_tuple")
    @eval begin
        @generated function Base.$(f){M, N, R, T}(a::SIMDVector{M, N, R, T})
            ex_simd = SIMDVectors.vectupexpr(i -> :(($($f))(a.simd_vecs[$i])), M)
            return quote
                SIMDVector($ex_simd, $($(tuple_f_string))(a.rest))
            end
        end
    end
end

# Binary functions between two vectors and vector, number.
for f in BINARY_FUNCS
    tuple_f_string = symbol(string(f) * "_tuple")
    @eval begin
        @generated function Base.$(f){M, N, R, T <: Number}(a::SIMDVector{M, N, R, T}, b::SIMDVector{M, N, R, T})
            ex_simd = SIMDVectors.vectupexpr(i -> :(($($f))(a.simd_vecs[$i], b.simd_vecs[$i])), M)
            return quote
                SIMDVector($ex_simd, $($(tuple_f_string))(a.rest, b.rest))
            end
        end

        @generated function Base.$(f){M, N, R, T <: Number}(a::SIMDVector{M, N, R, T}, b::Number)
            ex_simd = SIMDVectors.vectupexpr(i -> :(($($f))(a.simd_vecs[$i], b)), M)
            return quote
                SIMDVector($ex_simd, $($(tuple_f_string))(a.rest, b))
            end
        end

        @generated function Base.$(f){M, N, R, T <: Number}(b::Number, a::SIMDVector{M, N, R, T})
            ex_simd = SIMDVectors.vectupexpr(i -> :(($($f))(b, a.simd_vecs[$i])), M)
            return quote
                SIMDVector($ex_simd, $($(tuple_f_string))(b, a.rest))
            end
        end

        function $(f){M1, N1, R1, T1, M2, N2, R2, T2}(a::SIMDVector{M1, N1, R1, T1},
                                                      b::SIMDVector{M2, N2, R2, T2})
            $(f)(promote(a,b)...)
        end
    end
end


@generated function Base.rand{M, N, R, T}(a::Type{SIMDVector{M, N, R, T}})
    ex_simd = SIMDVectors.vectupexpr(i -> :(rand(VecRegister{N, T})), M)
    return quote
        $(Expr(:meta, :inline))
        SIMDVector($ex_simd, rand_tuple(NTuple{R, T}))
    end
end

@generated function Base.zero{M, N, R, T}(a::Type{SIMDVector{M, N, R, T}})
    ex_simd = SIMDVectors.vectupexpr(i -> :z, M)
    return quote
        $(Expr(:meta, :inline))
        z = zero(VecRegister{N, T})
        SIMDVector($ex_simd, zero_tuple(NTuple{R, T}))
    end
end

@generated function Base.one{M, N, R, T}(a::Type{SIMDVector{M, N, R, T}})
    ex_simd = SIMDVectors.vectupexpr(i -> :z, M)
    return quote
        $(Expr(:meta, :inline))
        z = one(VecRegister{N, T})
        SIMDVector($ex_simd, one_tuple(NTuple{R, T}))
    end
end
