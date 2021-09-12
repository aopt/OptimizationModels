$ontext

   Huber M regression by LCP

   erwin@amsterdamoptimization.com

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
   lambda(i)  'lagrange multipliers'
   beta(j)    'parameters to estimate'
   sp(i)      'slacks'
   sm(i)      'slacks'
;
positive variables sp,sm;

equations
   e1(i)
   e2(j)
   compl1(i)
   compl2(i)
;

e1(i).. lambda(i)  + y(i) - sum(j, X(i,j)*beta(j)) =e=  sp(i) - sm(i);
e2(j).. sum(i, X(i,j)*lambda(i)) =e= 0;
compl1(i).. lambda(i) + k =g= 0;
compl2(i).. -lambda(i) + k =g= 0;

model m /e1,e2,compl1.sp,compl2.sm/;
solve m using mcp;

display beta.l;
