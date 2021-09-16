"""
	MaxOutputs()

A model attribute a solver should use the specify the maximum number of scalar-valued 
outputs it can handle in multiobjective optimization.
`MOI.get( model, MaxOutputs )` defaults to 1 and should be overwritten by multiobjective 
solvers.
"""
struct MaxOutputs <: MOI.AbstractModelAttribute end	
MOI.attribute_value_type( ::MaxOutputs ) = Int64

"""
    NumberOfObjectives()
A model attribute for the number of objective functions in the model.
As each objective function might have multiple outputs use `NumberOfOutputs()` to get the total number of scalar-valued outputs.
"""
struct NumberOfObjectives <: MOI.AbstractModelAttribute end
MOI.attribute_value_type( ::NumberOfObjectives ) = Int64

"""
	NumberOfOutputs()

A model attribute for the number of scalar-valued objectives in the model.

If, e.g., the model describes a multiobjective optimization problem and there
are two objective functions, the first one being scalar-valued and the second 
returning a vector with 2 entries, then the NumberOfOutputs is 3.
"""
struct NumberOfOutputs <: MOI.AbstractModelAttribute end
MOI.attribute_value_type( ::NumberOfOutputs ) = Int64

"""
	ListOfObjectiveIndices()

A model attribute for the `Vector{ObjectiveIndex}` of all objective indices present in the model
(i.e., of length equal to the value of `NumberOfObjectives()`) in the order in
which they were added.
"""
struct ListOfObjectiveIndices <: MOI.AbstractModelAttribute end

"""
    ObjectiveValue(result_index::Int = 1, objective_index = nothing)
A model attribute for the objective value of the primal solution `result_index`.
See [`ResultCount`](@ref) for information on how the results are ordered.

If `objective_index` is an `ObjectiveIndex` then the value(s) of that objective
are concatenated and returned. If `objective_index` is `nothing` then the values of all objectives
are returned.
"""
struct ObjectiveValue{T<:Union{ObjectiveIndex,Nothing}} <: MOI.AbstractModelAttribute
    result_index::Int
	objective_index::T 
    function ObjectiveValue(result_index::Int = 1, objective_index::Nothing=nothing)
		return new{Nothing}(result_index, objective_index)
	end
end

"""
    AbstractObjectiveAttribute
Abstract supertype for attribute objects that can be used to set or get attributes (properties) of objective functions in the model.
"""
abstract type AbstractObjectiveAttribute end

# NOTE: all the attributes below are `AbstractModelAttribute`s in MOI
# I want them to be `AbstractObjectiveAttribute`s instead.

"$(Docs.doc(MOI.ObjectiveSense()))"
struct ObjectiveSense <: AbstractObjectiveAttribute end
MOI.attribute_value_type(::ObjectiveSense) = MOI.OptimizationSense

"""
    ObjectiveFunction{F<:Union{AbstractScalarFunction, AbstractVectorFunction}}()
A model attribute for the objective function which has a type `F`.
`F` should be guaranteed to be equivalent but not necessarily identical to the function type provided by the user.
Throws an `InexactError` if the objective function cannot be converted to `F`,
e.g. the objective function is quadratic and `F` is `ScalarAffineFunction{Float64}` or
it has non-integer coefficient and `F` is `ScalarAffineFunction{Int}`.
"""
struct ObjectiveFunction{F<:MOI.AbstractFunction} <: AbstractObjectiveAttribute end
MOI.attribute_value_type(::ObjectiveFunction{F}) where {F} = F

"""
    ObjectiveFunctionType()
A model attribute for the type `F` of the objective function set using the
`ObjectiveFunction{F}` attribute.

## Examples
In the following code, `attr` should be equal to `MOI.VariableIndex`:
```julia
x = MOI.add_variable(model)
objf_1 = MOI.add_objective(model, x)
attr = MOI.get(model, MOI.ObjectiveFunctionType(), objf_1)
```
"""
struct ObjectiveFunctionType <: AbstractObjectiveAttribute end
MOI.attribute_value_type(::ObjectiveFunctionType) = Type{<:MOI.AbstractFunction}

struct NumberOfObjectiveOutputs <: AbstractObjectiveAttribute end
MOI.attribute_value_type(::NumberOfObjectiveOutputs) = Int64