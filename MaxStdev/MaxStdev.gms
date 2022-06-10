$ontext

    Maximize Standard Deviation of a vector x(i) subject to bounds
    and a linear side constraint.

    This is a nonconvex problem. 

    We have the following models:
    1. Nonconvex QP
    2. Linear approximation using SOS1 variables. This is a problematic model.
    3. As 2. but with a bound on the objective.
    4. Linear approximation using binary variables.

$offtext

*------------------------------------------------------------------
* data
*------------------------------------------------------------------

set i /i1*i30/;

scalars
   lo / 0.5 /
   up / 3 /
   range
;
range = up-lo;
   
parameter a(i) 'coefficients of constraint';
a(i) = uniform(0,2);


*------------------------------------------------------------------
* reporting macros
*------------------------------------------------------------------

parameter results(*,*);

acronym Optimal;
acronym TimeLimit;

* macros for reporting
$macro stdev      sqrt(sum(i,sqr(x.l(i)-mu.l))/(card(i)-1))
$macro report(m,label)  \
    results(i,label) = x.l(i); \
    results('status',label)= m.solvestat; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('status',label)$(m.solvestat=3) = TimeLimit; \
    results('obj',label) = z.l; \
    results('mu',label) = mu.l; \
    results('stdev',label) = stdev; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd; \
    display results;




*------------------------------------------------------------------
* non-convex QP model
*------------------------------------------------------------------


positive variable x(i);
x.lo(i) = lo;
x.up(i) = up;

variable
  z 'obj'
  mu 'mean'
;

Equations
   e     'side constraint'
   obj   'objective'
   mean  'average'
;

e.. sum(i,a(i)*x(i)) =e= card(i);
mean.. mu =e= sum(i,x(i))/card(i);

obj.. z =e= sum(i, sqr(x(i)-mu));

model m1 /all/;
option qcp=cplex,threads=0;
m1.optfile=1;
solve m1 maximizing z using qcp;


$onecho > cplex.opt
OptimalityTarget=3
$offecho


report(m1,'GlobalQP')


*------------------------------------------------------------------
* SOS1 based model
*------------------------------------------------------------------

option reslim=1000;

set pm /'+','-'/;
sos1 variable s(i,pm);

equations
   split
   obj2
;

split(i).. s(i,'+')-s(i,'-') =e= x(i)-mu;
obj2.. z =e= sum((i,pm),s(i,pm));

model m2 /split,obj2,e,mean/;
solve m2 maximizing z using mip;

report(m2,'SOS1')

*------------------------------------------------------------------
* SOS1 with bound on the objective variable
*------------------------------------------------------------------

z.up = range*card(i);
solve m2 maximizing z using mip;

report(m2,'SOS1/bnd')

z.up = INF;

*------------------------------------------------------------------
* model using binary variables
*------------------------------------------------------------------

positive variable s2(i,pm);
binary variable b(i);

Equations
   split2a
   split2b
   split2c
   obj3
   ;
   
split2a(i).. s2(i,'+')-s2(i,'-') =e= x(i)-mu;
split2b(i).. s2(i,'+') =l= b(i)*range;
split2c(i).. s2(i,'-') =l= (1-b(i))*range;
obj3.. z =e= sum((i,pm),s2(i,pm));

model m3 /split2a,split2b,split2c,obj3,e,mean/;
solve m3 maximizing z using mip;

report(m3,'Binary')
