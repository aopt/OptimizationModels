$ontext

   use with cuts=5 gives a total runtime of

   --- MIQP status (102): integer optimal, tolerance.
   --- Cplex Time: 216.98sec (det. 155164.34 ticks)

   Solution satisfies tolerances
   MIP Solution:           62.444674    (1681459 iterations, 8326 nodes)
   Final Solve:            62.444674    (0 iterations)

   Best possible:          62.438838
   Absolute gap:            0.005837
   Relative gap:            0.000093

$offtext

set
   i /i1*i100/
   j /j1*j3/
;
alias(i,k);

set n(i,k) 'neighbors (about 10 neigbors for each i)';
n(i,k) = ord(k)>=ord(i)-5 and ord(k)<=ord(i)+5 and ord(i)<>ord(k);

parameter C(i);
c(i) = uniform(0,1);

binary variable x(i,j);
variable z;

equation
   obj
   e
;

obj.. z =e= sum((i,j,k)$n(i,k), c(k)*x(i,j)*x(k,j));
e(i)..  sum(j,x(i,j)) =e= 1;

option miqcp = cplex,threads=0;
model mod /all/;
solve mod minimizing z using miqcp;

display x.l;

