$ontext

   Huber M regression by NLP

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
   loss   'objective'
   e(i)   'deviations'
   beta(j)   'parameters to estimate'
;

equations
   obj
   fit(i)
;

obj.. loss =e= sum(i, ifthen(abs(e(i))<=k, sqr(e(i)), 2*k*abs(e(i))-sqr(k)));
fit(i).. y(i) =e= sum(j, X(i,j)*beta(j)) + e(i);

model m /all/;
solve m using dnlp minimizing loss;

display beta.l;
