$ontext

   Huber M regression by LCP

   Erwin Kalvelagen, november 2001

$offtext

set i 'number of cases' /i1*i40/;
set j 'coefficient to estimate' /'constant','coeff1'/;

$include expdata.inc


parameter y(i);
y(i) = data(i,'expenditure');

parameter X(i,j);
X(i,'constant') = 1;
X(i,'coeff1') = data(i,'income');

scalar k /1.5/;

variables
   w(i)       'lagrange multipliers'
   beta(j)    'parameters to estimate'
   lambda1(i) 'slacks'
   lambda2(i) 'slacks'
;
positive variables lambda1, lambda2;

equations
   e1(i)
   e2(j)
   compl1(i)
   compl2(i)
;

e1(i).. w(i) - sum(j, X(i,j)*beta(j)) + y(i) + lambda2(i) - lambda1(i) =e= 0;
e2(j).. sum(i, X(i,j)*w(i)) =e= 0;
compl1(i).. w(i) + k =g= 0;
compl2(i).. -w(i) + k =g= 0;

model m /e1,e2,compl1.lambda1,compl2.lambda2/;
solve m using mcp;

display beta.l;
