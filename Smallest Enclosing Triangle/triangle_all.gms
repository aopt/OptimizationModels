$onText

  Given are n data points (2d).
  Find the smallest triangle that contains all points.
 
  Three different definitions of size.
  
  Model m1: area, absolute value using variable splitting
        m2: area, absolute value using bounding
        m3: circumference 
        m4: sum of squares
        m5: as m4, use convex hull instead of all points 
 
$offText

option nlp=scip, reslim=1000;
 
*---------------------------------------------------------------------
* data: points
*---------------------------------------------------------------------
 
sets
   i 'points'   /point1*point50/
   s(i) 'subset (e.g. convex hull)'
   c 'coordinates' /x,y/
   k  'corner points of triangle' /corner1*corner3/
;
 
parameter p(i,c) 'data points';
p(i,c) = uniform(0,100);
display p;


*---------------------------------------------------------------------
* reporting
*---------------------------------------------------------------------

parameter
   results(*,*) 'combined results'
   triangle(*,k,c) 'solution' 
;

acronym timelimit;

$macro report(m,id) \
results(id,'area') = abs(0.5*[t.l(x1)*(t.l(y2)-t.l(y3)) + t.l(x2)*(t.l(y3)-t.l(y1)) + t.l(x3)*(t.l(y1)-t.l(y2))]); \
results(id,'time') = m.resusd; \
results(id,'obj') = m.objval;  \
results(id,'best bound') = m.objest; \
results(id,'gap%') = 100*abs(m.objest-m.objval)/m.objval; \
results(id,'status')$(m.solvestat=3) = timelimit;\
triangle(id,k,c) = t.l(k,c); \
display results,triangle;



*---------------------------------------------------------------------
* constraints:
*  points inside triangle using barymetric coordinates
*  order corner points by x coordinate
*---------------------------------------------------------------------


positive variable
   lambda(i,k)  'barycentric coordinates'
;

free variable
   t(k,c)  'triangle'
;
* some reasonable bounds
t.lo(k,c) = -1000;
t.up(k,c) = +1000;


equations
   calcLambda(i,c)  'solve for barycentric coordinates'
   sumLambda(i)     'lambdas need to add up to one'
   order            'order corner points by their x coordinate'
;

calcLambda(s,c)..  p(s,c) =e= sum(k, lambda(s,k)*t(k,c));
sumLambda(s)..     sum(k, lambda(s,k)) =e= 1;
order(k-1)..       t(k,'x') =g= t(k-1,'x');

model cons 'constraints' /calcLambda,sumLambda,order/;


*---------------------------------------------------------------------
* objective 1: area (variable splitting)
*---------------------------------------------------------------------

* use all points
s(i) = yes;

set
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
   z       'objective'
;
 
positive variable
   area(pm)     'area (using variable splitting)'
;
 
equations
   calcArea         'calculate area given its three corner points'
   obj              'objective'
;
 
calcArea..         area('+')-area('-') =e= 0.5*[t(x1)*(t(y2)-t(y3)) + t(x2)*(t(y3)-t(y1)) + t(x3)*(t(y1)-t(y2))];
obj..              z =e= sum(pm,area(pm));
 
model m1 'area -- var splitting' /calcArea,obj,cons/;
solve m1 minimizing z using nlp;

report(m1,'m1 area var split')

*---------------------------------------------------------------------
* objective 2: area (bounding)
*---------------------------------------------------------------------

variable
   a 'area'
   absa 'abs area'
;
absa.lo = 0;

equations
   calcArea2       'calculate area given its three corner points'
   bnd1            'objective bound'
   bnd2            'objective bound'
;

calcArea2..         a =e= 0.5*[t(x1)*(t(y2)-t(y3)) + t(x2)*(t(y3)-t(y1)) + t(x3)*(t(y1)-t(y2))];
bnd1..              a =l= absa;   
bnd2..              a =g= -absa;   

model m2 'area -- bounding' /calcArea2,bnd1,bnd2,cons/;
solve m2 minimizing absa using nlp;

