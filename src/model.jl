# module Model

# NOT WORKING!!!

export prepare_model_data, MyModel, SpMa

using SparseArrays
using Printf
using TimerOutputs
using LinearAlgebra

struct SpMa{Tv,Ti<:Integer}
    n::Int64
    iind::Vector{Ti}
    jind::Vector{Ti}
    nzval::Vector{Tv}
end

mutable struct MyModel
    A::Matrix{Any}
    AA::Vector{SparseArrays.SparseMatrixCSC{Float64}}
    myA::Vector{SpMa{Float64}}
    B::Vector{SparseArrays.SparseMatrixCSC{Float64}}
    C::Vector{SparseArrays.SparseMatrixCSC{Float64}}
    nzA::Matrix{Int64}
    sigmaA::Matrix{Int64}
    qA::Vector{Int64}
    b::Vector{Float64}
    b_const::Float64
    d_lin::SparseArrays.SparseVector{Float64, Int64}
    C_lin::SparseArrays.SparseMatrixCSC{Float64, Int64}
    n::Int64
    msizes::Vector{Int64}
    nlin::Int64
    nlmi::Int64

    function MyModel(
        A::Matrix{Any},
        AA::Vector{SparseArrays.SparseMatrixCSC{Float64}},
        myA::Vector{SpMa{Float64}},
        B::Vector{SparseArrays.SparseMatrixCSC{Float64}},
        C::Vector{SparseArrays.SparseMatrixCSC{Float64}},
        nzA::Matrix{Int64},
        sigmaA::Matrix{Int64},
        qA::Vector{Int64},
        b::Vector{Float64},
        b_const::Float64,
        d_lin::SparseArrays.SparseVector{Float64, Int64},
        C_lin::SparseArrays.SparseMatrixCSC{Float64, Int64},
        n::Int64,
        msizes::Vector{Int64},
        nlin::Int64,
        nlmi::Int64
        ) 

        model = new()
        model.A = A
        model.AA = AA
        model.myA = myA
        model.B = B
        model.C = C
        model.nzA = nzA
        model.sigmaA = sigmaA
        model.qA = qA
        model.b = b
        model.b_const = b_const
        model.d_lin = d_lin
        model.C_lin = C_lin
        model.n = n
        model.msizes = msizes
        model.nlin = nlin
        model.nlmi = nlmi
        return model
    end
end


function prepare_model_data(d)

msizes = Vector{Int64}
n = Int64(get(d, "nvar", 1));
msizesa = get(d, "msizes", 1)
if length(msizesa) == 1
    msizes = [convert.(Int64,msizesa)]
else
    msizes = convert.(Int64,msizesa[:])
end
nlin = Int64(get(d, "nlin", 1))
nlmi = Int64(get(d, "nlmi", 1))
A = get(d, "A", 1);
b = -get(d, "c", 1);
b_const = -get(d, "b_const", 1);

if nlin > 0
    d_lin = -get(d, "d", 1)
    d_lin = d_lin[:]
    C_lin = -get(d, "C", 1)
else
    d_lin = sparse([0.; 0.])
    C_lin = sparse([0. 0.;0. 0.])
end

drank = 0
model = MyModel(A, _prepare_A(A,drank)..., Float64.(b), Float64.(b_const), Float64.(d_lin), Float64.(C_lin), n, msizes, nlin, nlmi)

return model
end

