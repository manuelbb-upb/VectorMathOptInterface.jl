# this is copied and adapted from `constraints.jl`
"""
    supports_objective( model::ModelLike, 
		::Type{F})::Bool where {F<MOI.AbstractFunction}

Return a `Bool` indicating whether `model` generally supports adding an objective 
of type `F`.
That is, `copy_to(model, src)` does not throw [`UnsupportedObjective`](@ref) when
`src` contains objectives of type `F`.
"""
function MOI.supports_constraint(
    ::MOI.ModelLike,
    ::Type{<:MOI.AbstractFunction}
)
    return false
end

"""
    struct UnsupportedObjective{F<:MOI.AbstractFunction}
        message::String # Human-friendly explanation why the attribute cannot be set
    end

	An error indicating that objectives of type `F` are not supported by
the model, i.e. that [`supports_constraint`](@ref) returns `false`.
"""
struct UnsupportedObjective{F<:MOI.AbstractFunction} <: MOI.UnsupportedError
    message::String # Human-friendly explanation why the attribute cannot be set
end
UnsupportedObjective{F}() where F = UnsupportedObjective{F}("")


function MOI.element_name(::UnsupportedObjective{F}) where {F}
    return "`$F` objective"
end

"""
    struct AddObjectiveNotAllowed{F<:AbstractFunction} <: NotAllowedError
        message::String # Human-friendly explanation why the attribute cannot be set
    end
An error indicating that objectives of type `F` are supported (see
[`supports_constraint`](@ref)) but cannot be added.
"""
struct AddObjectiveNotAllowed{F<:MOI.AbstractFunction} <:
       MOI.NotAllowedError
    message::String # Human-friendly explanation why the attribute cannot be set
end
AddObjectiveNotAllowed{F}() where {F} = AddConstraintNotAllowed{F}("")

function MOI.operation_name(::AddObjectiveNotAllowed{F}) where F
    return "Adding `$F` objectives."
end

# This should be implemented by multiobjective solvers, i.e., if 
# `get( model, NumberOfObjectiveOutputs ) > 1`
# currently, it falls back to the old way of adding a single objective
function add_objective( model :: MOI.ModelLike, objf :: F ) where {F<:MOI.AbstractFunction}
	# this is a fallback to the old behavior:
	MOI.set( model, MOI.ObjectiveFunction{F}(), objf )
	
	# do some smart error handling as in src/constraints.jl
	return ObjectiveIndex{F}(1)
end

function add_objectives( model :: MOI.ModelLike, objfs :: Vector{<:MOI.AbstractFunction} )
	return add_objective.( model, ois, objfs )
end

# Default attributes

# overwrite this for a multi-objective solver:
MOI.get(model::MOI.ModelLike, ::MaxOutputs) = 1
MOI.get(model::MOI.ModelLike, ::NumberOfObjectives) = 1
MOI.get(model::MOI.ModelLike, ::NumberOfObjectiveOutputs) = 1

# default fallback to get number of outputs of a single objective
# using `output_dimension` which is provided for all MOI functions
function MOI.get( model :: MOI.ModelLike, :: NumberOfObjectiveOutputs, oi :: ObjectiveIndex)
	objf_fun = MOI.get( model, ObjectiveFunction(), oi )
	return MOI.output_dimension( objf_fun )
end

# default fallback to get number of outputs
function MOI.get( model :: MOI.ModelLike, :: NumberOfOutputs, oi :: ObjectiveIndex )
	if MOI.supports( model, ListOfObjectiveIndices() )
		output_counter = 0
		for oi in MOI.get( model, ListOfObjectiveIndices() )
			objf_fun = MOI.get( model, oi )
			output_counter += MOI.get( model, NumberOfObjectiveOutputs(), objf_fun )
		end
		return output_counter
	else
		throw(MOI.UnsupportedAttribute( NumberOfOutputs(), 
				"Cannot determine number of outputs because `ListOfObjectivesIndices` is not supported."))
	end		
end

# TODO `transform`