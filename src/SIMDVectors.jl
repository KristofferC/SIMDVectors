module SIMDVectors

export SIMDVector, SIMDElement, load

include("tuple_ops.jl")
include("SIMDElement.jl")
include("SIMDVector.jl")
include("conversion_promotion.jl")

end # module