function _prepare_A(A, datarank)

    nlmi = size(A, 1)
    n = size(A, 2) - 1
    AA = SparseMatrixCSC{Float64}[]
    myA = SpMa{Float64}[]
    B = SparseMatrixCSC{Float64}[]
    C = SparseMatrixCSC{Float64}[]
    nzA = zeros(Int64,n,nlmi)
    sigmaA = zeros(Int64,n,nlmi)
    qA = zeros(Int64,2)

    for i = 1:nlmi
        
        push!(C, copy(-A[i, 1]))

        Ai = A[i,:]
        AAA = prep_AA!(myA,Ai,n)
        push!(AA, copy(AAA'))

        # if 1 == 0
        if datarank == -1
            Btmp = prep_B!(A,n,i)
            push!(B, Btmp)
        end

        prep_sparse!(A,n,i,nzA,sigmaA,qA)
        # @show nzA[1:10]
        # @show nzA[end-9:end]
        # @show sigmaA[1:10]
        # @show sigmaA[end-9:end]


    end

    return AA, myA, B, C, nzA, sigmaA, qA
end

function prep_sparse!(A,n,i,nzA,sigmaA,qA)
    d1 = zeros(Float64,n)
    d2 = zeros(Float64,n)
    d3 = zeros(Float64,n)

    kappa = 900.
    for j = 1:n
        nzA[j,i] = nnz(A[i,j+1])
    end
    sisi = sort(nzA[:,i], rev = true)
    cs = cumsum(sisi[end:-1:1])
    cs = cs[n:-1:1]
    sigmaA[:,i] = sortperm(nzA[:,i], rev = true)

    for j = 1:n
        d1[j] = kappa * n * nzA[sigmaA[j,i]] + n^3 + kappa * cs[i]
        d2[j] = kappa * n * nzA[sigmaA[j,i]] + kappa * (n+1) * cs[i]
        d3[j] = kappa * (2 * kappa * nzA[sigmaA[j,i]] + 1) * cs[i]
    end

    # @show d1[1:10]
    # @show d1[end-9:end]
    # @show d2[1:10]
    # @show d2[end-9:end]
    # @show d3[1:10]
    # @show d3[end-9:end]


    qA[1] = 0
    ktmp = 0
    for j = 1:n
        if d1[j] > min(d2[j],d3[j])
            qA[1] = j-1
            ktmp = 1
            break
        end
    end
    if ktmp == 0
        qA[1] = n
        qA[2] = n
    else
        qA[2] = 0
        for j = max(1,qA[1]):n
            if d2[j] >= d1[j] || d2[j] > d3[j]
                qA[2] = j-1
                break
            end
        end
    end
    qA[2] = max(qA[2],qA[1])

    @show qA

end

function prep_B!(A,n,i)
    m = size(A[i, 1],1)
    Btmp = spzeros(n,m)

    for k = 1:n
        ii = rowvals(A[i, k + 1])
        bidx = unique(ii)
        if !isempty(bidx)
            tmp = Matrix(A[i, k + 1][bidx, bidx])
            # utmp, vtmp = eigen(Hermitian(tmp))
            utmp, vtmp = eigen((tmp + tmp') ./ 2)
            bbb = sign.(vtmp[:, end]) .* sqrt.(diag(tmp))
            tmp2 = bbb * bbb'
            if norm(tmp - tmp2) > 5.0e-6
                drank = 0
                println("\n WARNING: data conversion problem, switching to datarank = 0")
                break
            end
            Btmp[k, bidx] = bbb
        end
    end

    return Btmp
end

function prep_AA!(myA,Ai,n)

    @inbounds Threads.@threads for j = 1:n
        if isempty(Ai[j+1])
            Ai[j+1][1, 1] = 0
        end
    end

    ntmp = size(Ai[1], 1) * size(Ai[1], 2)
    
    nnz = 0
    @inbounds for j = 1:n
        ii,jj,vv = findnz(-(Ai[j+1]))
        push!(myA,SpMa(Int64(length(ii)),ii,jj,Float64.(vv)))
        nnz += length(ii)
    end

    iii = zeros(Int64, nnz)
    jjj = zeros(Int64, nnz)
    vvv = zeros(Float64, nnz)
    AAA1 = spzeros(ntmp, n)
    lb = 1
    @inbounds for j = 1:n      
        ii,vv = findnz(-(Ai[j+1])[:])
        lf = lb+length(ii)-1
        iii[lb:lf] = ii
        jjj[lb:lf] = j .* ones(Int64,length(ii))
        vvv[lb:lf] = Float64.(vv)
        lb = lf+1
    end
    AAA = sparse(iii,jjj,vvv,ntmp,n)

    return AAA
end

# end #module
