# (C) Jarett Revels ForwardDiff.jl, License MIT
function tupexpr(f,N)
    ex = Expr(:tuple, [f(i) for i=1:N]...)
    return quote
        $(Expr(:meta, :inline))
        @inbounds return $ex
    end
end

@inline zero_tuple(::Type{Tuple{}}) = tuple()

@generated function zero_tuple{N,T}(::Type{NTuple{N,T}})
    result = tupexpr(i -> :z, N)
    return quote
        $(Expr(:meta, :inline))
        z = zero($T)
        return $result
    end
end

@generated function one_tuple{N,T}(::Type{NTuple{N,T}})
    result = tupexpr(i -> :z, N)
    return quote
        $(Expr(:meta, :inline))
        z = one($T)
        return $result
    end
end

@inline rand_tuple(::Type{Tuple{}}) = tuple()

@generated function rand_tuple{N,T}(::Type{NTuple{N,T}})
    return tupexpr(i -> :(rand($T)), N)
end

for f in UNARY_FUNCS
    tuple_f_string = symbol(string(f) * "_tuple")
    @eval begin
        @generated function $(tuple_f_string){N}(a::NTuple{N})
            return quote
                $(Expr(:meta, :inline))
                $(tupexpr(i -> :($($f)(a[$i])), N))
            end
        end
    end
end

for f in BINARY_FUNCS
    tuple_f_string = symbol(string(f) * "_tuple")
    @eval begin
        @generated function $(tuple_f_string){N}(a::NTuple{N}, b::NTuple{N})
            return quote
            $(Expr(:meta, :inline))
            $(tupexpr(i -> :($($f)(a[$i], b[$i])), N))
            end
        end

        @generated function $(tuple_f_string){N}(a::NTuple{N}, b::Number)
            return quote
                $(Expr(:meta, :inline))
                $(tupexpr(i -> :($($f)(a[$i], b)), N))
            end
        end

        @generated function $(tuple_f_string){N}(b::Number, a::NTuple{N})
            return quote
                $(Expr(:meta, :inline))
                $(tupexpr(i -> :($($f)(b, a[$i])), N))
            end
        end
    end
end
