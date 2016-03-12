module SIMDVectors

import Base.Operators: +, *, .*, ./, -, /, .^


export SIMDVector, VecRegister, load

include("tuple_ops.jl")
include("VecRegister.jl")
include("SIMDVector.jl")
include("conversion_promotion.jl")

end # module
