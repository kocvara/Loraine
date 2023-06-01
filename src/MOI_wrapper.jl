using MathOptInterface
const MOI = MathOptInterface

const VAF = MOI.VectorAffineFunction{Float64}
const PSD = MOI.PositiveSemidefiniteConeTriangle
const NNG = MOI.Nonnegatives

MOI.Utilities.@product_of_sets(NNGCones, NNG)

MOI.Utilities.@product_of_sets(PSDCones, PSD)

MOI.Utilities.@struct_of_constraints_by_set_types(PSDOrNot, PSD, NNG)

const OptimizerCache = MOI.Utilities.GenericModel{
    Float64,
    MOI.Utilities.ObjectiveContainer{Float64},
    MOI.Utilities.VariablesContainer{Float64},
    PSDOrNot{Float64}{
        MOI.Utilities.MatrixOfConstraints{
            Float64,
            MOI.Utilities.MutableSparseMatrixCSC{
                Float64,
                Int64,
                MOI.Utilities.OneBasedIndexing,
            },
            Vector{Float64},
            PSDCones{Float64},
        },
        MOI.Utilities.MatrixOfConstraints{
            Float64,
            MOI.Utilities.MutableSparseMatrixCSC{
                Float64,
                Int64,
                MOI.Utilities.OneBasedIndexing,
            },
            Vector{Float64},
            NNGCones{Float64},
        },
    },
}

mutable struct Optimizer <: MOI.AbstractOptimizer
    solver::Union{Nothing,MySolver}
    halpha::Union{Nothing,Halpha}
    lmi_id::Dict{MOI.ConstraintIndex{VAF,PSD},Int64}
    lin_cones::Union{Nothing,NNGCones{Float64}}
    max_sense::Bool
    objective_constant::Float64
    silent::Bool
    options::Dict{String,Any}

    function Optimizer()
        return new(
            nothing,
            nothing,
            Dict{MOI.ConstraintIndex{VAF,PSD},Int64}(),
            nothing,
            false,
            0.0,
            false,
            copy(Solvers.DEFAULT_OPTIONS),
        )
    end
end

function MOI.default_cache(::Optimizer, ::Type{Float64})
    return MOI.Utilities.UniversalFallback(OptimizerCache())
end

function MOI.is_empty(optimizer::Optimizer)
    return isnothing(optimizer.solver)
end

function MOI.empty!(optimizer::Optimizer)
    optimizer.solver = nothing
    optimizer.lin_cones = nothing
    return
end

MOI.get(::Optimizer, ::MOI.SolverName) = "Loraine"

# MOI.RawOptimizerAttribute

function MOI.supports(::Optimizer, param::MOI.RawOptimizerAttribute)
    return haskey(Solvers.DEFAULT_OPTIONS, param.name)
end

