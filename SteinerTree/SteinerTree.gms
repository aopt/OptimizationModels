$ontext

   Euclidean Steiner Tree Model


   Based on model from:

     Nelson Maculan, Philippe Michelon and Adilson E. Xavier,
     The Euclidean Steiner tree problem in R^n: A mathematical
     programming formulation,
     Annals of Operations Research 96 (2000) 209–220

   See:
   https://yetanothermathprogrammingconsultant.blogspot.com/2021/03/euclidean-steiner-tree-problems-as.html

   erwin@amsterdamoptimization.com


$offtext


* size of the problem
* np = number of given points
* ns = number of steiner points

$set   np  5
$eval  ns (%np%-2)

set
  i     'all points'     /p1*p%np%,s1*s%ns%/
  p(i)  'given points'   /p1*p%np%/
  s(i)  'Steiner points' /s1*s%ns%/
  c     'coordinate'     /x,y/
;

scalars
   np 'number of given points' /%np%/
   ns 'number of Steiner points' /%ns%/
;

alias (i,j), (s,s1), (p,p1);

option seed = 1234;

*--------------------------------------------------
* data
*--------------------------------------------------

parameters
  x0(p,c)   'coordinates given points'
  box(c,*)  'min/max of x0'
;
x0(p,c) = uniform(0,100);
box(c,'lo') = smin(p,x0(p,c));
box(c,'up') = smax(p,x0(p,c));
box(c,'range') = box(c,'up')-box(c,'lo');
display x0,box;

set E(i,j) 'edges';
E(i,j) = ord(i)<ord(j);

scalar epsilon 'protect square root' /0.0001/;

*--------------------------------------------------
* Nonconvex MINLP model
*--------------------------------------------------

variables
   x(i,c)    'coordinates of points'
   y(i,j)    'tree'
   z         'objective'
;
binary variable y;
positive variable d;

x.fx(p,c) = x0(p,c);
x.lo(s,c) = box(c,'lo');
x.up(s,c) = box(c,'up');

equations
   objective 'min lengths'
   degree1   'terminal points p have degree 1'
   degree3   'Steiner points have degree 3'
   nocycle   'prevent cycles'
   order     'ordering constraint (symmetry breaker)'
   total     'optional constraint (set total edges)'
;

objective..
   z =e= sum(E(i,j),sqrt(sum(c,sqr(x(i,c)-x(j,c)))+epsilon)*y(E));

degree1(p)..
   sum(E(p,s), y(E)) =e= 1;

degree3(s)..
   sum(E(p,s), y(E)) + sum(E(s1,s), y(E)) + sum(E(s,s1), y(E)) =e= 3;

nocycle(s)$(ord(s)>1)..
   sum(E(s1,s),y(E)) =e= 1;

order(s+1)..
   x(s,'x') =l= x(s+1,'x');

total..
  sum(E,y(E)) =e= card(i)-1;

model m1 /objective,degree1,degree3,nocycle,order,total/;
option minlp=baron, optcr=0, threads=8;
solve m1 minimizing z using minlp;


*--------------------------------------------------
* MISOCP model
*--------------------------------------------------

variables
  d(i,j)    'distance (length)'
  d2(i,j,c) 'auxiliary variable in convex distance calculation'
  d3(i,j)   'auxiliary variable in convex distance calculation'
;
positive variable d3;

equations
   objective2    'min lengths'
   defd2(i,j,c)  'auxiliary constraint for socp constraint'
   socp(i,j)     'convex conic constraint'
   bound(i,j)    'auxiliary constraint for socp constraint'
;

scalar M;
M = sqrt(2)*(smax(c,box(c,'up'))-smin(c,box(c,'lo')));

objective2..       z =e= sum(E,d(E));

defd2(E(i,j),c)..  d2(E,c) =e= x(i,c)-x(j,c);
socp(E)..          sqr(d3(E)) =g= sum(c,sqr(d2(E,c)));
bound(E)..         d(E) =g= d3(E) - M*(1-y(E));


model m2 /objective2,defd2,socp,bound,degree1,degree3,nocycle,order,total/;
option miqcp=cplex;
solve m2 minimizing z using miqcp;


*--------------------------------------------------
* prepare data for plotting in R
*--------------------------------------------------

alias(*,c2,point);

parameter
  Points(i,point,c)
  Tree(i,j,c2)
;
Points(p,'given',c) = x.l(p,c);
Points(s,'steiner',c) = x.l(s,c);
loop((i,j)$(y.l(i,j)>0.5),
  Tree(i,j,'x1') = x.l(i,'x');
  Tree(i,j,'y1') = x.l(i,'y');
  Tree(i,j,'x2') = x.l(j,'x');
  Tree(i,j,'y2') = x.l(j,'y');
);
display Points,Tree;