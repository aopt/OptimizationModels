$ontext

   Calculate convex hull of a set of points using an MINLP, MIP or LP model

   Note that I did not prove that the LP will always deliver integer solutions.

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
* mip v1 convex hull model
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

display h.l,nh.l,lambda.l;
display h.l,lambda.l;

p(i,'hull/mip1') = h.l(i)>0.5;
p('count','hull/mip1') = sum(i$(h.l(i)>0.5),1);
display p;


*-----------------------------------------------------
* mip v2 convex hull model
*-----------------------------------------------------

* unfix
lambda.up(i,i) = 1;

Equations
   lambda_bnd(i,j) 'h(j)=0 => lambda(i,j)=0'
   inside3(i,k)    'linearization uses lambda_bnd'
   sum_lambda3     'linear version' 
;

inside3(i,k)..     p(i,k) =e= sum(j, lambda(i,j)*p(j,k)); 
sum_lambda3(i)..   sum(j, lambda(i,j)) =e= 1;

model m3 /lambda_bnd,inside3,sum_lambda3,count/;
solve m3 minimizing z using mip;

display h.l,lambda.l;

p(i,'hull/mip2') = h.l(i)>0.5;
p('count','hull/mip2') = sum(i$(h.l(i)>0.5),1);
display p;

display h.l,lambda.l;

*-----------------------------------------------------
* solve mip v2 as LP
*-----------------------------------------------------

solve m3 minimizing z using rmip;

p(i,'hull/lp') = h.l(i)>0.5;
p('count','hull/lp') = sum(i$(h.l(i)>0.5),1);
display p;

