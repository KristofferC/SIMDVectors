# Represents a SIMD Element which is a small collection of numbers which
# should fit in a register and thus support SIMD instructions
immutable VecRegister{N, T}
    data::NTuple{N, VecElement{T}}
end

function Base.getindex(avx::VecRegister, i)
    @inbounds v = avx.data[i].value
    return v
end


#typealias VecRegister{N, T} NTuple{N, VecElement{T}}

function vectupexpr(f,N)
    ex = Expr(:tuple, [f(i) for i=1:N]...)
    return quote
        $ex
    end
end

for oper in (:+, :-, :.*, :./)
    @eval begin
        @generated function $(oper){N}(a::VecRegister{N}, b::VecRegister{N})
            expr = vectupexpr(i -> :(VecElement( ($($oper))(a[$i], b[$i]))), N)
            return quote
            $(Expr(:meta, :inline))
            VecRegister($expr)
            end
        end
    end
end

@generated function Base.(:./){N}(a::VecRegister{N}, b::VecRegister{N})
    expr = vectupexpr(i -> :(VecElement(a[$i] / b[$i])), N)
    return quote
        $(Expr(:meta, :inline))
        VecRegister($expr)
    end
end

# "Symmetric" Binary operators between number and VecRegister
for oper in (:+, :*,)
    @eval begin
        @generated function $(oper){N}(a::VecRegister{N}, b::Number)
            expr = vectupexpr(i -> :(VecElement( ($($oper))(a[$i], b))), N)
            return quote
                $(Expr(:meta, :inline))
                VecRegister($expr)
            end
        end

        $(oper){N}(b::Number, a::VecRegister{N}) = $(oper)(a, b)
    end
end

# Binary operators between number and VecRegister
for oper in (:/, :.^, :-)
    @eval begin
        @generated function $(oper){N}(a::VecRegister{N}, b::Number)
            expr = vectupexpr(i -> :(VecElement( ($($oper))(a[$i], b))), N)
            return quote
                $(Expr(:meta, :inline))
                VecRegister($expr)
            end
        end
    end
end



#@generated function Base.(:/){N}(a::VecRegister{N}, n::Number)
#    return vectupexpr(i -> :(VecElement(a[$i].value / n)), N)
#end

#@generated function Base.(:*){N}(a::VecRegister{N}, n::Number)
#    return vectupexpr(i -> :(VecElement(a[$i].value * n)), N)
#end

#Base.(:*){N}(n::Number, a::VecRegister{N}) = a * n

@generated function Base.(:-){N}(a::VecRegister{N})
    expr = vectupexpr(i -> :(VecElement(-a[$i])), N)
    return quote
        $(Expr(:meta, :inline))
        VecRegister($expr)
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


# Elementwise unary functions
for f in (:sin, :cos, :exp)
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
