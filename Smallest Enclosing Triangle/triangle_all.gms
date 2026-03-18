$onText

  Given are n data points (2d).
  Find the smallest triangle that contains all points.
 
  Three different definitions of size.
 
$offText

option nlp=scip, reslim=1000;
 
*---------------------------------------------------------------------
* data: points
*---------------------------------------------------------------------
 
sets
   i 'points'   /point1*point50/
   c 'coordinates' /x,y/
;
 
parameter p(i,c) 'data points';
p(i,c) = uniform(0,100);

*---------------------------------------------------------------------
* constraints:
*  points inside triangle using barymetric coordinates
*  order corner points by x coordinate
*---------------------------------------------------------------------

set
   k  'corner points of triangle' /corner1*corner3/
;

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

calcLambda(i,c)..  p(i,c) =e= sum(k, lambda(i,k)*t(k,c));
sumLambda(i)..     sum(k, lambda(i,k)) =e= 1;
order(k-1)..       t(k,'x') =g= t(k-1,'x');


model cons 'constraints' /calcLambda,sumLambda,order/;

*---------------------------------------------------------------------
* objective 1: area (variable splitting)
*---------------------------------------------------------------------

parameter
   results(*,*) 'combined results'
   triangle(*,k,c) 'solution' 
;

 
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

results('m1 area var split','area') = abs(0.5*[t.l(x1)*(t.l(y2)-t.l(y3)) + t.l(x2)*(t.l(y3)-t.l(y1)) + t.l(x3)*(t.l(y1)-t.l(y2))]);
results('m1 area var split','time') = m1.resusd;
triangle('m1',k,c) = t.l(k,c);  
display results,triangle;

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

results('m2 area bnd','area') = abs(0.5*[t.l(x1)*(t.l(y2)-t.l(y3)) + t.l(x2)*(t.l(y3)-t.l(y1)) + t.l(x3)*(t.l(y1)-t.l(y2))]);
results('m2 area bnd','time') = m2.resusd;
triangle('m2',k,c) = t.l(k,c);  
display results,triangle;

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

results('m3 circumference','area') = abs(0.5*[t.l(x1)*(t.l(y2)-t.l(y3)) + t.l(x2)*(t.l(y3)-t.l(y1)) + t.l(x3)*(t.l(y1)-t.l(y2))]);
results('m3 circumference','time') = m3.resusd;
triangle('m3',k,c) = t.l(k,c);  
display results,triangle;

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

results('m4 sos','area') = abs(0.5*[t.l(x1)*(t.l(y2)-t.l(y3)) + t.l(x2)*(t.l(y3)-t.l(y1)) + t.l(x3)*(t.l(y1)-t.l(y2))]);
results('m4 sos','time') = m4.resusd;
triangle('m4',k,c) = t.l(k,c);  
display results,triangle;

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
put "txm1=["; loop(k,put triangle('m1',k,'x'):0:3,","); put "];"/;
put "tym1=["; loop(k,put triangle('m1',k,'y'):0:3,","); put "];"/;
put "txm3=["; loop(k,put triangle('m3',k,'x'):0:3,","); put "];"/;
put "tym3=["; loop(k,put triangle('m3',k,'y'):0:3,","); put "];"/;
put "txm4=["; loop(k,put triangle('m4',k,'x'):0:3,","); put "];"/;
put "tym4=["; loop(k,put triangle('m4',k,'y'):0:3,","); put "];"/;

set mall /m1,m3,m4/;

parameter box;
box(c,'lo') = smin((mall,k),triangle(mall,k,c));
box(c,'up') = smax((mall,k),triangle(mall,k,c));
box(c,'range') = box(c,'up')-box(c,'lo');
box(c,'lo2') =  box(c,'lo') - 0.1*box(c,'range');
box(c,'up2') =  box(c,'up') + 0.1*box(c,'range');
display box;

put "cmin=["; loop(c, put box(c,'lo2'):0:3,","); put "];"/;
put "cmax=["; loop(c, put box(c,'up2'):0:3,","); put "];"/;


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
