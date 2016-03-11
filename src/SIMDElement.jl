# Represents a SIMD Element which is a small collection of numbers which
# should fit in a register and thus support SIMD instructions
typealias SIMDElement{N, T} NTuple{N, VecElement{T}}

function vectupexpr(f,N)
    ex = Expr(:tuple, [f(i) for i=1:N]...)
    return quote
        $ex
    end
end

@generated function Base.(:+){N}(a::SIMDElement{N}, b::SIMDElement{N})
    return vectupexpr(i -> :(VecElement(a[$i].value + b[$i].value)), N)
end

@generated function Base.(:-){N}(a::SIMDElement{N}, b::SIMDElement{N})
    return vectupexpr(i -> :(VecElement(a[$i].value - b[$i].value)), N)
end

@generated function Base.(:.*){N}(a::SIMDElement{N}, b::SIMDElement{N})
    return vectupexpr(i -> :(VecElement(a[$i].value * b[$i].value)), N)
end

@generated function Base.(:./){N}(a::SIMDElement{N}, b::SIMDElement{N})
    return vectupexpr(i -> :(VecElement(a[$i].value / b[$i].value)), N)
end

@generated function Base.(:/){N}(a::SIMDElement{N}, n::Number)
    return vectupexpr(i -> :(VecElement(a[$i].value / n)), N)
end

@generated function Base.(:*){N}(a::SIMDElement{N}, n::Number)
    return vectupexpr(i -> :(VecElement(a[$i].value * n)), N)
end

Base.(:*){N}(n::Number, a::SIMDElement{N}) = a * n

@generated function Base.(:-){N}(a::SIMDElement{N})
    return vectupexpr(i -> :(VecElement(-a[$i].value)), N)
end
