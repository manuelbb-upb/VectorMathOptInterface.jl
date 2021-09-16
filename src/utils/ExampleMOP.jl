module ExampleMOP
import ..VectorMathOptInterface
MOI = VectorMathOptInterface

export MOP

Base.@kwdef struct MOP <: MOI.ModelLike
	name :: String = ""

	variables :: Vector{MOI.VariableIndex} = []
	
	lower_bounds :: Dict{ MOI.ConstraintIndex{MOI.VariableIndex, MOI.GreaterThan}, MOI.GreaterThan} = Dict()
	
	upper_bounds :: Dict{ MOI.ConstraintIndex{MOI.VariableIndex, MOI.LessThan}, MOI.LessThan} = Dict()
	
	scalar_affine_lt_constraints :: Dict{MOI.ConstraintIndex, Tuple{MOI.ScalarAffineFunction, MOI.LessThan}} = Dict()
end

function MOI.is_empty( mop :: MOP )
	_is_empty = true
	for fn in [:variables, :lower_bounds, :upper_bounds, :scalar_affine_eq_constraints]
		_is_empty &= isempty( getfield(mop, fn ))
	end
	return _is_empty
end

function MOI.empty!( mop :: MOP )
	for fn in [:variables, :lower_bounds, :upper_bounds, :scalar_affine_eq_constraints]
		isempty!( getfield(mop, fn ))
	end
	return nothing
end

MOI.supports_incremental_interface( :: MOP ) = true

MOI.supports( ::MOP, ::MOI.Name ) = true 
MOI.get(mop::MOP, ::MOI.Name ) = mop.name
function MOI.set( mop :: MOP, ::MOI.Name, new_name)
	mop.name = new_name
end

function rand_scalar_affine_func( vars )
	n_vars = length(vars)
	coeff = rand(n_vars)
	terms = [ MOI.ScalarAffineTerm( c, x ) for (c,x) in zip( coeff, vars ) ]
	return MOI.ScalarAffineFunction( terms, rand() )
end

# VARIABLES 
next_id( V ) = isempty( V ) ? 1 : maximum( v.value for v in V )
function MOI.add_variable( mop :: MOP )
	new_var_id = next_id( mop.variables )
	new_var = MOI.VariableIndex(new_var_id)
	push!(mop.variables, new_var )
	return new_var
end	
function MOI.delete( mop :: MOP, vi :: MOI.VariableIndex )
	vi_pos = findfirst( isequal(vi), mop.variables )
	if !isnothing(vi_pos)
		deleteat!(mop.variables, vi_pos)
	end
	return nothing
end
function MOI.is_valid( mop :: MOP, vi :: MOI.VariableIndex )
	return vi in mop.variables
end
	
MOI.get( mop :: MOP, :: MOI.NumberOfVariables ) = length( mop.variables )
MOI.get( mop :: MOP, :: MOI.ListOfVariableIndices ) = mop.variables
MOI.get( mop :: MOP, :: MOI.ListOfVariableAttributesSet ) = MOI.AbstractVariableAttribute[]

#%% BOUND CONSTRAINTS 
const LB_CI = MOI.ConstraintIndex{ MOI.VariableIndex, MOI.GreaterThan } 
const UB_CI = MOI.ConstraintIndex{ MOI.VariableIndex, MOI.LessThan } 

for (T, bound_type) in zip( [ LB_CI, UB_CI ], ["lower_bounds", "upper_bounds"])
	@eval begin 
	
		S = $(T).parameters[2]
		err = $T == LB_CI ? MOI.LowerBoundAlreadySet : MOI.UpperBoundAlreadySet
		fn = Symbol($bound_type)

		MOI.supports_constraint( ::MOP, ::Type{<:MOI.VariableIndex}, ::Type{<:S} ) = true
		
		function MOI.add_constraint( mop :: MOP, vi :: MOI.VariableIndex, b :: S )
			for con in keys( getfield( mop, fn ) )
				if vi.value == con.value
					throw(err)
				end
			end
			
			if MOI.is_valid( mop, vi )
				next_const = T( vi.value )
				mop.lower_bounds[ next_const ] = b
				
				return next_const
			else
				throw( MOI.InvalidIndex(vi) )
			end
		end

		function MOI.delete( mop :: MOP, ci :: $T )
			delete!( getfield(mop, fn), ci )
			return nothing
		end

		function MOI.is_valid( mop :: MOP, ci :: $T )
			return ci in keys( getfield(mop, fn) )
		end

	end
end

# Scalar, Affine Linear LT constraints

function _list_of_all_vars( f :: MOI.ScalarAffineFunction )
	return [ term.variable for term in f.terms ]
end

function MOI.supports_constraint( ::MOP, 
	::Type{<:MOI.ScalarAffineFunction}, ::Type{<:MOI.LessThan})
	return true 
end

function MOI.add_constraint( mop :: MOP, func :: MOI.ScalarAffineFunction, ub ::MOI.LessThan)
	for var_ind in _list_of_all_vars( func )
		if !MOI.is_valid( mop, var_ind )
			throw( MOI.InvalidIndex )
		end
	end

	constr_ind = MOI.ConstraintIndex{MOI.ScalarAffineFunction, MOI.LessThan}( next_id(keys(mop.scalar_affine_lt_constraints) ) )
	mop.scalar_affine_lt_constraints[ constr_ind ] = ub
	return constr_ind
end

function MOI.get( mop :: MOP, ::MOI.NumberOfConstraints )
	return sum( length( getfield(mop, fn) ) for 
		fn in [:lower_bounds, :upper_bounds, :scalar_affine_lt_constraints]) 
end
end#module