
using ConjugateGradients

function predictor(solver::MySolver,halpha::Halpha)
    
    solver.predict = true
    solver.Rp = solver.model.b

    if solver.model.nlmi > 0
        for i = 1:solver.model.nlmi
            solver.Rp -= solver.model.AA[i] * solver.X[i][:]
            solver.Rd[i] .= solver.model.C[i] - solver.S[i] - mat(solver.model.AA[i]' * solver.y)
            solver.Rc[i] .= solver.sigma .* solver.mu .* Matrix(I, length(solver.D[i]), 1) - solver.D[i] .^ 2
        end
    end

    if solver.model.nlin > 0
        solver.Rp -= solver.model.C_lin * solver.X_lin[:]
        solver.Rd_lin = solver.model.d_lin - solver.S_lin - solver.model.C_lin' * solver.y
        Rc_lin = solver.sigma * solver.mu .* ones(solver.model.nlin, 1) - solver.X_lin .* solver.S_lin
    end

    if solver.kit .== 0   # if direct solver; compute the Hessian matrix
    @timeit solver.to "BBBB" begin 
        if solver.model.nlmi > 0
            if 1 == 0
                BBBB = makeBBBB_rank1(solver.model.n,solver.model.nlmi,solver.model.B,solver.G)
            else
                # BBBB = makeBBBB(n,nlmi,A,G)   
                BBBB = makeBBBBalt(solver.model.n,solver.model.nlmi,solver.model.A,solver.model.AA,solver.W,solver.to)    
                # BBBB = makeBBBBalt1(solver.model.n,solver.model.nlmi,solver.model.A,solver.model.AA,solver.W)  
                # BBBB = makeBBBBsp(solver.model.n,solver.model.nlmi,solver.model.A,solver.model.myA,solver.W) 
                # BBBB = makeBBBBsp2(solver.model.n,solver.model.nlmi,solver.model.A,solver.model.myA,solver.W) 
            end
        else
            BBBB = zeros(Float64, solver.model.n, solver.model.n)
        end
        if solver.model.nlin > 0
            BBBB .+= solver.model.C_lin * spdiagm((solver.X_lin .* solver.S_lin_inv)[:]) * solver.model.C_lin'
            BBBB = Hermitian(BBBB)
        end
    end
    end

    if solver.model.nlmi > 0
        h = makeRHS(solver.model.nlmi,solver.model.AA,solver.W,solver.S,solver.Rp,solver.Rd)
    else
        h = copy(solver.Rp)
    end
    if solver.model.nlin > 0
        h .+= solver.model.C_lin * (spdiagm((solver.X_lin .* solver.Si_lin)[:]) * solver.Rd_lin + solver.X_lin)
    end

    # solving the linear system()
    if solver.kit == 0   # direct solver
    #     @timeit solver.to "backslash" begin
        if ishermitian(BBBB)
            try
                solver.cholBBBB = cholesky(BBBB)
            catch err
                println("Matrix H not positive definite, trying to regularize")
                icount = 0
                while isposdef(BBBB) == false
                    BBBB = BBBB + 1e-5 .* I(size(BBBB, 1))
                    icount = icount + 1
                    # @show icount
                    if icount > 1000
                        println("WARNING: H cannot be made positive definite, giving up")
                        solver.cholBBBB = I(size(BBBB, 1))
                        solver.status = 4
                        return
                    end
                end
                solver.cholBBBB = cholesky(BBBB)
            else
                solver.cholBBBB = copy(solver.cholBBBB)
            end
            solver.dely = solver.cholBBBB \ h
        else
            @warn("System matrix not Hermitian, stopping Loraine")
            solver.maxit = 1e10
            solver.status = 2
            solver.cholBBBB = 0
        end
    #     end
    else
        A = MyA(solver.W,solver.model.AA,solver.model.nlin,solver.model.C_lin,solver.X_lin,solver.S_lin_inv,solver.to)
        if solver.preconditioner == 0
            M = MyM_no(solver.to)
        elseif solver.preconditioner == 1
            Prec_for_CG_tilS_prep(solver,halpha)  
            M = MyM(solver.model.AA, halpha.AAAATtau, halpha.Umat, halpha.Z, halpha.cholS)
        elseif solver.preconditioner == 2 || solver.preconditioner == 4
            Prec_for_CG_beta(solver,halpha)  
            M = MyM_beta(solver.model.AA, halpha.AAAATtau)
        end

        @timeit solver.to "CG predictor" begin
        solver.dely, exit_code, num_iters = cg(A, h[:]; tol = solver.tol_cg, maxIter = 5000, precon = M)
        end

        # print(num_iters, exit_code)
        solver.cg_iter += num_iters
        solver.cg_iter_tot += num_iters
    end

    @timeit solver.to "find step predictor" begin
    find_step(solver)
    end

end

function sigma_update(solver)
    step_pred = min(minimum([solver.alpha; solver.alpha_lin]), minimum([solver.beta; solver.beta_lin]))
    if (solver.mu .> 1e-6)
        if (step_pred .< 1 / sqrt(3))
                expon_used = 1
        else
                expon_used = max(solver.expon, 3 * step_pred^2)
        end
    else
            expon_used = max(1, min(solver.expon, 3 * step_pred^2))
    end
    if btrace(solver.model.nlmi, solver.Xn, solver.Sn) .< 0
        solver.sigma = 0.8
    else
        if solver.model.nlmi > 0
            tmp1 = btrace(solver.model.nlmi, solver.Xn, solver.Sn)
        else
            tmp1 = 0
        end
        if solver.model.nlin > 0
                tmp2 = dot(solver.Xn_lin', solver.Sn_lin)
        else
                tmp2 = 0
        end
        tmp12 = (tmp1 + tmp2) / (sum(solver.model.msizes) + solver.model.nlin)
        solver.sigma = min(1, ((tmp12) / solver.mu)^expon_used)
    end

    return solver.sigma
end   

function corrector(solver,halpha)
    solver.predict = false
    h = solver.Rp #RHS for the linear system()
    if solver.model.nlmi > 0
        for i = 1:solver.model.nlmi
            h += solver.model.AA[i] * my_kron(solver.G[i], solver.G[i], (solver.G[i]' * solver.Rd[i] * solver.G[i] + spdiagm(solver.D[i]) - Diagonal((solver.sigma * solver.mu) ./ solver.D[i]) - solver.RNT[i]))         # RHS using my_kron()
        end
    end
    if solver.model.nlin > 0
        tmp = (solver.delX_lin .* solver.delS_lin) .* (solver.Si_lin) - (solver.sigma * solver.mu) .* (solver.Si_lin)
        h = h + solver.model.C_lin * (spdiagm((solver.X_lin .* solver.Si_lin)[:]) * solver.Rd_lin + solver.X_lin + tmp)
    end

    # solving the linear system()
    if solver.kit == 0   # direct solver
    # @timeit to "corrector backsl" begin
    solver.dely = solver.cholBBBB \ h
    
    else
        A = MyA(solver.W,solver.model.AA,solver.model.nlin,solver.model.C_lin,solver.X_lin,solver.S_lin_inv,solver.to)
        if solver.preconditioner == 0
            M = MyM_no(solver.to)
        elseif solver.preconditioner == 1
            M = MyM(solver.model.AA, halpha.AAAATtau, halpha.Umat, halpha.Z, halpha.cholS)
        else
            M = MyM_beta(solver.model.AA, halpha.AAAATtau)
        end

        @timeit solver.to "CG corrector" begin
        solver.dely, exit_code, num_iters = cg(A, h[:]; tol = solver.tol_cg, maxIter = 5000, precon = M)
        end
        solver.cg_iter += num_iters
        solver.cg_iter_tot += num_iters
    end
    # end

    # find delX, delS
    @timeit solver.to "find step corrector" begin
    find_step(solver)
    end
end

function find_step(solver)
    if solver.model.nlmi > 0
        for i = 1:solver.model.nlmi
            @timeit solver.to "find_step_A" begin
            solver.delS[i] = solver.Rd[i] - mat(solver.model.AA[i]' * solver.dely)
            Ξ = my_kron(solver.W[i], solver.W[i], solver.delS[i])
            if solver.predict
                solver.delX[i] = mat(-solver.X[i][:] - Ξ)
            else
                solver.delX[i] = mat(((solver.sigma * solver.mu) .* solver.Si[i] -solver.X[i])[:] - Ξ + my_kron(solver.G[i], solver.G[i], solver.RNT[i]))
            end
            end

            # determining steplength to stay feasible
            @timeit solver.to "find_step_B" begin
            delSb = solver.G[i]' * solver.delS[i] * solver.G[i]
            delXb = solver.Gi[i] * solver.delX[i] * solver.Gi[i]'
            delXb = Hermitian(delXb)
            end

            @timeit solver.to "find_step_C" begin
            XXX = solver.DDsi[i]' .* delXb .* solver.DDsi[i]
            XXX = Hermitian(Matrix(XXX))
            end
            @timeit solver.to "find_step_D" begin
            mimiX = eigmin(XXX)
            end
            if mimiX .> -1e-6
                solver.alpha[i] = 0.9
            else
                solver.alpha[i] = min(1, -solver.tau / mimiX)
            end

            @timeit solver.to "find_step_C" begin
            XXX = solver.DDsi[i]' .* delSb .* solver.DDsi[i]
            XXX = Hermitian(Matrix(XXX))
            end
            @timeit solver.to "find_step_D" begin
            mimiS = eigmin(XXX)
            end
            if mimiS .> -1e-6
                solver.beta[i] = 0.9
            else
                solver.beta[i] = min(1, -solver.tau / mimiS)
            end
        end
    end

    if solver.model.nlin > 0
        find_step_lin(solver)
    else
        solver.alpha_lin = 1
        solver.beta_lin = 1
    end    

    if solver.predict
        # solution update
        if solver.model.nlmi > 0
            for i = 1:solver.model.nlmi
                solver.Xn[i] = solver.X[i] + solver.alpha[i] .* solver.delX[i]
                solver.Sn[i] = solver.S[i] + solver.beta[i] .* solver.delS[i]
                deed = solver.D[i] * ones(1, Int(solver.model.msizes[i])) + ones(Int(solver.model.msizes[i]), 1) * solver.D[i]'
                solver.RNT[i] = -(solver.Gi[i] * solver.delX[i] * solver.delS[i] * solver.G[i] + solver.G[i]' * solver.delS[i] * solver.delX[i] * solver.Gi[i]') ./ deed 
            end
        end
    else
        solver.yold = solver.y
        solver.y = solver.y + minimum([solver.beta; solver.beta_lin]) * solver.dely
        if solver.model.nlmi > 0
            for i = 1:solver.model.nlmi
                solver.X[i] = solver.X[i] + minimum([solver.alpha; solver.alpha_lin]) .* solver.delX[i]
                solver.X[i] = Hermitian(solver.X[i])
                solver.S[i] = solver.S[i] + minimum([solver.beta; solver.beta_lin]) .* solver.delS[i]
                solver.S[i] = Hermitian(solver.S[i])
            end       
        end
    end  

    return
end


function find_step_lin(solver)
    solver.delS_lin = solver.Rd_lin - solver.model.C_lin' * solver.dely
    if solver.predict
        solver.delX_lin = -solver.X_lin - (solver.X_lin) .* (solver.Si_lin) .* solver.delS_lin
    else
        solver.delX_lin = -solver.X_lin - (solver.X_lin) .* (solver.Si_lin) .* solver.delS_lin + (solver.sigma * solver.mu) .* (solver.Si_lin) + solver.RNT_lin
    end
    mimiX_lin = minimum(solver.delX_lin ./ solver.X_lin)
    if mimiX_lin .> -1e-6
        solver.alpha_lin = 0.9
    else
        solver.alpha_lin = min(1, -solver.tau / mimiX_lin)
    end
    mimiS_lin = minimum(solver.delS_lin ./ solver.S_lin)
    if mimiS_lin .> -1e-6
        solver.beta_lin = 0.9
    else
        solver.beta_lin = min(1, -solver.tau / mimiS_lin)
    end

    if solver.predict
        # solution update
        solver.Xn_lin = solver.X_lin + solver.alpha_lin .* solver.delX_lin
        solver.Sn_lin = solver.S_lin + solver.beta_lin .* solver.delS_lin

        solver.RNT_lin = -(solver.delX_lin .* solver.delS_lin) .* solver.Si_lin
    else
        # @show solver.X_lin
        # @show mimiX_lin
        solver.X_lin = solver.X_lin + minimum([solver.alpha; solver.alpha_lin]) .* solver.delX_lin
        solver.S_lin = solver.S_lin + minimum([solver.beta; solver.beta_lin]) .* solver.delS_lin
        solver.S_lin_inv = 1 ./ solver.S_lin

        
        # @show minimum([solver.alpha; solver.alpha_lin])
        # @show solver.delX_lin
        # @show solver.X_lin
    
    end


    return 
end
