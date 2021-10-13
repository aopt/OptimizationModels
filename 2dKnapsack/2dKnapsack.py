#---------------------------------------------------
# 2d knapsak proble,


from ortools.sat.python import cp_model
from io import StringIO
import pandas as pd
import numpy as np

#---------------------------------------------------
# data 
#---------------------------------------------------

data = '''
item         width    height available    value   
k1             20       4       2        338.984  
k2             12      17       6        849.246  
k3             20      12       2        524.022  
k4             16       7       9        263.303  
k5              3       6       3        113.436  
k6             13       5       3        551.072  
k7              4       7       6         86.166  
k8              6      18       8        755.094  
k9             14       2       7        223.516  
k10             9      11       5        369.560  
'''

df = pd.read_table(StringIO(data),sep='\s+')
print(df)

H = 20
W = 30


#---------------------------------------------------
# derived data  
# expand to individual items
#---------------------------------------------------


w0 = df['width'].to_numpy()
h0 = df['height'].to_numpy()
a0 = df['available'].to_numpy()
v0 = df['value'].to_numpy()
indx0 = np.arange(np.size(w0))

w = np.repeat(w0,a0)
h = np.repeat(h0,a0)
v = np.repeat(v0,a0)
indx = np.repeat(indx0,a0)

n = len(w)
print(f"Number of individual items: {n}")

#---------------------------------------------------
# create rotated items  
# by duplicating
#---------------------------------------------------

wr = np.concatenate((w,h))
hr = np.concatenate((h,w))
vr = np.concatenate((v,v))
vr = (vr*1000.0).astype('int')  # scale values to become integers
indxr = np.concatenate((indx,indx))

nr = 2*n
print(f"Number of individual items (adding rotations): {nr}")

#---------------------------------------------------
# or-tools model 
#---------------------------------------------------

model = cp_model.CpModel()


#---------------------------------------------------
# variables
#---------------------------------------------------


# u[i] : item i is used
u = [ model.NewBoolVar(f"u{i}") for i in range(nr) ]

# x[i],y[i] : location of item i
x = [ model.NewIntVar(0,W,f"x{i}") for i in range(nr) ]
y = [ model.NewIntVar(0,H,f"y{i}") for i in range(nr) ]

# xw[i],yh[i] : width/height item i
xw = [ model.NewIntVar(0,int(wr[i]),f"xw{i}") for i in range(nr) ]
yh = [ model.NewIntVar(0,int(hr[i]),f"yh{i}") for i in range(nr) ]


# x2[i],y2[i] : upper limit of interval variable
x2 = [ model.NewIntVar(0,W,f"x2{i}") for i in range(nr) ]
y2 = [ model.NewIntVar(0,H,f"y2{i}") for i in range(nr) ]

# interval variables 
xival = [ model.NewIntervalVar(x[i],xw[i],x2[i],f"xival{i}") for i in range(nr) ]
yival = [ model.NewIntervalVar(y[i],yh[i],y2[i],f"yival{i}") for i in range(nr) ]
                               

#---------------------------------------------------
# constraints
#---------------------------------------------------

# The meain idea here is: if an item is not selected, make its
# height and width zero.

# u[i] = 0  ==> xw[i]=yh[i]=0  
# u[i] = 1  ==> xw[i]=hr[i],yh[i]=wr[i]   
for i in range(nr):
  model.Add(xw[i]==wr[i]*u[i])
  model.Add(yh[i]==hr[i]*u[i])

# only one of non-rotated/rotated pair can be used
for i in range(n):
    model.Add(u[i]+u[i+n]<=1)

# no overlap.
model.AddNoOverlap2D(xival,yival)

# extra:
model.Add(sum([wr[i]*hr[i]*u[i] for i in range(nr)])<=W*H)

# objective
model.Maximize(sum([u[i]*vr[i] for i in range(nr)]))


#---------------------------------------------------
# solve model
#---------------------------------------------------

solver = cp_model.CpSolver()
# log does not work inside a Jupyter notebook
solver.parameters.log_search_progress = True
solver.parameters.num_search_workers = 8
rc = solver.Solve(model)
print(f"return code:{rc}")
print(f"status:{solver.StatusName()}")
if rc != 4:
    raise


#---------------------------------------------------
# report solution
#---------------------------------------------------

used = {i for i in range(nr) if solver.Value(u[i]) == 1 }
dfout = pd.DataFrame({ 
     'x'      : [solver.Value(x[i]) for i in used],
     'y'      : [solver.Value(y[i]) for i in used],
     'w'      : [wr[i] for i in used],
     'h'      : [hr[i] for i in used],
     'x2'     : [solver.Value(x2[i]) for i in used],
     'y2'     : [solver.Value(y2[i]) for i in used],
     'value'  : [vr[i] for i in used],
     'id'     : [df['item'][indxr[i]] for i in used]
      })
print(dfout)