function MOI.set(optimizer::Optimizer, param::MOI.RawOptimizerAttribute, value)
    if !MOI.supports(optimizer, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    optimizer.options[param.name] = value
    return
end

function MOI.get(optimizer::Optimizer, param::MOI.RawOptimizerAttribute)
    if !MOI.supports(optimizer, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    return optimizer.options[param.name]
end

# MOI.Silent

MOI.supports(::Optimizer, ::MOI.Silent) = true

function MOI.set(optimizer::Optimizer, ::MOI.Silent, value::Bool)
    optimizer.silent = value
    return
end

MOI.get(optimizer::Optimizer, ::MOI.Silent) = optimizer.silent

# MOI.supports

function MOI.supports(
    ::Optimizer,
    ::Union{MOI.ObjectiveSense,MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}},
)
    return true
end

const SUPPORTED_CONES = Union{NNG,PSD}

function MOI.supports_constraint(::Optimizer, ::Type{VAF}, ::Type{<:SUPPORTED_CONES})
    return true
end

function MOI.optimize!(optimizer::Optimizer)
    optimizer.solver.to = TimerOutput()
    solve(optimizer.solver, optimizer.halpha)
    return
end

function MOI.copy_to(dest::Optimizer, src::OptimizerCache)
    MOI.empty!(dest)
    psd_AC = MOI.Utilities.constraints(src.constraints, VAF, PSD)
    Cd_lin = MOI.Utilities.constraints(src.constraints, VAF, NNG)
    SM = SparseMatrixCSC{Float64,Int64}
    psd_A = convert(SM, psd_AC.coefficients)
    C_lin = convert(SM, Cd_lin.coefficients)
    C_lin = convert(SM, C_lin')
    n = MOI.get(src, MOI.NumberOfVariables())
    nlmi = MOI.get(src, MOI.NumberOfConstraints{VAF,PSD}())
    A = Matrix{Tuple{Vector{Int64},Vector{Int64},Vector{Float64},Int64,Int64}}(undef, nlmi, n + 1)
    back = Vector{Tuple{Int64,Int64,Int64}}(undef, size(psd_A, 1))
    empty!(dest.lmi_id)
    row = 0
    msizes = Int64[]
    for (lmi_id, ci) in enumerate(MOI.get(src, MOI.ListOfConstraintIndices{VAF,PSD}()))
        dest.lmi_id[ci] = lmi_id
        set = MOI.get(src, MOI.ConstraintSet(), ci)
        d = set.side_dimension
        push!(msizes, d)
        for k = 1:(n+1)
            A[lmi_id, k] = (Int64[], Int64[], Float64[], d, d)
        end
        for j = 1:d
            for i = 1:j
                row += 1
                back[row] = (lmi_id, i, j)
            end
        end
    end
    function __add(lmi_id, k, i, j, v)
        I, J, V, _, _ = A[lmi_id, k]
        push!(I, i)
        push!(J, j)
        push!(V, v)
        return
    end
    function _add(lmi_id, k, i, j, coef)
        __add(lmi_id, k, i, j, coef)
        if i != j
            __add(lmi_id, k, j, i, coef)
        end
        return
    end
    for row in eachindex(back)
        lmi_id, i, j = back[row]
        _add(lmi_id, 1, i, j, -psd_AC.constants[row])
    end
    for var = 1:n
        for k in nzrange(psd_A, var)
            lmi_id, i, j = back[rowvals(psd_A)[k]]
            col = 1 + var
            _add(lmi_id, col, i, j, nonzeros(psd_A)[k])
        end
    end
    max_sense = MOI.get(src, MOI.ObjectiveSense()) == MOI.MAX_SENSE
    obj = MOI.get(src, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}())
    # objective_constant = MOI.constant(obj) # TODO
    b0 = zeros(n)
    for term in obj.terms
        b0[term.variable.value] += term.coefficient
    end
    b = max_sense ? b0 : -b0
    AA = Any[sparse(IJV...) for IJV in A]
    model = MyModel(
        AA,
        Solvers._prepare_A(AA)...,
        b,
        sparsevec(-Cd_lin.constants),
        C_lin,
        n,
        msizes,
        Int64(length(Cd_lin.constants)),
        nlmi,
    )
    # FIXME this does not work if an option is changed between `MOI.copy_to` and `MOI.optimize!`
    options = copy(dest.options)
    if dest.silent
        options["verb"] = 0
    end
    dest.lin_cones = Cd_lin.sets
    dest.solver, dest.halpha = load(model, options)
    return MOI.Utilities.identity_index_map(src)
end

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike)
    cache = OptimizerCache()
    index_map = MOI.copy_to(cache, src)
    MOI.copy_to(dest, cache)
    return index_map
end

function MOI.get(optimizer::Optimizer, ::MOI.TerminationStatus)
    if isnothing(optimizer.solver) || optimizer.solver.status == 0
        return MOI.OPTIMIZE_NOT_CALLED
    elseif optimizer.solver.status == 1
        return MOI.OPTIMAL
    else
        @assert optimizer.solver.status == 2
        return MOI.ITERATION_LIMIT
    end
end

function MOI.get(model::Optimizer, ::Union{MOI.PrimalStatus,MOI.DualStatus})
    term = MOI.get(model, MOI.TerminationStatus())
    if term == MOI.OPTIMIZE_NOT_CALLED
        return MOI.NO_SOLUTION
    elseif term == MOI.OPTIMAL
        return MOI.FEASIBLE_POINT
    else
        @assert term == MOI.ITERATION_LIMIT
        return MOI.UNKNOWN_RESULT_STATUS
    end
end

function MOI.get(model::Optimizer, ::MOI.ResultCount)
    if MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED
        return 0
    else
        return 1
    end
end

function MOI.get(optimizer::Optimizer, attr::MOI.ObjectiveValue)
    MOI.check_result_index_bounds(optimizer, attr)
    val = dot(optimizer.solver.model.b, optimizer.solver.y)
    return optimizer.max_sense ? val : -val
end

function MOI.get(optimizer::Optimizer, attr::MOI.DualObjectiveValue)
    MOI.check_result_index_bounds(optimizer, attr)
    val =
        btrace(optimizer.solver.model.nlmi, optimizer.solver.model.C, optimizer.solver.X) +
        dot(optimizer.solver.model.d_lin, optimizer.solver.X_lin)
    return optimizer.max_sense ? val : -val
end

function MOI.get(model::Optimizer, attr::MOI.VariablePrimal, vi::MOI.VariableIndex)
    MOI.check_result_index_bounds(model, attr)
    return model.solver.y[vi.value]
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{VAF,PSD},
)
    MOI.check_result_index_bounds(optimizer, attr)
    lmi_id = optimizer.lmi_id[ci]
    X = optimizer.solver.X[lmi_id]
    n = optimizer.solver.model.msizes[lmi_id]
    return [X[i, j] for j = 1:n for i = 1:j]
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{VAF,NNG},
)
    MOI.check_result_index_bounds(optimizer, attr)
    rows = MOI.Utilities.rows(optimizer.lin_cones, ci)
    return -optimizer.solver.X_lin[rows]
end
