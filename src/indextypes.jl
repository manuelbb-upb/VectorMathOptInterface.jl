struct ObjectiveIndex{ F <:MOI.AbstractFunction }
	value :: Int64
end

# TODO: should `ObjectiveIndex` be a subtype of MOI.AbstractFunction`?
# this would allow for constraints involving the objectives, i.e.
# min_x f, subject to f(x) ≤ 0 ?
