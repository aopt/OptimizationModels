$ontext

   Huber M regression by QP

   Erwin Kalvelagen

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
   loss     'objective'
   e(i)     'deviations'
   beta(j)  'parameters to estimate'
   lambda1(i) 'slacks'
   lambda2(i) 'slacks'
;
positive variable lambda1,lambda2;

equations
   obj
   con
;

obj.. loss =e= 0.5*sum(i,sqr(e(i))) + k*sum(i,lambda1(i)+lambda2(i));
con(i).. e(i) - sum(j, X(i,j)*beta(j)) + y(i) + lambda2(i) - lambda1(i) =e= 0;

model m /all/;
solve m using qcp minimizing loss;

display beta.l;
