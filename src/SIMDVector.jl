import Base.Operators: +, *, .*, ./, -, /

immutable SIMDVector{M, N, R, T <: Number} <: AbstractVector{T}
    simd_vecs::NTuple{M, SIMDElement{N, T}}
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
        bucket = 1
        while i < bucket * N; bucket += 1 end
#        bucket = div(i-1, N) + 1
        @inbounds val = v.simd_vecs[bucket][i - (bucket-1)*N].value
        return val
    end
end

function compute_lengths(N, T)
    if T == Float64 || T == Int64
        simd_len = 2
    elseif T == Float32 || T == Int32
        simd_len = 4
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
            push!(simd_array_create_expr.args,
                  Expr(:tuple, [:(VecElement(data[$j + offset])) for j in i:simd_len+i-1]...))
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


# Binary operators between two SIMDVectors
for (oper, tuple_oper) in ((:+, add_tuples),
                           (:-, subtract_tuples),
                           (:.*, mul_tuples),
                           (:./, div_tuples))
    @eval begin
        @generated function $(oper){M, N, R, T}(a::SIMDVector{M, N, R, T}, b::SIMDVector{M, N, R, T})
            ex_simd = SIMDVectors.vectupexpr(i -> :(($($oper))(a.simd_vecs[$i], b.simd_vecs[$i])), M)
            return quote
                $(Expr(:meta, :inline))
                SIMDVector{M, N, R, T}($ex_simd, $($(tuple_oper))(a.rest, b.rest))
            end
        end

        # Just a::SIMDVector, b::SIMDVector didn't work...
        function $(oper){M1, N1, R1, T1, M2, N2, R2, T2}(a::SIMDVector{M1, N1, R1, T1},
                                                         b::SIMDVector{M2, N2, R2, T2})
            $(oper)(promote(a,b)...)
        end
    end
end

# Binary operator SIMDVector and number
for (oper, tuple_oper) in ((:*, scale_tuple),
                           (:/, div_tuple_by_scalar))
    @eval begin
        @generated function $(oper){M, N, R, T}(a::SIMDVector{M, N, R, T}, n::Number)
            ex_simd = SIMDVectors.vectupexpr(i -> :(($($oper))(a.simd_vecs[$i], n)), M)
            return quote
                $(Expr(:meta, :inline))
                SIMDVector($ex_simd, $($(tuple_oper))(a.rest, n))
            end
        end
    end
end


Base.(:*){M, N, R, T <: Number}(b::T, a::SIMDVector{M, N, R, T}) = a * b

# Unary operators on SIMDVector
@generated function (-){M, N, R, T}(a::SIMDVector{M, N, R, T})
    ex_simd = SIMDVectors.vectupexpr(i -> :(-a.simd_vecs[$i]), M)
    return quote
        $(Expr(:meta, :inline))
        SIMDVector($ex_simd, minus_tuple(a.rest))
    end
end

@generated function Base.rand{M, N, R, T}(a::Type{SIMDVector{M, N, R, T}})
    ex_simd = SIMDVectors.vectupexpr(i -> :(rand(SIMDElement{N, T})), M)
    return quote
        $(Expr(:meta, :inline))
        SIMDVector($ex_simd, rand_tuple(NTuple{R, T}))
    end
end

@generated function Base.zero{M, N, R, T}(a::Type{SIMDVector{M, N, R, T}})
    ex_simd = SIMDVectors.vectupexpr(i -> :z, M)
    return quote
        $(Expr(:meta, :inline))
        z = zero(SIMDElement{N, T})
        SIMDVector($ex_simd, zero_tuple(NTuple{R, T}))
    end
end

@generated function Base.one{M, N, R, T}(a::Type{SIMDVector{M, N, R, T}})
    ex_simd = SIMDVectors.vectupexpr(i -> :z, M)
    return quote
        $(Expr(:meta, :inline))
        z = one(SIMDElement{N, T})
        SIMDVector($ex_simd, one_tuple(NTuple{R, T}))
end

# Elementwise unary functions
for f in (:sin, :cos, :exp)
    @eval begin
        function Base.$(f{N}(a::SIMDVector{M, N, R, T})
            return SIMDVector($f(a.simd_vecs), map(f, a.rest))
        end
    end
end
