# 
# Julia version of the Ramsey Growth Model
#
using JuMP, Ipopt, DataFrames


#----------------------------------------------------------------
# data
#----------------------------------------------------------------

T = 26     # number of time periods (0..25)
ρ = 0.05   # discount factor
g = 0.03   # labor growth rate
δ = 0.02   # capital depreciation factor
K0 = 3.00  # initial capital
I0 = 0.05  # initial investment
C0 = 0.95  # initial consumption
L0 = 1.00  # initial labor
b = 0.25   # Cobb-Douglas coefficient
a = (C0 + I0)/ (K0^b * L0^(1-b))     # Cobb-Douglas coefficient

𝜏 = 0:T-1 # time periods 0..25

# weight factor for future utilities
β = (1+ρ).^(-𝜏)
β[T] = (1/ρ) * (1+ρ)^(1-T+1)   

# labor is exogeneously determined using an exponential growth process
L = (1+g).^𝜏 * L0

#----------------------------------------------------------------
# model
#----------------------------------------------------------------

model = Model(Ipopt.Optimizer)

# decision variables
@variable(model, K[1:T] >= 0)       # capital
@variable(model, C[1:T] >= 0.001)   # consumption
@variable(model, I[1:T] >= 0)       # investment
@variable(model, Y[1:T] >= 0.001)   # output

# fix to initial values
fix(K[1],K0;force=true)
fix(C[1],C0;force=true)
fix(I[1],I0;force=true)

# initial point
set_start_value.(K, K0)
set_start_value.(C, C0)

@objective(model,  Max, sum(β[t]*log(C[t]) for t in 1:T))
@constraint(model, production[t in 1:T],      Y[t] == a * (K[t]^b) * (L[t]^(1-b)))
@constraint(model, allocation[t in 1:T],      Y[t] == C[t] + I[t])
@constraint(model, accumulation[t in 1:T-1],  K[t+1] == (1-δ)*K[t] + I[t])
@constraint(model, final,                     I[T] >= (g + δ) * K[T])

optimize!(model)

#----------------------------------------------------------------
# reporting
#----------------------------------------------------------------

results = DataFrame(
    t = 𝜏,
    C = value.(C),
    Y = value.(Y),
    K = value.(K),
    I = value.(I)
)

println(results)

println("W: ", objective_value(model))