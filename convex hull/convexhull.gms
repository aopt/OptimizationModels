$ontext

   Calculate convex hull of a set of points using an MINLP or MIP model

$offtext

option seed = 12345;

option minlp=baron, mip=cplex;

*-----------------------------------------------------
* data
*-----------------------------------------------------

set
   i 'data points' /point1*point15/
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

p(i,'hull/scipy') = hull(i);
p('count','hull/scipy') = card(hull);
display p;
 
 
*-----------------------------------------------------
* minlp convex hull model
*-----------------------------------------------------

alias(i,j);

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
   choose(i)     'point is either hull or interior'
   inside(i,k)   'convex combination, only for nh(i)=1'
   sum_lambda(i) 'normalize weights, only fot n(i)=1' 
   count         'number of hull points'  
;

choose(i).. h(i)+nh(i) =e= 1;

inside(i,k)..
    p(i,k)*nh(i) =e= sum(j, lambda(i,j)*p(j,k)*h(j));

sum_lambda(i).. sum(j, lambda(i,j)*h(j)) =e= nh(i);
    
count.. z =e= sum(i, h(i));

model m /all/;


solve m minimizing z using minlp;

display h.l,nh.l,lambda.l;

p(i,'hull/minlp') = h.l(i)>0.5;
p('count','hull/minlp') = sum(i$(h.l(i)>0.5),1);
display p;


*-----------------------------------------------------
* mip convex hull model
*-----------------------------------------------------

Equations
   lambda_bnd(i,j) 'h(j)=0 => lambda(i,j)=0'
   inside2(i,k)    'linearization uses lambda_bnd'
   sum_lambda2     'linear version' 
;

lambda_bnd(i,j)..  lambda(i,j) =l= h(j);
inside2(i,k)..     p(i,k)*nh(i) =e= sum(j, lambda(i,j)*p(j,k)); 
sum_lambda2(i)..   sum(j, lambda(i,j)) =e= nh(i);
   
model m2 /choose,lambda_bnd,inside2,sum_lambda2,count/;
solve m2 minimizing z using mip;

display h.l,lambda.l;

p(i,'hull/mip') = h.l(i)>0.5;
p('count','hull/mip') = sum(i$(h.l(i)>0.5),1);
display p;

