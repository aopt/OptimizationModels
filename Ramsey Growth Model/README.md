
# Implement Ramsey Optimal Growth model in different environments

See: https://yetanothermathprogrammingconsultant.blogspot.com/2026/03/experience-with-nlp-solvers-on-simple.html

| Files | Description |
|-------| ----------- |
| `ramsey.gms`, `ramsey.log`, `ramsey.lst` | Original GAMS model |
| `ramsey1.py`, `ramsey1.output` | Python, scipy, SLSQP, fails |
| `ramsey2.py`, `ramsey2.output` | Python, scipy, SLSQP, success |
| `ramsey3.py`, `ramsey3.output` | Python, scipy, trust region, success but very slow |
| `ramsey4.py`, `ramsey4.output` | Python, scipy, trust region, faster |
| `ramsey5.py`, `ramsey5.output` | Python, Pyomo, IPOPT |
| `ramsey6.py`, `ramsey6.output` | Python, Pyomo, IPOPT with decorators |
| `ramsey.R`, `R.output` | R, auglag |
| `ramsey.jl`, `julia.output` | Julia, JuMP, IPOPT |


