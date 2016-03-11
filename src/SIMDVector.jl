import Base.Operators: +, *, .*, ./, -, /

immutable SIMDVector{M, N, R, T <: Number} <: AbstractVector{T}
    simd_vecs::NTuple{M, SIMDElement{N, T}}
    rest::NTuple{R, T}
end

Base.size{M, N, R}(::SIMDVector{M, N, R}) = (R + M * N,)

# TODO: Make this efficient
function Base.getindex{M, N}(v::SIMDVector{M, N}, i::Int)
    @boundscheck checkbounds(v, i)
    if i > M * N
        return v.rest[i - M*N]
    else
        bucket = div(i-1, N) + 1
        return v.simd_vecs[bucket][i - (bucket-1)*N]
    end
end

@generated function load{N, T <: Number}(::Type{SIMDVector{N}}, data::Vector{T}, offset::Int = 0)
    if T == Float64
        simd_len = 2
    elseif T == Float32
        simd_len = 4
    else
        return quote error("Unsupported type") end
    end

    rest = N % simd_len
    buckets = div(N - rest, simd_len)

    simd_array_create_expr = Expr(:tuple)
    for i in 1:simd_len:N-rest
        push!(simd_array_create_expr.args,
              Expr(:tuple, [:(VecElement(data[$j + offset])) for j in i:simd_len+i-1]...))
    end

    rest_array_create_expr = Expr(:tuple, [:(data[$j + offset]) for j in (N-rest+1):N]...)

    return quote
        @assert $N + offset <= length(data)
        @inbounds simd_tup =  $simd_array_create_expr
        @inbounds rest = $rest_array_create_expr
        SIMDVector(simd_tup, rest)
    end
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
                simd_tup = $ex_simd
                SIMDVector{M, N, R, T}(simd_tup, $($(tuple_oper))(a.rest, b.rest))
            end
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
                simd_tup = $ex_simd
                SIMDVector{M, N, R, T}(simd_tup, $($(tuple_oper))(a.rest, n))
            end
        end
    end
end


Base.(:*){M, N, R, T}(b::Number, a::SIMDVector{M, N, R, T}) = a * b

# Unary operators on SIMDVector
@generated function (-){M, N, R, T}(a::SIMDVector{M, N, R, T})
    ex_simd = SIMDVectors.vectupexpr(i -> :(-a.simd_vecs[$i]), M)
    return quote
        $(Expr(:meta, :inline))
        simd_tup = $ex_simd
        SIMDVector{M, N, R, T}(simd_tup, minus_tuple(a.rest))
    end
end

