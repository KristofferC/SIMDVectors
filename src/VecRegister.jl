# Represents a vector register
immutable VecRegister{N, T}
    data::NTuple{N, VecElement{T}}
end

function Base.getindex(vec_reg::VecRegister, i)
    @inbounds v = vec_reg.data[i].value
    return v
end

function vectupexpr(f,N)
    ex = Expr(:tuple, [f(i) for i=1:N]...)
    return quote
        $ex
    end
end

# Elementwise unary functions
for f in UNARY_FUNCS
    @eval begin
        @generated function Base.$(f){N}(a::VecRegister{N})
            expr = vectupexpr(i -> :(VecElement($($f)(a[$i]))), N)
            return quote
                $(Expr(:meta, :inline))
                VecRegister($expr)
            end
        end
    end
end

# Binary func between VecRegister, VecRegister and
# Number, VecRegister.
for f in BINARY_FUNCS
    @eval begin
        @generated function $(f){N}(a::VecRegister{N}, b::VecRegister{N})
            expr = vectupexpr(i -> :(VecElement( ($($f))(a[$i], b[$i]))), N)
            return quote
            $(Expr(:meta, :inline))
            VecRegister($expr)
            end
        end

        @generated function $(f){N}(a::VecRegister{N}, b::Number)
            expr = vectupexpr(i -> :(VecElement( ($($f))(a[$i], b))), N)
            return quote
            $(Expr(:meta, :inline))
            VecRegister($expr)
            end
        end

        @generated function $(f){N}(b::Number, a::VecRegister{N})
            expr = vectupexpr(i -> :(VecElement( ($($f))(b, a[$i]))), N)
            return quote
            $(Expr(:meta, :inline))
            VecRegister($expr)
            end
        end
    end
end

function recursive_reduction_expr!(expr, i, N, f)
    if i == 2
        return expr
    else
        return Expr(:call, f, recursive_reduction_expr!(expr, i-1, N, f), :(a[$(i)]))
    end
end

for (f, f_scal) in REDUCTION_FUNCS
    @eval begin
        @generated function $(f){N}(a::VecRegister{N})
            if N == 0
                return quote end
            elseif N == 1
                return quote a[1] end
            else
                expr = Expr(:call, $f_scal, :(a[1]), :(a[2]))
                full_red_expr = recursive_reduction_expr!(expr, N, N, $f_scal)
                return quote
                    $(Expr(:meta, :inline))
                    $full_red_expr
                end
            end
        end
    end
end

@generated function Base.zero{N,T}(::Type{VecRegister{N,T}})
    result = vectupexpr(i -> :(VecElement(z)), N)
    return quote
        $(Expr(:meta, :inline))
        z = zero($T)
        VecRegister($result)
    end
end

@generated function Base.one{N,T}(::Type{VecRegister{N,T}})
    result = vectupexpr(i -> :(VecElement(z)), N)
    return quote
        $(Expr(:meta, :inline))
        z = one($T)
        return quote VecRegister($result) end
    end
end

@generated function Base.rand{N, T}(::Type{VecRegister{N,T}})
    expr = vectupexpr(i -> :(VecElement(rand(T))), N)
    return quote
        $(Expr(:meta, :inline))
        VecRegister($result)
    end
end
