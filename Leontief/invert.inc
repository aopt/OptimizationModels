* invert.inc
* Arguments:
*    A: input matrix
*    B: output matrix (inverse or all zero)
*    i: sets defining A and B
* if singular return a parameter with all zeros


$offlisting

embeddedCode Python:
gams.printLog("\n### invert.inc")
import numpy as np
import numpy.linalg as la
import time

t0 = time.time()

sa = "%1"  # name of A matrix
sb = "%2"  # name of B=inv(A) matrix
si = "%3"  # name of driving set

#
# load set i
#
I = list(gams.get(si,keyType=KeyType.INT))
n = len(I)
assert n>0, f">>>> set {si} has no elements"
assert isinstance(I[0],int),  f">>>> set {si} is not a 1 dim set"
imap = dict(zip(I,range(n)))  # maps gams indices -> Python indices


#
# allocate and populate matrix A
#
A = np.zeros((n,n))
try:
   for (i,j,aij) in gams.get(sa,keyType=KeyType.INT,keyFormat=KeyFormat.FLAT):
       A[imap[i],imap[j]] = aij
except:
   assert False,f">>>> Error in set elements. Check the set {si}."

t1 = time.time()-t0
gams.printLog(f".. Copied data from {si},{sa} ({t1:.1f}s)")


#
# invert
#
try:
  B = la.inv(A)
except la.LinAlgError:
  gams.printLog(".. Singular matrix. Returning zeros.")
  B = np.zeros((n,n))

t2 = time.time()-t0-t1
gams.printLog(f".. Inverted {sa} ({t2:.1f}s)")

#
# return B
#
GamsB = [((I[k[0]],I[k[1]]),v) for k,v in np.ndenumerate(B) if abs(v)>1e-9]
if len(GamsB)==0:
   GamsB = [((I[0],I[0]),0.0)]
gams.set(sb,GamsB)

t3 = time.time()-t0-t1-t2
gams.printLog(f".. Created GAMS sparse matrix {sb} ({t3:.1f}s)")

t = t1+t2+t3
gams.printLog(f".. Total elapsed {t:.1f}s")

endEmbeddedCode %2
