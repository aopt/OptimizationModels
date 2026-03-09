#
# Solving the Ramsey model using scipy.optimize.minimize with the trust-constr method
# We use a class to keep all data and functions together. This allows us to use
# the model parameters in the function evaluation without the extra "args".  
#
# Optimized version:
#    Substitute out fixed variables and y[t]
#    Provide analytic gradients
#    Equality constrained version
#    Initial feasible solution
#


import numpy as np
import scipy.optimize as opt
import pandas as pd


class RamseyModel:

    #----------------------------------------------------------------
    # data
    #----------------------------------------------------------------

    T = 25     # time periods (1..25). 
    ρ = 0.05   # discount factor
    g = 0.03   # labor growth rate
    δ = 0.02   # capital depreciation factor
    K0 = 3.00  # initial capital
    I0 = 0.05  # initial investment
    C0 = 0.95  # initial consumption
    L0 = 1.00  # initial labor
    b = 0.25   # Cobb-Douglas coefficient
    a = (C0 + I0)/ (K0**b * L0**(1-b))     # Cobb-Douglas coefficient

    # time indices: 1..T 
    # we do t=0 separately (that is exogenous)
    t = np.arange(1,T+1)

    # weight factor for future utilities
    β = (1+ρ)**(-t)
    β[T-1] = (1/ρ) * (1+ρ)**(1-T)

    # labor is exogeneously determined using an exponential growth process
    L = (1+g)**t * L0

    # precompute L^(1-b)
    Lb = L**(1-b)

    #----------------------------------------------------------------
    # model
    #----------------------------------------------------------------

    # mapping of variables into a single vector x:
    # x = [C[0],...,C[T-1],K[0],...,K[T-1],I[0],...,I[T-1]]
    # note: Y is substituted out 

    # lower bounds
    C_lo = 0.001*np.ones(T)
    K_lo = 0.001*np.ones(T)
    K_lo[0] = (1-δ)*K0 + I0
    I_lo = np.zeros(T)
    # combine lower bounds into a single vector
    lo = np.concatenate((C_lo,K_lo,I_lo))

    # upper bounds
    C_up = 1000*np.ones(T) 
    K_up = 1000*np.ones(T)
    K_up[0] = (1-δ)*K0 + I0
    I_up = 1000*np.ones(T)
    # combine upper bounds into a single vector
    up = np.concatenate((C_up,K_up,I_up))
  
    # Bounds
    bounds = opt.Bounds(lo,up)

    # initial values 
    x0 = np.concatenate((C0*np.ones(T),K0*np.ones(T),I0*np.ones(T)))

    # create an initial feasible solution by iterating on the equations
    def init_feas_sol(self):
        C_init = np.zeros(self.T)
        K_init = np.zeros(self.T)
        I_init = np.zeros(self.T)
        C_init[0] = self.C0
        K_init[0] = self.K0  
        I_init[0] = self.I0
        for t in range(1,self.T):
            K_init[t] = (1-self.δ)*K_init[t-1] + I_init[t-1]
            I_init[t] = (self.g + self.δ)*K_init[t]
            y = self.a * (K_init[t]**self.b) * (self.Lb[t])
            C_init[t] = y - I_init[t]
        return np.concatenate((C_init,K_init,I_init))

    # objective function 
    # W =e=sum(t,beta(t)*log(C(t)));
    # we minimize -W
    # Note: we dropped the first period so beware when comparing objective values. 
    def f(self, x):        
        Ct = x[0:self.T] 
        return -np.dot(self.β,np.log(Ct)) 

    # production function
    # C(t)+I(t) =e= a * (K(t)**b) * (L(t)**(1-b))
    def prod(self,x):
        Ct = x[0:self.T]
        Kt = x[self.T:2*self.T]
        It = x[2*self.T:3*self.T]
        return  Ct+It - self.a*np.multiply(Kt**self.b,self.Lb)

    # capital accumulation
    # K(t+1) =e= (1-delta)*K(t) + I(t)
    # K(0)   =e= (1-delta)*K0 + I0 (this goes into the rhs, i.e. the bounds) 
    # =>          C  K   I
    #      A  = [ 0  AK  I ] 
    #      AK = (1-delta)*I - U
    #      U is the identity matrix shifted by one period, with zeros in the first column 
    #      after this drop the last row.
    #
    def A1(self):
        AC = np.zeros((self.T,self.T))
        AK = (1-self.δ)*np.identity(self.T) - np.eye(self.T,k=1)
        AI = np.identity(self.T)
        return np.concatenate((AC,AK,AI),axis=1)[:-1,:]    

    # I(tlast) =g= (g+delta)*K(tlast)
    # => I[24] - (g+delta)*K[24] >= 0
    def A2(self):
        a =  np.zeros((1,3*self.T))
        a[0,3*self.T-1] = 1
        a[0,2*self.T-1] = -(self.g + self.δ)
        return a

    def constraints(self):
        c1 = opt.NonlinearConstraint(self.prod,0,0,jac=self.jacprod)
        c2 = opt.LinearConstraint(self.A1(),0,0)
        # c3 = opt.LinearConstraint(self.A2(),0,np.inf)
        c3 = opt.LinearConstraint(self.A2(),0,0)
        return [c1,c2,c3]

    def gradobj(self,x):
        Ct = x[0:self.T]
        gradC = -self.β / Ct
        gradRest = np.zeros(2*self.T)
        return np.concatenate((gradC,gradRest))
    

    def jacprod(self,x):
        Kt = x[self.T:2*self.T]
        JacCt = np.identity(self.T)
        JacKt = np.diag(-self.a * self.b * (Kt**(self.b-1)) * (self.Lb))
        JacIt = np.identity(self.T)
        return np.concatenate((JacCt, JacKt, JacIt), axis=1)


m = RamseyModel()
x0 = m.init_feas_sol()
# solve with the trust-constr method
result = opt.minimize(m.f,x0,bounds=m.bounds,jac=m.gradobj,constraints=m.constraints(),method='trust-constr',options={'verbose':2})  
#print(result) 

#----------------------------------------------------------------
# reporting
# store results in a dataframe for reporting
# insert initial values for t=0 (exogenous)
#----------------------------------------------------------------

df = pd.DataFrame(np.reshape(result.x,(3,m.T)).T, columns=['C','K','I'])
df0 = pd.DataFrame({'C':[m.C0],'K':[m.K0],'I':[m.I0]})
df  = pd.concat((df0,df), ignore_index=True)
L = np.concatenate((np.array([m.L0]),m.L))
df['Y'] = m.a*np.multiply(df['K']**m.b,L**(1-m.b))
print()
print(df)

β = np.concatenate((np.array([1]),m.β))
W = float(np.dot(β,np.log(df['C'])))
print()
print(f"{W=}")