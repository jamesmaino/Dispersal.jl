# Mixins

@premix @columns struct InstrinsicGrowthRate{GR}
    intrinsicrate::GR = 0.1 | true  | (0.0, 10.0)
end

@premix @columns struct CarryCap{CC}
    carrycap::CC = 100000   | false  | (0.0, 1000000.0)
end

@premix @columns struct Layers{L}
    layers::L    = ()       | false | _
end


# Type declarations

""" 
Extends AbstractCellModel for models of growth dynamics 

For best performance these should be chained into submodels with 
other AbstractCellModel or following an AbstractNeighborhoodModel.
"""
abstract type AbstractGrowthModel <: AbstractCellModel end


# Euler method solvers

" Simple fixed exponential growth rate solved with Euler method "
@InstrinsicGrowthRate struct EulerExponentialGrowth{} <: AbstractGrowthModel end

" Simple fixed logistic growth rate solved with Euler method "
@CarryCap @InstrinsicGrowthRate struct EulerLogisticGrowth{} <: AbstractGrowthModel end

" Exponential growth based on a suitability layer solved with Euler method "
@Layers struct SuitabilityEulerExponentialGrowth{} <: AbstractGrowthModel end

" Logistic growth based on a suitability layer solved with Euler method "
@CarryCap @Layers struct SuitabilityEulerLogisticGrowth{} <: AbstractGrowthModel end


# Exact growth solutions

" Simple fixed exponential growth rate using exact solution "
@InstrinsicGrowthRate struct ExactExponentialGrowth{} <: AbstractGrowthModel end

" Simple fixed logistic growth rate using exact solution "
@CarryCap @InstrinsicGrowthRate struct ExactLogisticGrowth{} <: AbstractGrowthModel end

" Exponential growth based on a suitability layer using exact solution "
@Layers struct SuitabilityExactExponentialGrowth{} <: AbstractGrowthModel end

" Logistic growth based on a suitability layer using exact solution "
@CarryCap @Layers struct SuitabilityExactLogisticGrowth{} <: AbstractGrowthModel end

" Simple suitability layer mask "
@Layers struct SuitabilityMask{ST} <: AbstractGrowthModel
    # "Minimum habitat suitability index."
    threshold::ST = 0.7 | true  | (0.0, 1.0)
end


# Rules 

# Euler solver rules
@inline rule(model::EulerExponentialGrowth, data, state, args...) = state + state * model.intrinsicrate * data.timestep

@inline rule(model::SuitabilityEulerExponentialGrowth, data, state, index, args...) = begin
    state == zero(state) && return state
    intrinsicrate = get_layers(model, data, index)
    state + intrinsicrate * state * data.timestep # dN = rN * dT
    # max(min(state * intrinsicrate, model.max), model.min)
end

# TODO: fix and test logistic growth
@inline rule(model::EulerLogisticGrowth, data, state, args...) =
    state + state * model.intrinsicrate * (oneunit(state) - state / model.carrycap) * data.timestep # dN = (1-N/K)rN dT

@inline rule(model::SuitabilityEulerLogisticGrowth, data, state, index, args...) = begin
    state == zero(state) && return state
    intrinsicrate = get_layers(model, data, index)
    saturation = intrinsicrate > zero(intrinsicrate) ? (oneunit(state) - state / model.carrycap) : oneunit(state)
    state + state * saturation * intrinsicrate * data.timestep
end


# Exact solution rules

@inline rule(model::ExactExponentialGrowth, data, state, args...) = state * exp(model.intrinsicrate * data.timestep)

@inline rule(model::SuitabilityExactExponentialGrowth, data, state, index, args...) = begin
    state == zero(state) && return state
    intrinsicrate = get_layers(model, data, index)
    state * exp(intrinsicrate * data.timestep)
    # max(min(state * intrinsicrate, model.max), model.min)
end

@inline rule(model::ExactLogisticGrowth, data, state, args...) =
    (state * model.carrycap) /
    (state + (model.carrycap - state) * exp(-model.intrinsicrate * data.timestep))

@inline rule(model::SuitabilityExactLogisticGrowth, data, state, index, args...) = begin
    state == zero(state) && return state
    intrinsicrate = get_layers(model, data, index)
    # Saturation only applies with positive growth
    if intrinsicrate > zero(intrinsicrate)
        (state * model.carrycap) /
        (state + (model.carrycap - state) * exp(-intrinsicrate * data.timestep))
    else
        state * exp(intrinsicrate * data.timestep)
    end
end

@inline rule(model::SuitabilityMask, data, state, index, args...) = begin
    state == zero(state) && return zero(state)
    get_layers(model, data, index) >= model.threshold ? state : zero(state)
end
