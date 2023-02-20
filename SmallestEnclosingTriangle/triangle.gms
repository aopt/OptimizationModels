$onText
  
  Given are n points (2d).
  Find smallest triangle that contains all points.
  
$offText

*---------------------------------------------------------------------
* data: points
*---------------------------------------------------------------------

set
   i 'points'   /point1*point25/
   c 'coordinates' /x,y/
;

parameter p(i,c) 'data points';
p(i,c) = uniform(0,100);

*---------------------------------------------------------------------
* find smallest triangle to contain all points
*---------------------------------------------------------------------


sets
   k  'corner points of triangle' /corner1*corner3/
   pm 'plusmin -- used in linearizing abs()' /'+','-'/
;

* shorthands to make our area calculation easier
singleton sets
   x1(k,c) /'corner1'.'x'/
   x2(k,c) /'corner2'.'x'/
   x3(k,c) /'corner3'.'x'/
   y1(k,c) /'corner1'.'y'/
   y2(k,c) /'corner2'.'y'/
   y3(k,c) /'corner3'.'y'/
;
   

variable
   t(k,c)  'triangle'
   z       'objective'
;

positive variable
   area(pm)     'area (using variable splitting)'
   lambda(i,k)  'barycentric coordinates' 
;
lambda.up(i,k) = 1;

equations
   calcArea         'calculate area given its three corner points'
   calcLambda(i,c)  'solve for barycentric coordinates' 
   sumLambda(i)     'lambdas need to add up to one'
   obj              'objective'
   order            'order corner points by their x coordinate' 
;

calcArea..         area('+')-area('-') =e= 0.5*[t(x1)*(t(y2)-t(y3)) + t(x2)*(t(y3)-t(y1)) + t(x3)*(t(y1)-t(y2))];
calcLambda(i,c)..  p(i,c) =e= sum(k, lambda(i,k)*t(k,c)); 
sumLambda(i)..     sum(k, lambda(i,k)) =e= 1;
obj..              z =e= sum(pm,area(pm));
order(k-1)..       t(k,'x') =g= t(k-1,'x');


* some reasonable bounds
t.lo(k,c) = -1000;
t.up(k,c) = +1000;


model m /all/;
option nlp=baron, threads=0, reslim=1000;
solve m minimizing z using nlp;

* data + results
display p,t.l,area.l,lambda.l;