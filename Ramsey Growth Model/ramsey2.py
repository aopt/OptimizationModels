#
# Python scipy implementation of Ramsey growth model
# This is a translation of the GAMS code in ramsey.gms
#
# version 2: presolve model ourselves.
#  - substitute out Y[t]
#  - remove fixed variables from model


import numpy as np
import scipy.optimize as opt
import pandas as pd

#----------------------------------------------------------------
# data
#----------------------------------------------------------------

T = 25     # time periods (1..25)
ρ = 0.05   # discount factor
g = 0.03   # labor growth rate
δ = 0.02   # capital depreciation factor
C0 = 0.95  # initial consumption
K0 = 3.00  # initial capital
I0 = 0.05  # initial investment
L0 = 1.00  # initial labor
b = 0.25   # Cobb-Douglas coefficient
a = (C0 + I0)/ (K0**b * L0**(1-b))     # Cobb-Douglas coefficient
print(f"{a=}")

# time indices: 1..T 
# we do t=0 separately (that is exogenous)
t = np.arange(1,T+1)

# weight factor for future utilities
β = (1+ρ)**(-t)
β[T-1] = (1/ρ) * (1+ρ)**(1-T)

# labor is exogeneously determined using an exponential growth process
L = (1+g)**t * L0

#----------------------------------------------------------------
# model
#----------------------------------------------------------------


# lower bounds
C_lo = 0.001*np.ones(T)
K_lo = 0.001*np.ones(T)
I_lo = np.zeros(T)
# combine lower bounds into a single vector
lo = np.concatenate((C_lo,K_lo,I_lo))

# upper bounds
C_up = 1000*np.ones(T) 
K_up = 1000*np.ones(T)
I_up = 1000*np.ones(T)
# combine upper bounds into a single vector
up = np.concatenate((C_up,K_up,I_up))

# initial values 
x0 = np.concatenate((C0*np.ones(T),K0*np.ones(T),I0*np.ones(T)))

# extra arguments to be passed around
xargs = (a,b,β,δ,g,L,K0,I0,T,)

# objective function 
# W =e=sum(t,beta(t)*log(C(t)));
# minimize -W 
def f(x,a,b,β,δ,g,L,K0,I0,T):
    mat = np.reshape(x,(3,T))
    Ct = mat[0,] 
    fval = -np.dot(β,np.log(Ct)) 
    return fval

# Bounds
bnd = opt.Bounds(lo,up)

# Constraints
def Feq(x,a,b,β,δ,g,L,K0,I0,T):
    # unpack x
    mat = np.reshape(x,(3,T)) #    
    Ct = mat[0,]
    Kt = mat[1,]
    It = mat[2,]

    # calc LHS - RHS = 0 for all equality constraints
    F1 = a*np.multiply(Kt**b,L**(1-b)) - (Ct+It)
    F2 = Kt[1:] - ((1-δ)*Kt[:-1]+It[:-1]) 
    F3 = Kt[0] - ((1-δ)*K0+I0)
    return np.concatenate((F1,F2,[F3]))

def Fineq(x,a,b,β,δ,g,L,K0,I0,T):
    # unpack x
    mat = np.reshape(x,(3,T))    
    Kt = mat[1,]
    It = mat[2,]

    # calc LHS-RHS >= 0
    F = It[T-1] - (g+δ)*Kt[T-1]
    return F

cons = [{'type':'eq','fun':Feq,'args':xargs},
        {'type':'ineq','fun':Fineq,'args':xargs}]

# solve
result = opt.minimize(f, x0, args=xargs, bounds=bnd, constraints=cons, 
                      method='SLSQP', options={'maxiter':1000,'disp':True})
# print(result)

""" 
Optimization terminated successfully    (Exit mode 0)
            Current function value: -5.504718231397155
            Iterations: 32
            Function evaluations: 2433
            Gradient evaluations: 32
"""

#----------------------------------------------------------------
# reporting
#----------------------------------------------------------------

df = pd.DataFrame(np.reshape(result.x,(3,T)).T, columns=['C','K','I'])
df0 = pd.DataFrame({'C':[C0],'K':[K0],'I':[I0]})
df  = pd.concat((df0,df), ignore_index=True)
L = np.concatenate((np.array([L0]),L))
df['Y'] = a*np.multiply(df['K']**b,L**(1-b))
print()
print(df)

β = np.concatenate((np.array([1]),β))
W = float(np.dot(β,np.log(df['C'])))
print()
print(f"{W=}")