#
# Solving the Ramsey model using scipy.optimize.minimize with the trust-constr method
# We use a class to keep all data and functions together. This allows us to use
# the model parameters in the function evaluation without the extra "args".  
#
# This method works but is rather slow.
#

import numpy as np
import scipy.optimize as opt
import pandas as pd


class RamseyModel:

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

    # mapping of variables into a single vector x:
    # x = [C[0],...,C[T-1],Y[0],...,Y[T-1],K[0],...,K[T-1],I[0],...,I[T-1]]
    # luckily this very regular. In more complicated models, we would need to keep 
    # track of the mapping between variables and their position in x.

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

    bounds = opt.Bounds(lo,up)

    # initial values 
    x0 = np.concatenate((C0*np.ones(T),np.ones(T),K0*np.ones(T),I0*np.ones(T)))

    # objective function 
    # W =e=sum(t,beta(t)*log(C(t)));
    # minimize -W 
    def f(self,x):
        mat = np.reshape(x,(4,self.T))
        Ct = mat[0,] 
        fval = -np.dot(self.β,np.log(Ct)) 
        return fval
    
    # production function
    # Y(t)=e= a * (K(t)**b) * (L(t)**(1-b))
    def prod(self,x):
        mat = np.reshape(x,(4,self.T))
        Yt = mat[1,] 
        Kt = mat[2,]
        F1 = Yt - self.a*np.multiply(Kt**self.b,self.L**(1-self.b))
        return F1
    
    # sub matrix for identity
    # Y(t) =e= C(t) + I(t)
    # =>          C  Y  K  I
    #      A1 = [ I -I  0  I ] 
    def A1(self):        
        AC = np.identity(self.T)
        AY = -np.identity(self.T)
        AK = np.zeros((self.T,self.T))
        AI = np.identity(self.T)
        return np.concatenate((AC,AY,AK,AI),axis=1)
    
    # capital accumulation
    # K(t+1) =e= (1-delta)*K(t) + I(t)
    # =>          C  Y  K   I
    #      A2 = [ 0  0  AK  I ] and drop last row
    #      AK = (1-delta)*I - U
    #      U is the identity matrix shifted by one period, with zeros in the first column 
    def A2(self):
        AC = np.zeros((self.T,self.T))
        AY = np.zeros((self.T,self.T))
        AK = (1-self.δ)*np.identity(self.T) - np.eye(self.T,k=1)
        AI = np.identity(self.T)
        return np.concatenate((AC,AY,AK,AI),axis=1)[:-1,:]
    
    # I(tlast) =g= (g+delta)*K(tlast)
    # => I[25] - (g+delta)*K[25] >= 0
    def A3(self):
        a =  np.zeros((1,4*self.T))
        a[0,3*self.T + self.T-1] = 1
        a[0,2*self.T + self.T-1] = -(self.g + self.δ)
        return a
    
    def constraints(self):
        c1 = opt.NonlinearConstraint(self.prod,0,0)
        c2 = opt.LinearConstraint(self.A1(),0,0)
        c3 = opt.LinearConstraint(self.A2(),0,0)
        c4 = opt.LinearConstraint(self.A3(),0,np.inf)
        return [c1,c2,c3,c4]
    

m = RamseyModel()

# solve with the trust-constr method
result = opt.minimize(m.f,m.x0,bounds=m.bounds,constraints=m.constraints(),method='trust-constr',options={'verbose':2})  
#print(result) 

'''
`gtol` termination condition is satisfied.
Number of iterations: 297, function evaluations: 30345, CG iterations: 832, optimality: 3.42e-09, constraint violation: 4.33e-10, execution time:  4.8 s.
'''

#----------------------------------------------------------------
# reporting
# store results in a dataframe for reporting
#----------------------------------------------------------------

df = pd.DataFrame(np.reshape(result.x,(4,m.T)).T, columns=['C','Y','K','I'])
print()
print(df)

W = float(np.dot(m.β,np.log(df['C'])))
print()
print(f"{W=}")