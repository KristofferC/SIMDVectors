# (C) Jarett Revels ForwardDiff.jl, License MIT
function tupexpr(f,N)
    ex = Expr(:tuple, [f(i) for i=1:N]...)
    return quote
        $(Expr(:meta, :inline))
        @inbounds return $ex
    end
end

@generated function scale_tuple{N}(tup::NTuple{N}, x)
    return  quote
        $(Expr(:meta, :inline))
        $(tupexpr(i -> :(tup[$i] * x), N))
    end
end

@generated function div_tuple_by_scalar{N}(tup::NTuple{N}, x)
    return quote
        $(Expr(:meta, :inline))
        $tupexpr(i -> :(tup[$i]/x), N)
    end
end

@generated function minus_tuple{N}(tup::NTuple{N})
    return quote
        $(Expr(:meta, :inline))
        $(tupexpr(i -> :(-tup[$i]), N))
    end
end

@generated function subtract_tuples{N}(a::NTuple{N}, b::NTuple{N})
    return quote
        $(Expr(:meta, :inline))
        $(tupexpr(i -> :(a[$i]-b[$i]), N))
    end
end

@generated function add_tuples{N}(a::NTuple{N}, b::NTuple{N})
    return quote
        $(Expr(:meta, :inline))
        $(tupexpr(i -> :(a[$i]+b[$i]), N))
    end
end

@generated function mul_tuples{N}(a::NTuple{N}, b::NTuple{N})
    return quote
        $(Expr(:meta, :inline))
        $(tupexpr(i -> :(a[$i]*b[$i]), N))
    end
end

@generated function div_tuples{N}(a::NTuple{N}, b::NTuple{N})
    return quote
        $(Expr(:meta, :inline))
        $(tupexpr(i -> :(a[$i]/b[$i]), N))
    end
end