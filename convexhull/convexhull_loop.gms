$ontext

   Calculate convex hull of a set of points using a MIP model
   We do 500 points in stages

$offtext

option seed = 12345;

option mip=highs;

*-----------------------------------------------------
* data
*-----------------------------------------------------

set
   i 'data points' /point1*point500/
   k 'coordinates' /x,y/
; 

parameter p(*,*) 'data points';
p(i,k) = uniform(0,10);
display p;

*-----------------------------------------------------
* convex hull python code
*-----------------------------------------------------

set hull(i) 'convex hull computed by scipy';

embeddedCode Python:
import scipy as sp
import numpy as np
import gams.transfer as gt

print("Computing convex hull...")
i = list(gams.get("i"))
p = gt.Container(gams.db)["p"].toDense()
hull = sp.spatial.ConvexHull(p)
h = [i[pt] for pt in hull.vertices]
gams.set("hull",h)
endEmbeddedCode hull

display hull;


parameter trace(*,*) 'convex hull after each stage';
option trace:0;
trace(i,'scipy') = hull(i);
trace('count','scipy') = card(hull);
display trace;
 
 
*-----------------------------------------------------
* convex hull model of subset of points
*-----------------------------------------------------

alias(i,j);

set si(i) 'active subset';
alias (si,sj);

variable
  lambda(i,j) 'weights'
;
lambda.lo(i,j) = 0;
lambda.up(i,j) = 1;
lambda.fx(i,i) = 0;

variable z 'objective';

binary variable
   h(i)    'hull'
   nh(i)   'interior'
;

Equation
   choose(i)        'point is either hull or interior'
   lambda_bnd(i,j)  'h(j)=0 => lambda(i,j)=0'
   inside(i,k)      'convex combination, only for nh(i)=1'
   sum_lambda(i)    'normalize weights, only fot n(i)=1' 
   count            'number of hull points'  
;

choose(si(i))..        h(i)+nh(i) =e= 1;
lambda_bnd(si(i),sj(j))..  lambda(i,j) =l= h(j);
inside(si(i),k)..      p(i,k)*nh(i) =e= sum(sj(j), lambda(i,j)*p(j,k)); 
sum_lambda(si(i))..    sum(sj(j), lambda(i,j)) =e= nh(i);  
count..                z =e= sum(si(i), h(i));

model m /all/;

*-----------------------------------------------------
* loop
*-----------------------------------------------------

*
* split our 500 point in 5 stages of 100 points + hull points of previous stage
*
Sets
  st 'stage' /stage1*stage5/
  sti(st,i) '(stage,point) data'
  ch(i)   'current hull' 
;
sti(st,i) = ord(i) > (ord(st)-1)*100 and ord(i) <= ord(st)*100;
ch(i) = no; 

loop(st,

   si(i) = sti(st,i);
* add hull points from previous stage
   si(ch) = yes;

   display si;
   
   solve m minimizing z using mip;
   
   ch(i) = no;
   ch(si) = h.l(si)>0.5;
   
   trace(i,st) = ch(i);
   trace('count',st) = sum(ch,1);
   display trace;
);



$stop

loop(stage)

solve m minimizing z using mip;

display h.l,nh.l,lambda.l;

p(i,'hull/mip') = h.l(i)>0.5;
p('count','hull/mip') = sum(i$(h.l(i)>0.5),1);
display p;


