""""Solve a semidefinite optimization problem in SDPA input format by Loraine using JuMP 
(or any other SDP code linked in JuMP)"""

using JuMP
import Loraine 
import CSDP
import SCS
using Mosek
using MosekTools
import Hypatia
using Dualization

# Select your semidefinite optimization problem in SDPA input format
# model=read_from_file("/Users/michal/Dropbox/michal/sdplib/Hans/trto4.dat-s")
# model=read_from_file("/Users/michal/Dropbox/michal/sdplib/theta6.dat-s")
# model=read_from_file("/Users/michal/Dropbox/michal/POEMA/IP/ip-for-low-rank-sdp/database/problems/SDPA/tru3.dat-s")
# model=read_from_file("/Users/michal/Dropbox/michal/POEMA/IP/ip-for-low-rank-sdp/database/problems/SDPA/hubbard_X4N4p.10000.0.pqg.dat-s")
model=read_from_file("/Users/michal/Dropbox/michal/j/k.dat-s")


# model=read_from_file("examples/data/theta1.dat-s")
# model=read_from_file("examples/data/maxG11.dat-s") #use with "datarank = -1"

set_optimizer(model, Loraine.Optimizer)

# # Loraine options

# set_attribute(model, "kit", 0)
# set_attribute(model, "tol_cg", 1.0e-2)
# set_attribute(model, "tol_cg_min", 1.0e-6)
# set_attribute(model, "eDIMACS", 1e-15)
# set_attribute(model, "preconditioner", 1)
# set_attribute(model, "erank", 1)
# set_attribute(model, "aamat", 2)
# set_attribute(model, "verb", 1)
# set_attribute(model, "datarank", -1)
# set_attribute(model, "initpoint", 0)
# set_attribute(model, "maxit", 100)
# set_attribute(model, "datarank", 0)

# set_optimizer(model, Loraine.Optimizer)
optimize!(model)

# Mosek (CSDP, etc) for a comparison
# Mosek must solve the dualized problem to be efficient

set_optimizer(model, CSDP.Optimizer)
dual_model = dualize(model, CSDP.Optimizer)
@time optimize!(dual_model)

# termination_status(model)