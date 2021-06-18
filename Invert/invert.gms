$ontext

   Invert.gms

   Invert a matrix as LP problem.
   The second version is optimized.

   See:
   http://yetanothermathprogrammingconsultant.blogspot.com/2021/04/inverting-matrix-by-lp.html

   erwin@amsterdamoptimization.com


$offtext


*---------------------------------------------------------
* data
*   ident: identity matrix
*   A    : minij matrix
*---------------------------------------------------------

set i /i1*i200/;
alias(i,j,k);


parameters
  A(i,j)     'minij matrix'
  ident(i,j) 'identity matrix'
;
A(i,j) = min(ord(i),ord(j));
display$(card(i)<25) A;

ident(i,i) = 1;


*---------------------------------------------------------
* standard approach
*---------------------------------------------------------

variables
   Ainv(j,i) 'inverse'
   z         'dummy objective'
;

equations
   obj
   matmul(i,j)  'A*Ainv = I'
;

obj.. z =e= 1;

matmul(i,j)..
    sum(k,A(i,k)*Ainv(k,j)) =e= ident(i,j);

model m1 /all/;
option limrow=0,limcol=0,solprint=off;
solve m1 minimizing z using lp;
display$(card(i)<25) Ainv.l;

parameter err(i,j) 'errors';
err(i,j) =  sum(k,A(i,k)*Ainv.l(k,j)) - ident(i,j);
display$(card(i)<25) err;

scalar maxerr 'maximum absolute error';
maxerr = smax((i,j), abs(err(i,j)));
display maxerr;

parameter statistics(*,*);
statistics('generation','default') = m1.resgen;
statistics('solver','default') = m1.resusd;
statistics('iterations','default') = m1.iterusd;
statistics('maxerr','default') = maxerr;
display statistics;


*---------------------------------------------------------
* optimized approach
*---------------------------------------------------------

equations matmul2(i,j) 'faster version';

matmul2(i,j)..
    sum(k,A(i,k)*Ainv(j,k)) =e= ident(i,j);


* advanced basis

* basic
Ainv.m(i,j) = 0;
z.m = 0;
* non-basic
matmul2.m(i,j) = 1;
obj.m = 1;
option bratio=0;

model m2 /obj,matmul2/;
m2.optfile=1;
solve m2 minimizing z using lp;
display$(card(i)<25) Ainv.l;


err(i,j) =  sum(k,A(i,k)*Ainv.l(k,j)) - ident(i,j);
display$(card(i)<25) err;

maxerr = smax((i,j), abs(err(i,j)));
display maxerr;

statistics('generation','optimized') = m2.resgen;
statistics('solver','optimized') = m2.resusd;
statistics('iterations','optimized') = m2.iterusd;
statistics('maxerr','optimized') = maxerr;
display statistics;



$onecho > cplex.opt
preind = 0
advind = 1
$offecho