module VectorMathOptInterface

import MathOptInterface
const MOI = MathOptInterface

include("indextypes.jl")
include("attributes.jl")
include("objectives.jl")

########################## MOI "Import & Export" #################################
# get the names defined in MOI and construct and evaluate an expression `_moi_expr`
# such that for every `_moi_name` (not in `IMPORT_FILTER`) we have an assignement 
# `_moi_name = VectorMathOptInterface.MOI._moi_name`.

IMPORT_FILTER = [
	:ObjectiveFunction,
	:ObjectiveSense,
	:ObjectiveFunctionType,
	:ObjectiveValue,
	:DualObjectiveValue,
	:ObjectiveBound ]	# TODO RelativeGap?

_moi_names = Symbol[] 
for _moi_name in Base.names(MOI; all = true, imported = false)
	_moi_name_str = string(_moi_name)
	if startswith(_moi_name_str, "#")
		_moi_name_str = _moi_name_str[2:end]
	end
	_moi_name = Symbol(_moi_name_str)
	
	if !(_moi_name in IMPORT_FILTER) && !occursin("#",_moi_name_str) && 
		!isdefined(Base, _moi_name)
		push!(_moi_names, _moi_name)
	end
end

_vmoi_moi_subexpr = [ 
	Expr(:(=), 
		_moi_name, 
		Expr(:(.), 
			Expr(:(.), 
				:VectorMathOptInterface, QuoteNode(:MOI)), 
			QuoteNode(_moi_name))
	) for _moi_name in _moi_names 
]
_moi_expr = Expr(:toplevel, _vmoi_moi_subexpr...)
eval(_moi_expr)
########################## MOI "Import & Export" #################################

include("utils/ExampleMOP.jl")
using .ExampleMOP

end
