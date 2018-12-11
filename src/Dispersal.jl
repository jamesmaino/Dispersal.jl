"""
This package extends [Cellular.jl](https://github.com/rafaqz/Cellular.jl)

[Dispersal.jl](https://github.com/rafaqz/Dispersal.jl) provides a range of
dispersal modules that can be combined to build grid-based organism dispersal simulations.

The design provides a solid framework while allowing customisation of any
aspect. A model may start with the defaults and formulations provided,
but incrementally customise them for a particular use-case, to any level of detail.

Additionally, modules, outputs, neighborhoods provided by Cellular.jl or other
packages that extend it may be incorporated into a simulaiton.
"""
module Dispersal

using Cellular,
      DocStringExtensions,
      LinearAlgebra,
      Parameters,
      Mixers,
      Flatten,
      Requires,
      FieldMetadata,
      Distributions

import Cellular: rule, rule!, neighbors, inbounds, radius
import Base: getindex, setindex!, lastindex, size, length, push!
import Flatten: flattenable
import FieldMetadata: @description, @limits, description, limits

# Documentation templates
@template TYPES =
    """
    $(TYPEDEF)
    $(FIELDS)
    """

include("types.jl")
include("layers.jl")
include("utils.jl")
include("local/common.jl")
include("local/inwards.jl")
include("local/outwards.jl")
include("growth.jl")
include("human.jl")
include("jump.jl")
include("allee.jl")

export AbstractDispersal,
       AbstractInwardsDispersal,
       InwardsBinaryDispersal,
       InwardsPopulationDispersal,
       AbstractOutwardsDispersal,
       OutwardsBinaryDispersal,
       OutwardsPopulationDispersal,
       HudginsDispersal,
       AbstractJumpDispersal,
       JumpDispersal,
       AbstractHumanDispersal,
       HumanDispersal,
       EulerExponentialGrowth,
       EulerLogisticGrowth,
       ExactExponentialGrowth,
       ExactLogisticGrowth,
       AlleeExtinction,
       SuitabilityMask,
       SuitabilityEulerExponentialGrowth,
       SuitabilityEulerLogisticGrowth,
       SuitabilityExactExponentialGrowth,
       SuitabilityExactLogisticGrowth,
       AbstractDispersalKernel,
       DispersalKernel,
       DispersalGrid,
       Layer,
       Sequence,
       exponential

function __init__()
    @require CuArrays="3a865a2d-5b23-5a0f-bc46-62713ec82fae" begin
        include("cuda.jl")
    end
end



end # module
