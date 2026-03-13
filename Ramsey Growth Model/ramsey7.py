import sys
import gamspy as gp

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

m=gp.Container()

t = gp.Set(m,name="t",records = ["period"+str(t) for t in range(T)])
data = gp.Parameter(m,name="data",domain=[t,"*"],records=   
                         [("period"+str(t),"L",L[t]) for t in range(T)] 
                       + [("period"+str(t),"beta",β[t]) for t in range(T)])

C = gp.Variable(m,domain=t,description="Consumption")
Y = gp.Variable(m,name="Y",domain=t,description="Output")
K = gp.Variable(m,name="K",domain=t,description="Capital")
I = gp.Variable(m,name="I",domain=t,description="Investment")
W = gp.Variable(m,name="W",description="Utility")

C.lo[t] = 0.001
K.lo[t] = 0.001
Y.lo[t] = 0
I.lo[t] = 0

C.fx["period0"] = C0
K.fx["period0"] = K0    
I.fx["period0"] = I0

production = gp.Equation(m,name="production",domain=t,description='Cobb-Douglas production function')
allocation = gp.Equation(m,name="allocation",domain=t,description='household chooses between consumption and saving')
accumulation = gp.Equation(m,name="accumulation",domain=t,description='capital accumulation')
utility = gp.Equation(m,name="utility",description='discounted utility')
final = gp.Equation(m,name="final",domain=t,description='minimal investment in final period')

utility[...]  =                         W == gp.Sum(t,data[t,"beta"]*gp.math.log(C[t]))
production[t] =                         Y[t] == a * (K[t]**b) * (data[t,"L"]**(1-b))
allocation[t] =                         Y[t] == C[t] + I[t]
accumulation[t].where[gp.Ord(t) < T] =  K[t+1] == (1-δ)*K[t] + I[t]
final[t].where[gp.Ord(t) == T] =        I[t] >= (g+δ)*K[t]

model = gp.Model(m,equations=[utility,production,allocation,accumulation,final],
                 objective=W,sense=gp.Sense.MAX,problem=gp.Problem.NLP)

summary = model.solve()
print(summary)


#----------------------------------------------------------------
# reporting
#----------------------------------------------------------------

results = gp.Parameter(m,name="results",domain=[t,"*"])
results[t,"C"] = C[t]
results[t,"Y"] = Y[t]    
results[t,"K"] = K[t]
results[t,"I"] = I[t]
print("")
print(results.pivot().round(3))
w = W.records.at[0,"level"]
print(f"W={w}")
