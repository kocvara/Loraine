var documenterSearchIndex = {"docs":
[{"location":"low-rank_data.html#Low-rank-data,-more-details","page":"Low-rank data, more details","title":"Low-rank data, more details","text":"","category":"section"},{"location":"low-rank_data.html","page":"Low-rank data, more details","title":"Low-rank data, more details","text":"Assume that matrices A_i in sum_i=1^n y_i A_i + S = C  Ssucceq 0 are obtained  by","category":"page"},{"location":"low-rank_data.html","page":"Low-rank data, more details","title":"Low-rank data, more details","text":"  A_i = B_i B_i^top","category":"page"},{"location":"low-rank_data.html","page":"Low-rank data, more details","title":"Low-rank data, more details","text":"with data matrices B_iinmathbb R^mtimes k and with k ll n.","category":"page"},{"location":"low-rank_data.html","page":"Low-rank data, more details","title":"Low-rank data, more details","text":"The complexity of H assembly is then reduced from nm^3 to knm^2.","category":"page"},{"location":"low-rank_data.html","page":"Low-rank data, more details","title":"Low-rank data, more details","text":"In particular: If we know that A_i have rank one, the decomposition A_i = b_i b_i^top is performed by Lorain automatically (datarank = -1).","category":"page"},{"location":"overview.html#Loraine-LOw-RAnk-INtErior-point-method","page":"Overview","title":"Loraine - LOw-RAnk INtErior point method","text":"","category":"section"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Primal-dual predictor-corrector interior-point method together with (optional) iterative solution of the resulting linear systems.","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"The iterative solver is a preconditioned Krylov-type method with a preconditioner utilizing low rank of the solution.","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Loraine is a general purpose SDP solver, particularly efficient for SDP problems with low-rank data and/or very-low-rank solutions.","category":"page"},{"location":"overview.html#Linear-SDP-problem","page":"Overview","title":"Linear SDP problem","text":"","category":"section"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Let's first fix the notation and the problem Lorain atempts to solve. Consider the primal and the dual linear SDP problem with explicit linear constraints in variables ","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"textprimal X in mathbbS^m x_textlinin mathbbR^pqquad \ntextdual y in mathbbR^n S in mathbbS^m s_textlin in mathbbR^p","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"and with data","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"A_i in mathbbS^m (i=1ldotsn) C in mathbbS^m cinmathbb R^n Dinmathbb R^ntimes p dinmathbb R^p","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Primal problem","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"beginequation*tagP\nbeginaligned\nmax_XinmathbbS^mx_textlininmathbbR^mC bullet X + d^top x_textlin\ntextsubject to \nqquad A_i bullet X+ (D^top x_textlin)_i=b_i quad i=1dotsn\nqquad Xsucceq 0  x_textlingeq 0 \nendaligned\nendequation*","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Dual problem","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"\t\tbeginequation*tagD\n\tbeginaligned\n\t min_yinmathbbR^nSinmathbbS^ms_textlininmathbbR^m c^top y \n\t textsubject to\n\tqquad sum_i=1^n y_i A_i + S = C  Ssucceq 0\n\tqquad Dy+s_textlin=d  s_textlingeq 0\n\tendaligned\n    endequation*","category":"page"},{"location":"overview.html#General-assumptions-(for-the-IP-algorithm-to-converge)","page":"Overview","title":"General assumptions (for the IP algorithm to converge)","text":"","category":"section"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Slater constraint qualification and strict complementarity","category":"page"},{"location":"overview.html#Low-rank-solution","page":"Overview","title":"Low-rank solution","text":"","category":"section"},{"location":"overview.html","page":"Overview","title":"Overview","text":"The following assumptions are only needed when the user want to usilize the iterative solver with the low-rank preconditioner (kit = 1, preconditioner > 0). The assumptions are not needed when using Loraine with the direct solver (kit = 0).","category":"page"},{"location":"overview.html#Assumptions:","page":"Overview","title":"Assumptions:","text":"","category":"section"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Main assumption","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"We assume that X^*, the solution of (P)(!!), has very low rank.","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Be sure about your problem formulation: If X^* has low rank then S^*, the solution of the dual problem, has almost full rank and vice versa. Hence if, in your problem, you assume that S^* has low rank, you cannot use Loraine with iterative solver directly; rather you may need to dualize your formulation using JuMP's dualize.","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Further assumptions","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"Sparsity of A_i: Define the matrix cal A=textsvecA_1dots textsvecA_n We assume that matrix-vector products with cal A and cal A^top may each be applied in O(n) flops and memory.\nSparsity of D: The inverse (D^top D)^-1 and matrix-vector product with (D^top D)^-1 may each be computed in mathcalO(n) flops and memory.","category":"page"},{"location":"overview.html#Low-rank-data","page":"Overview","title":"Low-rank data","text":"","category":"section"},{"location":"overview.html","page":"Overview","title":"Overview","text":"At the moment, Loraine can only handle rank-one data.\nThis feature is only relevant for Loraine used with the direct solver.","category":"page"},{"location":"overview.html","page":"Overview","title":"Overview","text":"If you know (or strongly suspect) that all data matrices A_i have rank one, select the option datarank = -1. Loraine will factorize the matrices as A_i = b_i b_i^top and use only the vectors b_i in the interior point algorithm. This will gravely reduce the complexity (and the elapsed time) of Loraine.","category":"page"},{"location":"Loraine_options.html#Options","page":"Loraine Options","title":"Options","text":"","category":"section"},{"location":"Loraine_options.html","page":"Loraine Options","title":"Loraine Options","text":"The list of Loraine options (default values are in the [bracket]):","category":"page"},{"location":"Loraine_options.html","page":"Loraine Options","title":"Loraine Options","text":"kit             # kit = 0 for direct solver; kit = 1 for CG [0]\ntol_cg          # initial tolerance for CG solver [1.0e-2]\ntol_cg_up       # tolerance update [0.5]\ntol_cg_min      # minimal tolerance for CG solver [1.0e-6]\neDIMACS         # epsilon for DIMACS error stopping criterion [1.0e-5]\npreconditioner  # 0...no; 1...H_alpha; 2...H_beta; 4...hybrid [1]\nerank           # estimated rank [1]\naamat           # 0..A^TA; 1..diag(A^TA); 2..identity [2]\nverb            # 2..full output; 1..short output; 0..no output [1]\ndatarank        # 0..full rank matrices expected [0]\n                # -1..rank-1 matrices expected, converted to vectors, if possible\n                # (TBD) 1..vectors expected for low-rank data matrices\ninitpoint       # 0..Loraine heuristics, 1..SDPT3-like heuristics [0]\ntiming          # 1..yes, 0..no\nmaxit           # maximal number of global iterations [200]","category":"page"},{"location":"Loraine_options.html#Comments","page":"Loraine Options","title":"Comments","text":"","category":"section"},{"location":"Loraine_options.html","page":"Loraine Options","title":"Loraine Options","text":"eDIMACS is checked against the maximum of DIMACS errors, measuring (weighted) primal and dual infeasibility, complementary slackness and duality gap.  \nfor the direct solver (kit = 0), value about 1e-7 should give a similar precision as default MOSEK\nfor the iterative solver (kit = 1), eDIMACS may need to be increased to 1e-6 or even 1e-5 to guarantee convergence of Loraine.\nfor the iterative solver (kit = 1), tol_cg_min should always be smaller than or equal to eDIMACS\npreconditioner\nper CG iteration, 0 is faster (lower complexity) than 2 which is faster than 1\nas a preconditioner, 1 is better than 2 is better than 0, in the sence of CG iterations needed to solve the linear system\nsome  SDP problems are \"easy\", meaning that CG always converges without preconditioner (i.e., `preconditioner = 0'), so it's always worth trying this option\nhybrid (preconditioner = 4) starts with (cheaper) H_beta and once it gets into difficulties, switches to H_alpha\nerank (only used when kit = 1 and preconditioner > 0)\nif you are not sure what the actual rank of the solution is, always choose erank = 1; with inreasing value of erank, the complexity of the preconditioner grows and the whole code could be slower, despite neding fewer CG iterations\nonly if you are sure about the rank of the solution, set erank to this value (but you should always compare it to erank = 1)\ndatarank (only used with the direct solver kit = 0)\nchoose datarank = -1 if you know (or suspect) that all the data matrices A_i have rank one; in this case, the matrices will be factorized as A_i = b_i b_i^T and vectors b_i will be used when constructing the Schur complement matrix\nif you are not sure about the rank of the data matrices, you can always try to set datarank = -1; if the factorization of any matrix fails, Lorain will switch to the default option datarank = 0\nfor rank-one data matrices, option datarank = -1 will result in a much faster code than the default datarank = 0\ntiming is not used when Loraine is called from JuMP\ntol_cg, tol_cg_up, aamat: it is not recommended to change values of these options, unless you really want to","category":"page"},{"location":"index.html#Loraine.jl","page":"Index","title":"Loraine.jl","text":"","category":"section"},{"location":"index.html","page":"Index","title":"Index","text":"Loraine.jl is a Julia implementation of an interior point method algorithm for linear semidefinite optimization problems. ","category":"page"},{"location":"index.html","page":"Index","title":"Index","text":"The special feature of Loraine is the iterative solver for linear systems. This is to be used for problems with (very) low rank solution matrix.","category":"page"},{"location":"index.html","page":"Index","title":"Index","text":"Standard (non-low-rank) problems and linear programs can be solved using the direct solver; then the user gets a standard IP method akin SDPT3.","category":"page"},{"location":"index.html#Installation","page":"Index","title":"Installation","text":"","category":"section"},{"location":"index.html","page":"Index","title":"Index","text":"Install Loraine using Pkg.add:","category":"page"},{"location":"index.html","page":"Index","title":"Index","text":"import Pkg\nPkg.add(\"Loraine\")","category":"page"},{"location":"index.html#License-and-Original-Contributors","page":"Index","title":"License and Original Contributors","text":"","category":"section"},{"location":"index.html","page":"Index","title":"Index","text":"Loraine is licensed under the MIT License.","category":"page"},{"location":"index.html","page":"Index","title":"Index","text":"Loraine was developed by Soodeh Habibi and Michal Kočvara, University of Birmingham, and Michael Stingl, University of Erlangen, for H2020 ITN POEMA. ","category":"page"},{"location":"index.html","page":"Index","title":"Index","text":"The JuMP interface was provided by Benoît Legat. His help is greatly acknowledged.","category":"page"},{"location":"index.html#Citing","page":"Index","title":"Citing","text":"","category":"section"},{"location":"index.html","page":"Index","title":"Index","text":"If you find Loraine useful, please cite the following paper:","category":"page"},{"location":"index.html","page":"Index","title":"Index","text":"@article{loraine2023,\n  title={Loraine-An interior-point solver for low-rank semidefinite programming},\n  author={Habibi, Soodeh and Ko{\\v{c}}vara, Michal and Stingl, Michael},\n  www={https://hal.science/hal-04076509/}\n  note={Preprint hal-04076509}\n  year={2023}\n}","category":"page"},{"location":"low-rank_solutions.html#Low-rank-solution,-more-details","page":"Low-rank Solutions","title":"Low-rank solution, more details","text":"","category":"section"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"In each iteration of the (primal-dual, predictor-corrector) interior-point method we have to solve two systems of linear equations in variable y with a scaling matrix W:","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"beginequation\nH=cal A^T(Wotimes W)cal A+ D^T X_rm linS^-1_rm lin D\nendequation","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"The complexity of interior point method can be significantly reduced by solving the Schur complement equation H y = r by an iterative method, rather than Cholesky solver, a standard choice of most IP-based software. ","category":"page"},{"location":"low-rank_solutions.html#Iterative-solver","page":"Low-rank Solutions","title":"Iterative solver","text":"","category":"section"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"Loraine uses preconditioned conjugate gradient (CG) method.","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"What can be gained:\nH assembly: lower complexity, H does not have to be stored in memory","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"- ``Hy=r`` can only be solved approximately, one CG iteration has very low complexity (matrix-vector multiplication)","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"Drawback:\t\nH getting (very) ill-conditioned, CG may need very many iterations and may not work at all","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"We need a good preconditioner!","category":"page"},{"location":"low-rank_solutions.html#Low-rank-preconditioners-for-Interior-Point-method","page":"Low-rank Solutions","title":"Low-rank preconditioners for Interior-Point method","text":"","category":"section"},{"location":"low-rank_solutions.html#Preconditioner-H_\\alpha-(preconditioner-1)","page":"Low-rank Solutions","title":"Preconditioner H_alpha (preconditioner = 1)","text":"","category":"section"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"Critical observation (due to Richard Y. Zhang and Javad Lavaei, IEEE, 2017) reveals that if the solution ``X^is low-rank thenW`` will be low-rank.*","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"Hence  W=W_0+UU^T and","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"H=cal A^T(W_0otimes W_0)cal A+cal A^T(Uotimes Z)(Uotimes Z)^Tcal A+ D^T X_rm linS^-1_rm lin D","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"This leads to the following preconditioner called H_alpha:","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"H_alpha=tau^2 I +VV^T+ D^T X_rm linS^-1_rm lin D","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"Here V = cal A^T(Uotimes Z) has low rank, so we can use Sherman-Morrison-Woodbury formula to compute H_alpha^-1.","category":"page"},{"location":"low-rank_solutions.html#Preconditioner-H_\\beta-(preconditioner-2)","page":"Low-rank Solutions","title":"Preconditioner H_beta (preconditioner = 2)","text":"","category":"section"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"In many problems, the last term in ... is dominating in the first iterations of the IP algorithm, before the low-rank structure of W is clearly recognized.","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"This observation lead to the idea of a simplified preconditioner called H_beta and defined as follows","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"beginalign*\nH_beta=tau^2 I+D^top X_textlinS_textlin^-1D\nendalign*","category":"page"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"in which tau is defined as in the previous section. This matrix is easy to invert; in fact, the matrix is diagonal in many problems. It is therefore an extremely cheap preconditioner that is efficient in the first iterations of the IP algorithm.","category":"page"},{"location":"low-rank_solutions.html#Hybrid-preconditioner-(preconditioner-4)","page":"Low-rank Solutions","title":"Hybrid preconditioner (preconditioner = 4)","text":"","category":"section"},{"location":"low-rank_solutions.html","page":"Low-rank Solutions","title":"Low-rank Solutions","text":"For relevant problems, we therefore recommend to use a hybrid preconditioner: we start the IP iterations with H_beta and, once it becomes inefficient, switch to the more expensive but more efficient H_alpha. ","category":"page"}]
}
