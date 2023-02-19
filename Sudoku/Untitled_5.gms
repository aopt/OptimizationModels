$ontext

   Multi-dimensional ranking

   Ranks
         x(i) => rank(i)
   or    x(i,j) => rank(i,j)

   See https://www.delftstack.com/howto/numpy/python-numpy-rank/
   for argsort(argsort) trick

$offtext

$version 390

set
  i /i1*i10/
;

alias(i,a,b,c);

parameters
  p(a,b,c), Rank(a,b,c)
;
p(a,b,c) = normal(0,1);

embeddedCode Python:
import gamstransfer as gt
import numpy as np

def rank(paramname: str,rankname: str):

   print("\n### calculating rank")

   # read GAMS data
   c = gt.Container()
   c.read(gams.db)
   p = c.data[paramname].toDense()
   shape = p.shape
   print(f"shape = {shape}")

   # ranking
   rnk = np.argsort(np.argsort(p,axis=None))+1
   rnk = np.reshape(rnk,shape)
   print(rnk)

   # pass results back to GAMS
   c.data[rankname].setRecords(rnk)
   c.write(gams.db, [rankname])

rank("p","Rank") # case sentitive!!!

endEmbeddedCode rank

option rank:0;
display$(card(p)<=1000) p, rank;



