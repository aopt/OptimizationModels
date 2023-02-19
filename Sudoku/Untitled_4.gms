$ontext

   Multi-dimensional ranking

   Ranks x(i,j) => rank(i,j)

   See https://www.delftstack.com/howto/numpy/python-numpy-rank/
   for argsort(argsort) trick

$offtext

$version 390

set
  i /i1*i10/
  j /j1*j10/
;

parameter x(i,j),rank(i,j);
x(i,j) = normal(0,1);


embeddedCode Python:
import gamstransfer as gt
import numpy as np

print("\n### calculating rank")

# read GAMS data
c = gt.Container()
c.read(gams.db, symbols=["i","j","x","rank"])
ni = c.data["i"].number_records;
nj = c.data["j"].number_records;
x = c.data["x"].toDense()
y = np.reshape(x,ni*nj)
print(f"len(x) = {len(y)}")

# ranking
yrank = np.argsort(np.argsort(y))+1
print(yrank)
xrank = np.reshape(yrank,(ni,nj))


# pass results back to GAMS
c.data["rank"].setRecords(xrank)
c.write(gams.db, ["rank"])

endEmbeddedCode rank

option rank:0;
display$(card(x)<=100) x, rank;



