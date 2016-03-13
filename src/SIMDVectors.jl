module SIMDVectors

importall Base

export SIMDVector, load, store!

const VEC_REGISTER_SIZE_BITS = 128

const VECTOR_DATATYPES = Set{DataType}(
	 (Bool,
	  Int8,Int16, Int32, Int64, Int128,
	  UInt8, UInt16, UInt32, UInt64, UInt128,
	  Float16, Float32, Float64))

# List taken from FixedSizeArrays.jl
const UNARY_FUNCS = (:-, :~, :conj, :abs,
                  :sin, :cos, :tan, :sinh, :cosh, :tanh,
                  :asin, :acos, :atan, :asinh, :acosh, :atanh,
                  :sec, :csc, :cot, :asec, :acsc, :acot,
                  :sech, :csch, :coth, :asech, :acsch, :acoth,
                  :sinc, :cosc, :cosd, :cotd, :cscd, :secd,
                  :sind, :tand, :acosd, :acotd, :acscd, :asecd,
                  :asind, :atand, :rad2deg, :deg2rad,
                  :log, :log2, :log10, :log1p, :exponent, :exp,
                  :exp2, :expm1, :cbrt, :sqrt, :erf,
                  :erfc, :erfcx, :erfi, :dawson, :ceil, :floor,
                  :trunc, :round, :significand, :lgamma,
                  :gamma, :lfact, :airy, :airyai,
                  :airyprime, :airyaiprime, :airybi, :airybiprime,
                  :besselj0, :besselj1, :bessely0, :bessely1,
                  :eta, :zeta, :digamma)

const BINARY_FUNCS  = (:.+, :.-,:.*, :./, :.\, :.^,
                   :.==, :.!=, :.<, :.<=, :.>, :.>=, :+, :-,
                   :min, :max,
                   :div, :fld, :rem, :mod, :mod1,
                   :atan2, :besselj, :bessely, :hankelh1, :hankelh2,
                   :besseli, :besselk, :beta, :lbeta)

const REDUCTION_FUNCS = ((:maximum, :max),
                         (:minimum,  :min),
                         (:sum, :.+),
                         (:prod, :.*))

include("tuple_ops.jl")
include("VecRegister.jl")
include("SIMDVector.jl")
include("conversion_promotion.jl")

end # module
