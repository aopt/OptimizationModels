$ontext


   Arrange points on a line such that minimum distance between points
   is maximized. Each point has a valid interval where it can be placed.
   These intervals may overlap.

   Random data set with 50 points.

   Implement three different models:
     1. MINLP model
     2. MIP model using binary variables
     3. MIP model using SOS1 variables


   All models are solved in two ways (w/o and with fixing)

   https://yetanothermathprogrammingconsultant.blogspot.com/2021/06/arranging-points-on-line.html

   erwin@amsterdamoptimization.com


$offtext

*--------------------------------------------------
* data
*--------------------------------------------------

set
 i 'points' /i1*i50/
 b 'bounds' /lo,up/
;

parameter bounds(i,b) 'ranges';
bounds(i,'lo') = uniform(0,80);
bounds(i,'up') = bounds(i,'lo') + uniform(0,15);

option bounds:3:0:6;
display bounds;

*-------------------------------------------------------
* reporting macros
*-------------------------------------------------------

acronym TimeLimit;
acronym Optimal;
acronym Error;

parameter results(*,*);
$macro report(m,label,isfixed)  \
    results('points',label) = card(i); \
    results('vars',label) = m.numVar; \
    results('  discr',label) = m.numDVar; \
    results('  fixed',label)$isfixed  = card(fix0)+card(fix1); \
    results('equs',label) = m.numEqu; \
    results('status',label) = Error; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('status',label)$(m.solvestat=3) = TimeLimit; \
    results('obj',label) = z.l; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd; \
    results('gap%',label)$(m.solvestat=3) = 100*abs(m.objest - m.objval)/abs(m.objest);


*--------------------------------------------------
* MINLP model
*--------------------------------------------------

alias(i,j);
variable
   x(i)         'location'
   delta(i,j)   'binary variable'
   z
;
binary variable delta;

x.lo(i) = bounds(i,'lo');
x.up(i) = bounds(i,'up');
z.lo = 0;

* what can we fix?
sets
   gt(i,j)
   fix0(i,j)
   fix1(i,j)
;
gt(i,j) = ord(i)>ord(j);
fix0(gt(i,j)) = bounds(j,'lo')>bounds(i,'up');
fix1(gt(i,j)) = bounds(i,'lo')>bounds(j,'up');


parameter fixed(*) 'statistics on fixed variables';
fixed('total') = card(gt);
fixed('fixed(0)') = card(fix0);
fixed('fixed(1)') = card(fix1);
fixed('unfixed') = card(gt)-card(fix0)-card(fix1);
option fixed:0;
display fixed;

equations dist(i,j);

dist(gt(i,j)).. z =l= delta(i,j)*(x(i)-x(j)) + (1-delta(i,j))*(x(j)-x(i));

model m1 /dist/;
option optcr=0, minlp=baron, threads=8, reslim=1000;
solve m1 maximizing z using minlp;

report(m1,'MINLP',0)
display results;


* remove solution
delta.l(gt) = 0;
x.l(i) = 0;

* and fix viariables
delta.fx(fix0) = 0;
delta.fx(fix1) = 1;

solve m1 maximizing z using minlp;

report(m1,'MINLP/FX',1)
display results;

*unfix for next model
delta.lo(gt) = 0;
delta.up(gt) = 1;


*--------------------------------------------------
* MIP model
*--------------------------------------------------

parameter M(i,j) 'big-M';
M(gt(i,j)) = 2*max(bounds(i,'up'),bounds(j,'up')) - min(bounds(i,'lo'),bounds(j,'lo'));
* the factor 2 is to bridge from -abs() to +abs()

positive variable d(i,j) 'absolute distance between points i and j';

equations
   dist1(i,j), dist2(i,j), dist3(i,j), dist4(i,j)
   smallest(i,j) 'bound on d(i,j)'
;

dist1(gt(i,j)).. d(i,j) =g= x(i)-x(j);
dist2(gt(i,j)).. d(i,j) =g= x(j)-x(i);
dist3(gt(i,j)).. d(i,j) =l= x(i)-x(j) + M(i,j)*(1-delta(i,j));
dist4(gt(i,j)).. d(i,j) =l= x(j)-x(i) + M(i,j)*delta(i,j);
smallest(gt(i,j)).. z =l= d(i,j);

model m2 /dist1,dist2,dist3,dist4,smallest/;
solve m2 maximizing z using mip;

report(m2,'MIP/BIN',0)
display results;

* fix variables
delta.fx(fix0) = 0;
delta.fx(fix1) = 1;

solve m2 maximizing z using mip;

report(m2,'MIP/BIN/FX',1)
display results;


*--------------------------------------------------
* MIP model using SOS1 variables
*--------------------------------------------------

set k /case1, case2/;

sos1 variable v(i,j,k);

equations
  distA(i,j), distB(i,j)
;


distA(gt(i,j)).. d(i,j) =e= x(i)-x(j) + v(i,j,'case1');
distB(gt(i,j)).. d(i,j) =e= x(j)-x(i) + v(i,j,'case2');

model m3 /distA,distB,smallest/;
solve m3 maximizing z using mip;

report(m3,'MIP/SOS',0)
display results;

* fix variables
v.fx(fix0,'case2') = 0;
v.fx(fix1,'case1') = 0;

solve m3 maximizing z using mip;

report(m3,'MIP/SOS/FX',1)
display results;
