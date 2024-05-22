$onText


 Problem
 We have a number of overlapping circles. We want to move around
 a bit (as little as possible) to make them non-overlapping.
 
 This is a nonconvex problem.

$offText


*-------------------------------------------------------------------
* size of problem
*-------------------------------------------------------------------

set i /circle1*circle10/;
alias(i,j);

set ij(i,j) 'i<j';
ij(i,j) = ord(i) < ord(j);

table bounds(*,*) 'limits for (x0,y0) and (x,y)'
        min  max
  x0   -100  100
  y0   -100  100
  r     10   50
  x    -200  200
  y    -200  200
;

* (x0,y0) and r are data
* (x,y) are variables  


*-------------------------------------------------------------------
* data
*-------------------------------------------------------------------

Parameter
   x0(i)  'prior x-coordinate'
   y0(i)  'prior y-coordinate' 
   r(i)   'radius'
   d(i,*) 'reporting of data+results'
;
x0(i) = uniform(bounds('x0','min'),bounds('x0','max'));
y0(i) = uniform(bounds('y0','min'),bounds('y0','max'));
r(i) = uniform(bounds('r','min'),bounds('r','max'));

d(i,'x0') = x0(i);
d(i,'y0') = y0(i);
d(i,'r') = r(i);
display d;

*-------------------------------------------------------------------
* model
*-------------------------------------------------------------------

variables
  x(i) 'new x-coordinates'
  y(i) 'new y-coordinates'
  z 'objective: sum of squared distances'
;

* for global NLPs it is always advised to
* to use proper bounds on all variables
x.lo(i) = bounds('x','min');
x.up(i) = bounds('x','max');
y.lo(i) = bounds('y','min');
y.up(i) = bounds('y','max');


Equations
   obj     'objective: (x,y) as close as possible to (x0,y0)'
   no_overlap(i,j) 'circles i and j should not overlap (non-convex costraint)'
;

obj..
   z =e= sum(i, sqr(x(i)-x0(i)) + sqr(y(i)-y0(i)));

no_overlap(ij(i,j))..
   sqr(x(i)-x(j)) + sqr(y(i)-y(j)) =g= sqr(r(i)+r(j));

model move /all/;

*-------------------------------------------------------------------
* select algorithm
*-------------------------------------------------------------------

$set MultiStart 1
$set Global     0


*-------------------------------------------------------------------
* multistart approach using local NLP solver
* best used without symmetry breaker
* we get a solution:  91.183 @ trial1015
*-------------------------------------------------------------------

$ifThen %MultiStart% == 1

set k /trial1*trial25/;
option qcp = conopt;
parameter best(i,*) 'best solution';
scalar zbest 'best objective' /INF/;
parameter trace(k) 'keep track of improvements';
move.solprint = %solprint.Silent%;
move.solvelink = 5;
loop(k,
     x.l(i) = uniform(bounds('x','min')+10,bounds('x','max')-10);
     y.l(i) = uniform(bounds('y','min')+10,bounds('y','max')-10);
     
     solve move minimizing z using qcp;
     if(z.l<zbest,
         zbest = z.l;
         best(i,'x') = x.l(i);
         best(i,'y') = y.l(i);
         trace(k) = z.l;
    );
 );

display zbest,best,trace;

x.l(i) = best(i,'x');
y.l(i) = best(i,'y');


* reset to default for next solves
move.solprint = %solprint.On%;

$endIf


*-------------------------------------------------------------------
* Global NLP solver
* with or without symmetry breaker
*-------------------------------------------------------------------

$ifThen %Global% == 1

option qcp=scip, reslim=1000;
option threads=-1;
solve move minimizing z using qcp;

$endIf
   
*-------------------------------------------------------------------
* reporting
*-------------------------------------------------------------------

d(i,'x') = x.l(i);
d(i,'y') = y.l(i);
d(i,'sq.dist') = sqr(x.l(i)-x0(i)) + sqr(y.l(i)-y0(i));
display d;
