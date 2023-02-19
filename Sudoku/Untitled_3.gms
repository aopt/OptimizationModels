set i / i1*i10 /;
alias(i,j);

parameter a(i,j);
a(i,j) = 1 / (ord(i)+ord(j) - 1);
a(i,i) = 1;

parameter inv_a(i,j);
parameter ident(i,j);

embeddedCode Python:
import gamstransfer as gt
import numpy as np
import time

gams.printLog("")
gams.printLog("")

s = time.time()
m = gt.Container(gams.db)
gams.printLog(f"read data: {round(time.time() - s, 3)} sec")

s = time.time()
A = m.data["a"].toDense()
gams.printLog(f"create matrix A: {round(time.time() - s, 3)} sec")

s = time.time()
invA = np.linalg.inv(A)
gams.printLog(f"calculate inv(A): {round(time.time() - s, 3)} sec")

s = time.time()
m.data["inv_a"].setRecords(invA)
gams.printLog(f"convert matrix to records for inv(A): {round(time.time() - s, 3)} sec")

s = time.time()
I = np.dot(A,invA)
tol = 1e-9
I[np.where((I<tol) & (I>-tol))] = 0
gams.printLog(f"calculate A*invA + small number cleanup: {round(time.time() - s, 3)} sec")

s = time.time()
m.data["ident"].setRecords(I)
gams.printLog(f"convert matrix to records for I: {round(time.time() - s, 3)} sec")

s = time.time()
m.write(gams.db, ["inv_a","ident"])
gams.printLog(f"write to GamsDatabase: {round(time.time() - s, 3)} sec")

gams.printLog("")
endEmbeddedCode inv_a, ident

display ident;