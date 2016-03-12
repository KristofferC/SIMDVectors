# Represents a SIMD Element which is a small collection of numbers which
# should fit in a register and thus support SIMD instructions
typealias SIMDElement{N, T} NTuple{N, VecElement{T}}

function vectupexpr(f,N)
    ex = Expr(:tuple, [f(i) for i=1:N]...)
    return quote
        $ex
    end
end

for oper in (:+, :-, :.*, :./)
    @eval begin
        @generated function $(oper){N}(a::SIMDElement{N}, b::SIMDElement{N})
            return vectupexpr(i -> :(VecElement( ($($oper))(a[$i].value, b[$i].value)), N)
            end
        end
    end
end

#@generated function Base.(:+){N}(a::SIMDElement{N}, b::SIMDElement{N})
#    return vectupexpr(i -> :(VecElement(a[$i].value + b[$i].value)), N)
#end
#
#@generated function Base.(:-){N}(a::SIMDElement{N}, b::SIMDElement{N})
#    return vectupexpr(i -> :(VecElement(a[$i].value - b[$i].value)), N)
#end
#
#@generated function Base.(:.*){N}(a::SIMDElement{N}, b::SIMDElement{N})
#    return vectupexpr(i -> :(VecElement(a[$i].value * b[$i].value)), N)
#end

@generated function Base.(:./){N}(a::SIMDElement{N}, b::SIMDElement{N})
    return vectupexpr(i -> :(VecElement(a[$i].value / b[$i].value)), N)
end

# "Symmetric" Binary operators between number and SIMDElement
for oper in (:+, :*,)
    @eval begin
        @generated function $(oper){N}(a::SIMDElement{N}, b::Number)
            return vectupexpr(i -> :(VecElement( ($($oper))(a[$i].value, b)), N)
        end

        $(oper){N}(b::Number, a::SIMDElement{N}) = $(oper)(a, b)
    end
end

# Binary operators between number and SIMDElement
for oper in (:/, :.^, :-)
    @eval begin
        @generated function $(oper){N}(a::SIMDElement{N}, b::Number)
            return vectupexpr(i -> :(VecElement( ($($oper))(a[$i].value, b)), N)
        end
    end
end



#@generated function Base.(:/){N}(a::SIMDElement{N}, n::Number)
#    return vectupexpr(i -> :(VecElement(a[$i].value / n)), N)
#end

#@generated function Base.(:*){N}(a::SIMDElement{N}, n::Number)
#    return vectupexpr(i -> :(VecElement(a[$i].value * n)), N)
#end

#Base.(:*){N}(n::Number, a::SIMDElement{N}) = a * n

@generated function Base.(:-){N}(a::SIMDElement{N})
    return vectupexpr(i -> :(VecElement(-a[$i].value)), N)
end

@generated function Base.zero{N,T}(::Type{SIMDElement{N,T}})
    result = vectupexpr(i -> :(VecElement(z)), N)
    return quote
        z = zero($T)
        return $result
    end
end

@generated function Base.one{N,T}(::Type{SIMDElement{N,T}})
    result = vectupexpr(i -> :(VecElement(z)), N)
    return quote
        z = one($T)
        return $result
    end
end

@generated function Base.rand{N, T}(::Type{SIMDElement{N,T}})
    return vectupexpr(i -> :(VecElement(rand(T))), N)
end


# Elementwise unary functions
for f in (:sin, :cos, :exp)
    @eval begin
        @generated function Base.$(f){N}(a::SIMDElement{N}, n::Number)
            return vectupexpr(i -> :(VecElement($($f)(a[$i].value)), N)
        end
    end
end
