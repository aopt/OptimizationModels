

set
  i /i1*i5/
;
alias (i,j);

parameter q(i,j);

$onEmbeddedCode Python:
import numpy as np

seti = list(gams.get("i"))

n = len(seti)
print(f"n={n}")
np.random.seed(0)
Q = np.random.uniform(-1, 1, size=(n, n))
Q = np.dot(Q.T, Q)
print(Q)

gams.set('q', [(seti[i],seti[j],Q[i,j]) for i in range(n) for j in range (n) ])
$offEmbeddedCode q

display q;


positive variable x;
x.lo(i) = 0;
x.up(i) = 1;

variable z;

equations
   obj1
   unit
;

obj1.. z =e= sum((i,j),x(i)*q(i,j)*x(j)) + 1.0e-10*sum(i,x(i)**0.1);
unit.. sum(i,x(i)) =e= 1;

model m /all/;
solve m minimizing z using nlp;

