#
# Python scipy implementation of Ramsey growth model
# This is a translation of the GAMS code in ramsey.gms
#

import numpy as np
import scipy.optimize as opt

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
print(f"{a=}")

# time indices: 0..T-1 
t = np.arange(0,T)

# weight factor for future utilities
β = (1+ρ)**(-t)
β[T-1] = (1/ρ) * (1+ρ)**(1-T+1)

# labor is exogeneously determined using an exponential growth process
L = (1+g)**t * L0


#----------------------------------------------------------------
# model
#----------------------------------------------------------------


# lower bounds
C_lo = 0.001*np.ones(T)
Y_lo = np.zeros(T)
K_lo = 0.001*np.ones(T)
I_lo = np.zeros(T)
# t=0 is fixed to the initial values
C_lo[0] = C0
K_lo[0] = K0
I_lo[0] = I0
# combine lower bounds into a single vector
lo = np.concatenate((C_lo,Y_lo,K_lo,I_lo))

# upper bounds
C_up = 1000*np.ones(T) 
Y_up = 1000*np.ones(T)
K_up = 1000*np.ones(T)
I_up = 1000*np.ones(T)
# t=0 is fixed to the initial values
C_up[0] = C0
K_up[0] = K0
I_up[0] = I0
# combine upper bounds into a single vector
up = np.concatenate((C_up,Y_up,K_up,I_up))

# initial values 
x0 = np.concatenate((C0*np.ones(T),np.ones(T),K0*np.ones(T),I0*np.ones(T)))

# extra arguments to be passed around
xargs = (a,b,β,δ,g,L,T,)

# objective function 
# W =e=sum(t,beta(t)*log(C(t)));
# minimize -W 
def f(x,a,b,β,δ,g,L,T):
    mat = np.reshape(x,(4,T))
    Ct = mat[0,] 
    fval = -np.dot(β,np.log(Ct)) 
    return fval

# Bounds
bnd = opt.Bounds(lo,up)

# Constraints

def Feq(x,a,b,β,δ,g,L,T):
    # unpack x
    mat = np.reshape(x,(4,T))    
    Ct = mat[0,]
    Yt = mat[1,] 
    Kt = mat[2,]
    It = mat[3,]

    # calc LHS - RHS = 0 for all equality constraints
    F1 = Yt - a*np.multiply(Kt**b,L**(1-b))
    F2 = Yt - (Ct+It)
    F3 = Kt[1:] - ((1-δ)*Kt[:-1]+It[:-1]) 
    return np.concatenate((F1,F2,F3))

def Fineq(x,a,b,β,δ,g,L,T):
    # unpack x
    mat = np.reshape(x,(4,T))    
    Kt = mat[2,]
    It = mat[3,]

    # calc LHS-RHS >= 0
    F4 = It[T-1] - (g+δ)*Kt[T-1]
    return F4

cons = [{'type':'eq','fun':Feq,'args':xargs},
        {'type':'ineq','fun':Fineq,'args':xargs}]

# solve
result = opt.minimize(f, x0, args=xargs, bounds=bnd, constraints=cons, 
                      method='SLSQP', options={'maxiter':1000,'disp':True})
print(result)

# This version yields:
#     message: Singular matrix C in LSQ subproblem
#     success: False

