$ontext

 leontief.inc

 Calculate the leontief inverse.

 Arguments:
   %1 : input matrix: square matrix with technological coefficients
   %2 : output matrix: Leontief matrix
   %3 : sets defining A and L
        can have 1 or multiple dimensions

$offtext

$offlisting

embeddedCode Python:

gams.printLog("\n### leontief.inc")
import numpy as np
import numpy.linalg as la
import scipy.sparse as sp
import time

TRACE = True

# arguments
sA = "%1"
sL = "%2"
sI = "%3"

t0 = time.time()

#
#  load set I
#
if TRACE: gams.printLog(f".. load set {sI}")
gmsI = list(gams.get(sI,keyType=KeyType.INT))
if TRACE: gams.printLog(f".... {gmsI[0:5]} (max 5 shown)")

#
#  get size and dimension
#
n = len(gmsI)
if TRACE: gams.printLog(f".. size of matrices=({n}x{n})")
assert n>0
if isinstance(gmsI[0],int):
   dim = 1
else:
   dim = len(gmsI[0])
if TRACE: gams.printLog(f".. dim={dim} (dimension of row and column indices)")

#
#  load matrix
#
gams.printLog(f".. load parameter {sA}")
gmsA = list(gams.get(sA,keyType=KeyType.INT,keyFormat=KeyFormat.FLAT))
if TRACE: gams.printLog(f".... {gmsA[0:3]} (max 3 shown)")

t1 = time.time()-t0
gams.printLog(f".. loaded gams data {sI},{sA} ({t1:.1f}s)")


#
#  convert gmsA into something we can actually use
#

# set up dict for indices that maps GAMS numbers to Python indices
imap = dict(zip(gmsI,range(len(gmsI))))

# set up matrix.
gmsA2 = list(zip(*gmsA)) # unzip
try:
  if dim==1:
    irow = [imap[k] for k in gmsA2[0]]
    jcol = [imap[k] for k in gmsA2[1]]
    aij  =  list(a2[2])
  else:
    irow = [imap[kk] for kk in zip(*[gmsA2[k] for k in range(dim)])]
    jcol = [imap[kk] for kk in zip(*[gmsA2[k] for k in range(dim,2*dim)])]
    aij  = list(gmsA2[2*dim])
except:
   gams.printLog(f">>>> Some indices are not in {sI}. Check the set {sI}.")
   raise ValueError()

# create a dense numpy matrix I-A
npIA = np.eye(n) - sp.coo_matrix((aij,(irow,jcol)),shape=(n,n)).toarray()

t2 = time.time()-t0-t1
gams.printLog(f".. Created matrix I-{sA} ({t2:.1f}s)")

#
# invert I-A
#
try:
  invIA = la.inv(npIA)
except la.LinAlgError:
  gams.printLog(".. Singular matrix. Returning empty matrix.")
  invIA = np.zeros_like(npIA)

t3 = time.time()-t0-t1-t2
gams.printLog(f".. Inverted matrix I-{sA} ({t3:.1f}s)")

#
# return inv(I-A)
#
if dim==1:
   listL = [((gmsI[i1],gmsI[j1]),invIA[i1,j1]) for i1 in range(n) for j1 in range(n)]
else:
   listL = [(tuple(gmsI[i1]+gmsI[j1]),invIA[i1,j1]) for i1 in range(n) for j1 in range(n)]

gams.set(sL,listL)

t4 = time.time()-t0-t1-t2-t3
gams.printLog(f".. Created matrix {sL} ({t4:.1f}s)")


t = time.time()-t0
gams.printLog(f".. elapsed {t:.1f}s")


endEmbeddedCode %2

