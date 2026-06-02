$onText

   Find dispersed k out-of n locations by maximizing the minimum distance.
   
   Experiment with alternatives for indicator constraints.

   See:
   https://yetanothermathprogrammingconsultant.blogspot.com/2026/06/minlp-instead-of-indicator-constraints.html

$offText


option seed = 12345;
option minlp=baron,mip=cplex;

* select k out of n points
$set n 50
$set k 10

* 0: no plot
$set htmlplot 1

*-----------------------------------------------------------------
* data
*-----------------------------------------------------------------

Scalars
  n 'total number of locations' /%n%/
  k 'number of locations to choose' /%k%/
;

set 
    i 'possibe locations' /location1*location%n%/
    c 'coordinates' /x,y/
;

parameter
    p(i,c) 'possible locations'
;
p(i,c) = uniform(0,100);
display p;

*-----------------------------------------------------------------
* derived data: distances
*-----------------------------------------------------------------

alias(i,j);
set lt(i,j) 'upper triangular part';
lt(i,j) = ord(i)<ord(j);

parameter dist(i,j) 'distance between locations';
dist(lt(i,j)) = sqrt(sum(c, sqr(p(i,c)-p(j,c))));
display dist;

scalars
   mind 'minimum distance'
   maxd 'maximum distance'
;
mind = smin(lt(i,j),dist(i,j));
maxd = smax(lt(i,j),dist(i,j));
display mind,maxd;

*-----------------------------------------------------------------
* models 
*-----------------------------------------------------------------

parameter M(i,j) 'big-M';
M(lt(i,j)) = maxd-dist(i,j);  

binary variable s(i) 'location is selected';
variable z 'objective: max min dist';

Equations
    count     'select n locations'
    mindist1  'min distance (bound): MINLP formulation of indicator constraint'
    mindist2  'min distance (bound): MINLP formulation of indicator constraint'
    mindist3  'min distance (bound): Linearized big-M formulation'
;

mindist1(lt(i,j))..  z*s(i)*s(j) =l= dist(i,j);
mindist2(lt(i,j))..  z*s(i)*s(j) =l= dist(i,j)*s(i)*s(j);
mindist3(lt(i,j))..  z =l= dist(i,j) + M(i,j)*(1-s(i)) + M(i,j)*(1-s(j));
count.. sum(i, s(i)) =e= k;

z.lo = 0;
z.up = maxd;

model m1 /mindist1, count/;
model m2 /mindist2, count/;
model m3 /mindist3, count/;

solve m1 maximizing z using minlp;
solve m2 maximizing z using minlp;
solve m3 maximizing z using mip;

parameter d(i,j) 'distance of used points';
d(lt(i,j))$(s.l(i)>0.5 and s.l(j)>0.5) = dist(i,j);
display z.l,s.l,d;

scalar xmind 'z.l is not exact';
xmind = smin((i,j)$d(i,j),d(i,j));

set mindist_id(i,j) 'min distance nodes';
mindist_id(i,j)$d(i,j) = d(i,j) = xmind;
display mindist_id;

parameter results,size;
size('n') = n;
size('k') = k;
results('model 1','minlp','obj')=m1.objval;
results('model 1','minlp','time')=m1.resusd;
results('model 1','minlp','nodes')=m1.nodusd;
results('model 2','minlp','obj')=m2.objval;
results('model 2','minlp','time')=m2.resusd;
results('model 2','minlp','nodes')=m2.nodusd;
results('model 3','mip','obj')=m3.objval;
results('model 3','mip','time')=m3.resusd;
results('model 3','mip','nodes')=m3.nodusd;
display size,results;

*---------------------------------------------------------------------
* visualization
*---------------------------------------------------------------------
$set html  plot.html
$set data  data.js

$if %htmlplot%==0 $goto skipplot



file fdata /%data%/; put fdata;

*  points
put "px=["/;
loop(i$(s.l(i)<0.5),
  put p(i,'x'):0:4,","/;
);
put "]"/;
put "py=["/;
loop(i$(s.l(i)<0.5),
  put p(i,'y'):0:4,","/;
);
put "]"/;
put "sx=["/;
loop(i$(s.l(i)>0.5),
  put p(i,'x'):0:4,","/;
);
put "]"/;
put "sy=["/;
loop(i$(s.l(i)>0.5),
  put p(i,'y'):0:4,","/;
);
put "]"/;

$onecho > %html%
<html>
<script src="https://cdn.plot.ly/plotly-3.4.0.min.js" charset="utf-8"></script>
<script src="%data%" charset="utf-8"></script>

<div id="plotDiv0" style="width: 800px; height: 600px;"></div>

<p id="expl">
<p>

<script>


var data1 = {
  x: px,
  y: py,
  size: 2,
  mode: 'markers',
  type: 'scatter',
  color: 'blue',
  name: 'locations'
};
var data2 = {
  x: sx,
  y: sy,
  size: 2,
  mode: 'markers',
  type: 'scatter',
  color: 'orange',
  name: 'selected locations'
};


n = sy.length;

shortest = 1.0e6
ishort = -1
jshort = -1

for (i=0; i<n; ++i) {
   for (j=0; j<i; ++j) {
      d = (sx[i]-sx[j])**2 + (sy[i]-sy[j])**2
      if (d<shortest) {
         ishort=i;
         jshort=j;
         shortest=d;
      }
   }
}

shapes = []

for (i=0; i<n; ++i) {
   for (j=0; j<i; ++j) {
       col = 'orange';
       w = 1;
       if ((i==ishort) && (j==jshort)) {
          col = 'red';
          w = 2;
       }
       sh = {
         type : 'line',
         x0 : sx[i],
         y0 : sy[i],
         x1 : sx[j],
         y1 : sy[j],
         line : {
            color: col,
            width: w
         }
       }
       shapes.push(sh);
   }
}

var layout1 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  title: {text:'maximin distance',font: {size: 24}},
  shapes: shapes,
}



var trc1 = [data1,data2];
var options1 = {staticPlot: true, displayModeBar: false, responsive: false};
Plotly.newPlot('plotDiv0', trc1, layout1, options1);


document.getElementById("expl").innerHTML = "We find k="+sx.length+" points out of n="+(sx.length+px.length)+". The length of the shortest line between selected points is maximized. "
+ "This shortest line is colored red and has length "+Math.sqrt(shortest).toFixed(3) + ".";


</script>
$offecho

executetool 'win32.ShellExecute "%html%"';

$label skipplot
 