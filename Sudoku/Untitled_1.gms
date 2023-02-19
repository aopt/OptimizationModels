$version 390

set i /i1*i10/;
*set i /i1*i10000000/;

parameter x(i),rank(i);
x(i) = normal(0,1);


embeddedCode Python:
import gamstransfer as gt
import numpy as np

print("\n### calculating rank")

# read GAMS data
c = gt.Container()
c.read(gams.db, symbols=["i","x","rank"])
x = c.data["x"].toDense()
print(f"len(x) = {len(x)}")

# ranking
rank = np.argsort(np.argsort(x))+1
print(rank)

# pass results back to GAMS
c.data["rank"].setRecords(rank)
c.write(gams.db, ["rank"])

endEmbeddedCode rank

option rank:0;
display$(card(x)<50) x, rank;

parameter res(i,*);
res(i,'x') = x(i);
res(i,'rank') = rank(i);
display$(card(x)<50) res;
