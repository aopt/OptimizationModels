# Enumerate all optimal LP solutions

This shows how we can enumerate all optimal bases. In other words it lists all optimal
primal and dual solutions.

Files:
1.  trsnport.gms: original model (model 1 from GAMS model library)
2.  trnsportall.gms: enumerate all optimal solutions using a loop and no-good cuts
3.  trnsportallcplex.gms: enumerate all optimal solutions using the Cplex solution pool