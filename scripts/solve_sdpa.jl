""""Solve a semidefinite optimization problem in SDPA input format by Loraine using JuMP 
(or any other SDP code linked in JuMP)"""

using JuMP
import Loraine # if needed, do "] activate Loraine" in directory above Loraine

# Select your semidefinite optimization problem in SDPA input format
# model=read_from_file("/Users/michal/Dropbox/michal/sdplib/thetaG11.dat-s")
model=read_from_file("/Users/michal/Dropbox/michal/POEMA/IP/ip-for-low-rank-sdp/database/problems/SDPA/tru15.dat-s")

set_optimizer(model, Loraine.Optimizer)

# Loraine options
MOI.set(model, MOI.RawOptimizerAttribute("kit"), 1)
MOI.set(model, MOI.RawOptimizerAttribute("tol_cg"), 1.0e-2)
MOI.set(model, MOI.RawOptimizerAttribute("tol_cg_min"), 1.0e-6)
MOI.set(model, MOI.RawOptimizerAttribute("eDIMACS"), 1e-5)
MOI.set(model, MOI.RawOptimizerAttribute("preconditioner"), 4)
MOI.set(model, MOI.RawOptimizerAttribute("aamat"), 2)
MOI.set(model, MOI.RawOptimizerAttribute("verb"), 1)
MOI.set(model, MOI.RawOptimizerAttribute("initpoint"), 0)
MOI.set(model, MOI.RawOptimizerAttribute("maxit"), 100)

# @time begin
optimize!(model)
# end

# termination_status(model)