$ontext

   Plot convex hull

$offtext

option seed = 12345;

option minlp=baron, mip=cplex;

*-----------------------------------------------------
* data
*-----------------------------------------------------

set
   i 'data points' /point1*point50/
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
 
*---------------------------------------------------------------------
* visualization
*---------------------------------------------------------------------

$set html  plot.html
$set data  data.js


file fdata /%data%/; put fdata;

put "p=[";
loop(i,
  put "{";
  put "x:",p(i,'x'):0:4,",";
  put "y:",p(i,'y'):0:4,",";
  put "h:",(1*hull(i)):1,",";
  put "},"/;
    
);
put "]"/;

$onecho > %html%
<html>
<script src="https://cdn.plot.ly/plotly-3.4.0.min.js" charset="utf-8"></script>
<script src="%data%" charset="utf-8"></script>
<h1>Convex Hull</h1>
<div id="plotDiv"></div>
<script>

xh = p.filter(o => o.h === 1).map(o => o.x)
yh = p.filter(o => o.h === 1).map(v => v.y)
xnh = p.filter(o => o.h === 0).map(o => o.x)
ynh = p.filter(o => o.h === 0).map(v => v.y)

trace1 = {
   x : xh, y : yh,
   mode : 'markers',
   name : 'hull',
}

trace2 = {
   x : xnh, y : ynh,
   mode : 'markers',
   name : 'interior',
}

layout = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true
  }

Plotly.newPlot('plotDiv', [trace1,trace2], layout);
</script>
</html>
$offecho

executetool 'win32.ShellExecute "%html%"';

