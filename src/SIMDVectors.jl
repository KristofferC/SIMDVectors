module SIMDVectors

export SIMDVector, SIMDElement, load

include("tuple_ops.jl")
include("SIMDElement.jl")
include("SIMDVector.jl")

end # module
