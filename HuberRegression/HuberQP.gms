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
   t(i)     'absolute value'
;
positive variable t;

equations
   obj
   bound1(i)
   bound2(i)
;

obj.. loss =e= 0.5*sum(i,sqr(e(i))) + k*sum(i,t(i));
bound1(i).. -t(i) =l= sum(j, X(i,j)*beta(j)) - y(i) + e(i);
bound2(i).. t(i) =g= sum(j, X(i,j)*beta(j)) - y(i) + e(i);

model m /all/;
solve m using qcp minimizing loss;

display beta.l;
