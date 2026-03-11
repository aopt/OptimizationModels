# solve the Ramsey model using Pyomo/ipopt

import pyomo.environ as pyo
import pandas as pd

#----------------------------------------------------------------
# data
#----------------------------------------------------------------


T = 26     # time periods (0..25)
ρ = 0.05   # discount factor
g = 0.03   # labor growth rate
δ = 0.02   # capital depreciation factor
K0 = 3.00  # initial capital
I0 = 0.05  # initial investment
C0 = 0.95  # initial consumption
L0 = 1.00  # initial labor
b = 0.25   # Cobb-Douglas coefficient
a = (C0 + I0)/ (K0**b * L0**(1-b))     # Cobb-Douglas coefficient
# print(f"{a=}")

# weight factor for future utilities
β = [(1+ρ)**(-t) for t in range(T)]
β[T-1] = (1/ρ) * (1+ρ)**(1-(T-1))

# labor is exogeneously determined using an exponential growth process
L = [(1+g)**t * L0 for t in range(T)]

#----------------------------------------------------------------
# model
#----------------------------------------------------------------

m = pyo.ConcreteModel()

# Sets
# This is a set of numbers
m.t = pyo.Set(initialize=[t for t in range(T)])

# Define variables
m.C = pyo.Var(m.t, domain=pyo.NonNegativeReals, bounds=(0.001,None),initialize=1)
m.Y = pyo.Var(m.t, domain=pyo.NonNegativeReals, initialize=1)
m.K = pyo.Var(m.t, domain=pyo.NonNegativeReals, bounds=(0.001,None),initialize=1)
m.I = pyo.Var(m.t, domain=pyo.NonNegativeReals, initialize=0.01)

# define constraints and objective

#  W =e=sum(t,beta(t)*log(C(t)));
def obj_rule(m):
    return sum(β[t]*pyo.log(m.C[t]) for t in m.t)
m.obj = pyo.Objective(rule=obj_rule, sense=pyo.maximize)

# Y(t) =e= a *(K(t)**b) * (L(t)**(1-b));
def production_rule(m,t):
    return m.Y[t] == a * (m.K[t]**b) * (L[t]**(1-b))
m.production = pyo.Constraint(m.t, rule=production_rule)

# Y(t) =e= C(t)+ I(t);
def allocation_rule(m,t):
    return m.Y[t] == m.C[t]+ m.I[t]
m.allocation = pyo.Constraint(m.t, rule=allocation_rule)

# K(t+1) =e= (1-delta)*K(t) + I(t);
def accumulation_rule(m,t):
    if (t==T-1):
        return pyo.Constraint.Skip
    return m.K[t+1] == (1-δ)*m.K[t]+ m.I[t]
m.accumulation = pyo.Constraint(m.t, rule=accumulation_rule)

# I(tlast) =g= (g+delta)*K(tlast);
def final_rule(m):
    return m.I[T-1] >= (g+δ)*m.K[T-1]
m.final = pyo.Constraint(rule=final_rule)

# fix variables
m.K[0].fix(K0)
m.I[0].fix(I0)
m.C[0].fix(C0)

# print the complete model
# this is useful for debugging, but can be commented out for large models
m.pprint()

#----------------------------------------------------------------
# solve
#----------------------------------------------------------------

# ipopt.exe is missing from conda install ipopt. This is downloaded
# from the ipopt repository on github.
ipoptexe = r'C:\Users\erwin\Downloads\Ipopt-3.14.12-win64-msvs2019-md\Ipopt-3.14.12-win64-msvs2019-md\bin\ipopt.exe'
opt = pyo.SolverFactory('ipopt',executable=ipoptexe)
res = opt.solve(m, tee=True) 

#----------------------------------------------------------------
# reporting
#----------------------------------------------------------------

results = {
    'C': [pyo.value(m.C[t]) for t in m.t],
    'Y': [pyo.value(m.Y[t]) for t in m.t],
    'K': [pyo.value(m.K[t]) for t in m.t],
    'I': [pyo.value(m.I[t]) for t in m.t]
}

df = pd.DataFrame(results, index=list(m.t))
print(df)
print(f"W={pyo.value(m.obj)}")