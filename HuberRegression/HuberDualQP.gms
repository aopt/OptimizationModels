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
   u(i)     'duals'
;

equations
   obj
   edual(j)
;

obj.. loss =e= (k/2)*sum(i,sqr(u(i))) + sum(i, y(i)*u(i));
edual(j).. sum(i, X(i,j)*u(i)) =e= 0;

u.lo(i) = -1;
u.up(i) = 1;

model m /all/;
solve m using qcp minimizing loss;

display edual.m;
