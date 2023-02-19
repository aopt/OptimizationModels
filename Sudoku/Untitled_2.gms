set i / i1*i1000 /;
alias(i,j);

parameter a(i,j);
a(i,j) = 1 / (ord(i)+ord(j) - 1);
a(i,i) = 1;


embeddedCode Python:
import gamstransfer as gt
import numpy as np
import time

gams.printLog("")
s = time.time()
m = gt.Container(gams.db)
gams.printLog(f"read data: {round(time.time() - s, 3)} sec")

s = time.time()
A = m.data["a"].toDense()
gams.printLog(f"create matrix A: {round(time.time() - s, 3)} sec")

s = time.time()
invA = np.linalg.inv(A)
gams.printLog(f"generate inv(A): {round(time.time() - s, 3)} sec")

endEmbeddedCode