report(m2,'m2 area bnd')

*---------------------------------------------------------------------
* objective 3: circumference
*---------------------------------------------------------------------

alias(k,kk);

equations
   circumference    'calculate perimeter of triangle'
;

circumference..    z =e= sum((k,kk)$(ord(k)<ord(kk)), sqrt(sum(c,sqr(t(k,c)-t(kk,c)))));

model m3 'area -- bounding' /circumference,cons/;
solve m3 minimizing z using nlp;

report(m3,'m3 circumference')

*---------------------------------------------------------------------
* objective 4: sum of squares
*---------------------------------------------------------------------

alias(k,kk);

equations
   sos    'drop square root'
;

sos..    z =e= sum((k,kk)$(ord(k)<ord(kk)), sum(c,sqr(t(k,c)-t(kk,c))));

model m4 'area -- bounding' /sos,cons/;
solve m4 minimizing z using nlp;

report(m4,'m4 sos')


*---------------------------------------------------------------------
* model 4 hull: as previous but now use only the points
* that are part of the convex hull
*---------------------------------------------------------------------

set hull(i) 'convex hull';

embeddedCode Python:
import scipy as sp
import numpy as np
import gams.transfer as gt

i = list(gams.get("i"))
p = gt.Container(gams.db)["p"].toDense()
hull = sp.spatial.ConvexHull(p).vertices
h = [i[pt] for pt in hull]
gams.set("hull",h)
endEmbeddedCode hull

display hull;

s(i) = no;
s(hull) = yes;
solve m4 minimizing z using nlp;

report(m4,'m4 sos hull')

*---------------------------------------------------------------------
* visualization
*---------------------------------------------------------------------

$set html  plot.html
$set data  data.js

file fdata /%data%/; put fdata;

* points
put "px=["; loop(i,put p(i,'x'):0:3,","); put "];"/;
put "py=["; loop(i,put p(i,'y'):0:3,","); put "];"/;
* triangles
put "txm1=["; loop(k,put triangle('m1 area var split',k,'x'):0:3,","); put "];"/;
put "tym1=["; loop(k,put triangle('m1 area var split',k,'y'):0:3,","); put "];"/;
put "txm3=["; loop(k,put triangle('m3 circumference',k,'x'):0:3,","); put "];"/;
put "tym3=["; loop(k,put triangle('m3 circumference',k,'y'):0:3,","); put "];"/;
put "txm4=["; loop(k,put triangle('m4 sos',k,'x'):0:3,","); put "];"/;
put "tym4=["; loop(k,put triangle('m4 sos',k,'y'):0:3,","); put "];"/;


$onecho > %html%
<html>
<script src="https://cdn.plot.ly/plotly-3.4.0.min.js" charset="utf-8"></script>
<script src="%data%" charset="utf-8"></script>
<h1>Smallest Encompassing Triangle</h1>
<div id="plotDiv"></div>
<script>
var data = {
  x: px,
  y: py,
  mode: 'markers',
  type: 'scatter',
  name: 'data points'
};

txm1[3]=txm1[0];
tym1[3]=tym1[0];
var minarea = {
  x: txm1,
  y: tym1,
  mode: 'lines',
  type: 'scatter',
  name: 'min area'
};

txm3[3]=txm3[0];
tym3[3]=tym3[0];
var mincircumf = {
  x: txm3,
  y: tym3,
  mode: 'lines',
  type: 'scatter',
  name: 'min circumference'
};

txm4[3]=txm4[0];
tym4[3]=tym4[0];
var minsos = {
  x: txm4,
  y: tym4,
  mode: 'lines',
  type: 'scatter',
  name: 'min sum of squares'
};

var layout = {
  autosize: false,
  width: 700,
  height: 500,
  showlegend: true
}
var trc = [data,minarea,mincircumf,minsos];
var options = {staticPlot: true, displayModeBar: false};
Plotly.newPlot('plotDiv', trc, layout, options);
</script>
</html>
$offecho

executetool 'win32.ShellExecute "%html%"';
