set
   i /i1*i100/
   j /j1*j4/
;
alias(i,k);


set n(i,k) 'neighbors';
n(i,k) = ord(k)>=ord(i)-4 and ord(k)<=ord(i)+4 and ord(i)<>ord(k);

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
mod.optfile=1;
option reslim=100;
solve mod minimizing z using miqcp;

display x.l;

$onecho > cplex.opt
qtolin 0
mipemphasis 1
$offecho


mod.optfile=2;
option reslim=1000;
solve mod minimizing z using miqcp;

$onecho > cplex.op2
qtolin 1
mipemphasis 2
cuts 4
mipstart 1
symmetry 5
$offecho
