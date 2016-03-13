@generated function Base.promote_rule{M1, N1, R1, T1, M2, N2, R2, T2}(::Type{SIMDVector{M1, N1, R1, T1}},
                                                                      ::Type{SIMDVector{M2, N2, R2, T2}})
    Tr = promote_type(T1, T2)

    simd_len, rest, buckets = compute_lengths(M1*N1 + R1, Tr)
    return quote
        $(Expr(:meta, :inline))
        SIMDVector{$buckets, $simd_len, $rest, $Tr}
    end
end

function generate_conversion_expr(simd_len, N, rest, T)
    simd_array_create_expr = Expr(:tuple)
    if simd_len != 0
        for i in 1:simd_len:N-rest
            exp_simd_ele = Expr(:call, :VecRegister)
            push!(exp_simd_ele.args, Expr(:tuple, [:(VecElement(convert($T, v[$j]))) for j in i:simd_len+i-1]...))
            push!(simd_array_create_expr.args, exp_simd_ele)
        end
    end

    rest_array_create_expr = Expr(:tuple, [:(convert($T, v[$j])) for j in (N-rest+1):N]...)

    return simd_array_create_expr, rest_array_create_expr
end

# Identity conversion
@inline Base.convert{M, N, R, T}(::Type{SIMDVector{M, N, R, T}}, vec::SIMDVector{M, N, R, T}) = vec

@generated function Base.convert{M1, N1, R1, T1, M2, N2, R2, T2}(::Type{SIMDVector{M1, N1, R1, T1}},
                                                                 v::SIMDVector{M2, N2, R2, T2})
    Tr = promote_type(T1, T2)
    simd_len, rest, buckets = compute_lengths(M1*N1 + R1, Tr)

    simd_array_create_expr, rest_array_create_expr = generate_conversion_expr(simd_len, M1*N1 + R1, rest, Tr)
    return quote
        $(Expr(:meta, :inline))
        @assert M1 * N1 + R1 == M2 * N2 + R2
        @inbounds simd_tup =  $simd_array_create_expr
        @inbounds rest = $rest_array_create_expr
        SIMDVector{$buckets, $simd_len, $rest, $Tr}(simd_tup, rest)
    end
end

@generated function promote_eltype{M, N, R, T1, T2}(::Type{SIMDVector{M, N, R, T1}},
                                                    n::T2)
    Tr = promote_type(T1, T2)
    simd_len, rest, buckets = compute_lengths(M1*N1 + R1, Tr)

    simd_array_create_expr, rest_array_create_expr = generate_conversion_expr(simd_len, M1*N1 + R1, rest, Tr)
    return quote
        $(Expr(:meta, :inline))
        @inbounds simd_tup =  $simd_array_create_expr
        @inbounds rest = $rest_array_create_expr
        SIMDVector{$buckets, $simd_len, $rest, $Tr}(simd_tup, rest)
    end
end
