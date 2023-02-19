$ontext

   Matrix Balancing:
   RAS vs Entropy Optimization
   
   http://yetanothermathprogrammingconsultant.blogspot.com/2022/08/some-matrix-balancing-experiments.html

$offtext

* reduce size of listing file
option limrow=0, limcol=0, solprint=off;

*---------------------------------------------------------------
* size of the matrix
*---------------------------------------------------------------

set
   i 'rows' /r1*r1000/
   j 'columns' /c1*c1000/
;

*---------------------------------------------------------------
* random sparse data
*---------------------------------------------------------------

Set P(i,j) 'sparsity pattern';
P(i,j) = uniform(0,1)<0.5;

Parameter A0(i,j) 'inner data table';
A0(p) = uniform(0,100);

Parameter
    r(i) 'known row sums'
    c(j) 'known column sums'
;

r(i) = sum(p(i,j), A0(p));
c(j) = sum(p(i,j), A0(p));

*
* perturb A0
*
A0(p) = uniform(0.5,1.5)*A0(p);

*---------------------------------------------------------------
* RAS
*---------------------------------------------------------------

set iter 'max RAS iterations' /iter1*iter50/;
Scalars
   tol    'tolerance' /1e-6/
   niter  'iteration number'
   diff1  'max(|rho-1|)'
   diff2  'max(|sigma-1|)'
   diff   'max(diff1,diff2)'
   t      'time'
;

parameters
   A(i,j) 'updated matrix using RAS method'
   rho(i) 'row scaling'
   sigma(j) 'column scaling'
   trace(iter,*) 'RAS convergence'
;

t = timeElapsed;

A(i,j) = A0(i,j);

loop(iter,

    niter = ord(iter);

*
* step 1 row scaling
*
   rho(i) = r(i)/sum(j,A(i,j));
   A(i,j) = rho(i)*A(i,j);

*
* step 2 column scaling
*
   sigma(j) = c(j)/sum(i,A(i,j));
   A(i,j) =  A(i,j)*sigma(j);

*
* converged?
*
   diff1 = smax(i,abs(rho(i)-1));
   diff2 = smax(j,abs(sigma(j)-1));
   diff = max(diff1,diff2);
   trace(iter,'||rho-1||') = diff1;
   trace(iter,'||sigm-1||') = diff2;
   trace(iter,'||both||') = diff;

   break$(diff < tol);

);


option trace:8; display trace;
if(diff < tol,
  display "RAS converged.",niter;
else
  abort "RAS did not converge";
);

t = timeElapsed-t;

parameter report 'timings of different solvers';
report('RAS alg','obj') = sum(p,A(p)*log(A(p)/A0(p)));
report('RAS alg','iter') = niter;
report('RAS alg','time') = t;

display report;

*---------------------------------------------------------------
* Entropy Model
*---------------------------------------------------------------

variable z 'objective';
positive variable A2(i,j) 'updated table';

* initial point
A2.l(p) = A0(p);
* protect log
A2.lo(p) = 1e-5;

equations
   objective  'cross-entropy objective'
   rowsum(i)  'row totals'
   colsum(j)  'column totals'
   ;

objective.. z =e= sum(p,A2(p)*log(A2(p)/A0(p)));
rowsum(i).. sum(P(i,j), A2(p)) =e= r(i);
colsum(j).. sum(P(i,j), A2(p)) =e= c(j);

model m1 /all/;
option threads=0, nlp=conopt;
solve m1 minimizing z using nlp;

*---------------------------------------------------------------
* Compare results
* ||A2-A||
*---------------------------------------------------------------

scalar adiff 'max difference between solutions';
adiff = smax((i,j),abs(A2.l(i,j)-A(i,j)));
display adiff;

*---------------------------------------------------------------
* Try different solvers
*---------------------------------------------------------------

report('CONOPT','obj') = z.l;
report('CONOPT','iter') = m1.iterusd;
report('CONOPT','time') = m1.resusd;

A2.l(p) = 0;

option nlp=ipopt;
solve m1 minimizing z using nlp;

report('IPOPT','obj') = z.l;
report('IPOPT','iter') = m1.iterusd;
report('IPOPT','time') = m1.resusd;

A2.l(p) = 0;

option nlp=ipopth;
solve m1 minimizing z using nlp;

report('IPOPTH','obj') = z.l;
report('IPOPTH','iter') = m1.iterusd;
report('IPOPTH','time') = m1.resusd;

A2.l(p) = 0;

option nlp=knitro;
solve m1 minimizing z using nlp;

report('KNITRO','obj') = z.l;
report('KNITRO','iter') = m1.iterusd;
report('KNITRO','time') = m1.resusd;

display report;

*---------------------------------------------------------------
* for mosek we use the exponential cone
*---------------------------------------------------------------

positive variable x1(i,j);
variable x3(i,j);
a2.l(p) = 1;

equations
   expcone(i,j) 'exponential cone'
   obj2         'updated objective'
   defx1        'x1 = a0'
;


obj2.. z =e= -sum(p,x3(p));

expcone(p).. x1(p) =g= a2(p)*exp(x3(p)/a2(p));

defx1(p).. x1(p) =e= a0(p);


$onecho > mosek.opt
MSK_DPAR_INTPNT_CO_TOL_REL_GAP = 1.0e-5
$offecho

model m2 /obj2,expcone,rowsum,colsum,defx1/;
option nlp=mosek;
m2.optfile=1;
solve m2 minimizing z using nlp;

report('MOSEK','obj') = z.l;
report('MOSEK','iter') = m2.iterusd;
report('MOSEK','time') = m2.resusd;

display report;