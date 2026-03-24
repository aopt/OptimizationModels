$ontext

  Given n data points, find the smallest circle that contains all the points. 

$offtext

option nlp=conopt, qcp=xpress;

*-----------------------------------------------------
* data
*-----------------------------------------------------

set 
   i 'data points' /point1*point100/
   xy 'coordinates' /x,y/
;  

parameter p(i,xy) 'data points';
p(i,xy) = uniform(0,100);
display p;

scalars
   hullarea 'area of convex hull'
   hullcircumference 'perimeter of hull'   
;


*-----------------------------------------------------
* convex hull 
*-----------------------------------------------------

set hull(i) 'convex hull';

embeddedCode Python:
import scipy as sp
import numpy as np
import gams.transfer as gt

print(f"scipy version {sp.__version__}")

i = list(gams.get("i"))
p = gt.Container(gams.db)["p"].toDense()
hull = sp.spatial.ConvexHull(p)
h = [i[pt] for pt in hull.vertices]
gams.set("hull",h)
endEmbeddedCode hull 

parameter numpoints(*) 'number of points';
numpoints('data points') = card(i);
numpoints('convex hull') = card(hull);
display numpoints,hull;


*-----------------------------------------------------
* nlp model
*-----------------------------------------------------

variables
   c(xy)  'center' 
   r2     'squared radius'
;

equation inside(i) 'point i is inside circle';

inside(i).. sum(xy, sqr(p(i,xy)-c(xy))) =l= r2;

* very good initial point
c.l(xy) = sum(i,p(i,xy))/card(i);
r2.l = smax(i,sum(xy, sqr(p(i,xy)-c.l(xy))));

model m1 /inside/;

*-----------------------------------------------------
* solve and reporting
*-----------------------------------------------------

parameter results(*,*,*);
results('c',xy,'initial') = c.l(xy);
results('r','','initial') = sqrt(r2.l);

solve m1 minimizing r2 using nlp;

results('c',xy,'nlp') = c.l(xy);
results('r','','nlp') = sqrt(r2.l);
results('time','','nlp') = m1.resusd;
results('iterations','','nlp') = m1.iterusd;
display results;

*-----------------------------------------------------
* conic model
*-----------------------------------------------------

variable
  r 'radius'
  diff(i,xy) 'p(i,xy)-c(xy)'
;
r.lo = 0;

positive variable
  ri(i) 'needed for mosek'
;

equations
   ediff(i,xy) 'auxiliary constraint, needed for socp'
   er(i)       'needed for mosek'
   inside2(i)  'point i is inside circle'
;

ediff(i,xy)..  diff(i,xy) =e= p(i,xy)-c(xy);
er(i)..        r =e= ri(i);
inside2(i)..   sum(xy, sqr(diff(i,xy))) =l= sqr(ri(i));

model m2 /ediff,er,inside2/;
solve m2 minimizing r using qcp;

results('c',xy,'socp') = c.l(xy);
results('r','','socp') = r.l;
results('time','','socp') = m2.resusd;
results('iterations','','socp') = m2.iterusd;
display results;
