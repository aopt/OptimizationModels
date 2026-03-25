$ontext

  Given n data points, find the smallest circle that contains all the points. 

$offtext

option nlp=conopt, qcp=cplex;

* 0: use all data points
* 1: use only convex hull
scalar convexhull /0/;

*-----------------------------------------------------
* data
*-----------------------------------------------------

set 
   i 'data points' /point1*point100/
   k 'coordinates' /x,y/
;  

parameter p(i,k) 'data points';
p(i,k) = uniform(0,100);
display p;

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
* model 1: nlp model
*-----------------------------------------------------

set j(i) 'subset of points used in model';

j(i)$(convexhull=0) = yes;
j(hull)$(convexhull=1) = yes;

variables
   c(k)   'center' 
   r2     'squared radius'
;

equation inside(i) 'point i is inside circle';

inside(j).. sum(k, sqr(p(j,k)-c(k))) =l= r2;

* (very good) initial point
c.l(k) = sum(j,p(j,k))/card(i);
r2.l = smax(j,sum(k, sqr(p(j,k)-c.l(k))));

model m1 /inside/;

*-----------------------------------------------------
* solve and reporting
*-----------------------------------------------------

parameter results(*,*,*);
results('c',k,'initial') = c.l(k);
results('r','','initial') = sqrt(r2.l);

solve m1 minimizing r2 using nlp;

results('c',k,'nlp') = c.l(k);
results('r','','nlp') = sqrt(r2.l);
results('time','','nlp') = m1.resusd;
results('iterations','','nlp') = m1.iterusd;
display results;

*-----------------------------------------------------
* model 2: conic model
*-----------------------------------------------------

variable
  r 'radius'
  diff(i,k) 'p(i,k)-c(k)'
;
r.lo = 0;

positive variable
  s(i) 'needed for mosek'
;

equations
   ediff(i,k) 'auxiliary constraint, needed for socp'
   es(i)       'needed for mosek'
   inside2(i)  'point i is inside circle'
;

ediff(j,k)..   diff(j,k) =e= p(j,k)-c(k);
es(j)..        r =e= s(j);
inside2(j)..   sum(k, sqr(diff(j,k))) =l= sqr(s(j));

model m2 /ediff,es,inside2/;

*-----------------------------------------------------
* solve and reporting
*-----------------------------------------------------

solve m2 minimizing r using qcp;

results('c',k,'socp') = c.l(k);
results('r','','socp') = r.l;
results('time','','socp') = m2.resusd;
results('iterations','','socp') = m2.iterusd;
display results;



*---------------------------------------------------------------------
* visualization
*---------------------------------------------------------------------

$set html  plot.html
$set data  data.js


parameter init(k), initr;
init(k) = sum(j,p(j,k))/card(j);
initr = sqrt(smax(j,sum(k, sqr(p(j,k)-init(k)))));


file fdata /%data%/; put fdata;

* points
put "px=["; loop(j,put p(j,'x'):0:4,","); put "];"/;
put "py=["; loop(j,put p(j,'y'):0:4,","); put "];"/;
put "xa0=",(init('x')-initr):0:4,";"/;
put "ya0=",(init('y')-initr):0:4,";"/;
put "xa1=",(init('x')+initr):0:4,";"/;
put "ya1=",(init('y')+initr):0:4,";"/;
put "xb0=",(c.l('x')-r.l):0:4,";"/;
put "yb0=",(c.l('y')-r.l):0:4,";"/;
put "xb1=",(c.l('x')+r.l):0:4,";"/;
put "yb1=",(c.l('y')+r.l):0:4,";"/;


$onecho > %html%
<html>
<script src="https://cdn.plot.ly/plotly-3.4.0.min.js" charset="utf-8"></script>
<script src="%data%" charset="utf-8"></script>
<h1>Smallest Encompassing Circle</h1>
<div id="plotDiv"></div>
<script>
var data = {
  x: px,
  y: py,
  mode: 'markers',
  type: 'scatter',
  name: 'data points'
};

var layout = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  shapes: [{type:'circle',
            xref:'x',
            yref:'y',
            x0:xa0,
            y0:ya0,
            x1:xa1,
            y1:ya1,
            line:{color:'orange',width:2},
            fillcolor:'rgba(0,0,0,0)'
            },
           {type:'circle',
            xref:'x',
            yref:'y',
            x0:xb0,
            y0:yb0,
            x1:xb1,
            y1:yb1,
            line:{color:'purple',width:2},
            fillcolor:'rgba(0,0,0,0)'
            }
          ]

}
var trc = [data];
var options = {staticPlot: true, displayModeBar: false};
Plotly.newPlot('plotDiv', trc, layout, options);
</script>
</html>
$offecho

executetool 'win32.ShellExecute "%html%"';


