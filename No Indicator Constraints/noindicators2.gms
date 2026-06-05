$onText

   Find dispersed k out-of n locations by maximizing the minimum distance.
   
   Experiment with alternatives for indicator constraints.

   See:
   https://yetanothermathprogrammingconsultant.blogspot.com/2026/06/minlp-instead-of-indicator-constraints.html

$offText


option seed = 12345;
option minlp=baron,mip=cplex;

* select k out of n points
*$set n 50
*$set k 10
$set n 100
$set k 15

* 0: no plot
$set htmlplot 0

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
display$(n<=50) dist;

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

set s1 'for sos1' /sos1-1,sos1-2/;

binary variables
    s(i)   'location is selected'
    t(i,j) 's(i)*s(j)'
;
positive variable tr(i,j) 'relaxed version of t(i,j)';
tr.up(i,j) = 1;

variable z 'objective: max min dist';

sos1 variable slack(i,j,s1);


Equations
    count     'select n locations'
    mindist1  'using indicator constraints'
    mindist2  'min distance (bound): MINLP formulation of indicator constraint'
    mindist2a 'min distance (bound): MINLP formulation of indicator constraint'
    mindist3  'min distance (bound): MINLP formulation of indicator constraint'
    mindist3a 'min distance (bound): MINLP formulation of indicator constraint'
    mindist4  'min distance (bound): Linearized big-M formulation'
    tbound    's(i)=s(j)=1 => t(i,j)=1'
    tbounda   's(i)=s(j)=1 => tr(i,j)=1'
    sosbound  "s(i)=s(j)=1 => slack(i,j,'sos1-1')=1" 
    sos_1
    sos_2   
;

mindist1(lt(i,j))..  z =l= dist(i,j);
mindist2(lt(i,j))..  z*s(i)*s(j) =l= dist(i,j);
mindist2a(lt(i,j)).. z*tr(i,j) =l= dist(i,j);
mindist3(lt(i,j))..  z*s(i)*s(j) =l= dist(i,j)*s(i)*s(j);
mindist3a(lt(i,j))..  z*tr(i,j) =l= dist(i,j)*tr(i,j);
mindist4(lt(i,j))..  z =l= dist(i,j) + M(i,j)*(1-s(i)) + M(i,j)*(1-s(j));
tbound(lt(i,j))..    t(i,j) =g= s(i)+s(j)-1;
tbounda(lt(i,j))..   tr(i,j) =g= s(i)+s(j)-1;
count.. sum(i, s(i)) =e= k;

slack.up(lt,'sos1-1') = 1;
sos_1(lt(i,j)).. slack(i,j,'sos1-1') =g= s(i)+s(j)-1;
sos_2(lt(i,j)).. z =l= dist(i,j) + slack(i,j,'sos1-2'); 

* gams indicator constraints are nuts
$onecho > cplex.opt
indic mindist1(i,j)$t(i,j) 1
$offecho

* bounds for the benefit of Baron
z.lo = 0;
z.up = maxd;

model m1 /mindist1, tbound, count/;
model m2 /mindist2, count/;
model m2a /mindist2a, tbounda, count/;
model m3 /mindist3, count/;
model m3a /mindist3a, tbounda, count/;
model m4 /mindist4, count/;
model m5 /sos_1,sos_2, count/;

option reslim = 1000;

m1.optfile=1;
solve m1 maximizing z using mip;
s.l(i) = 0;
solve m2 maximizing z using minlp;
s.l(i) = 0;
solve m2a maximizing z using minlp;
s.l(i) = 0;
solve m3 maximizing z using minlp;
s.l(i) = 0;
solve m3a maximizing z using minlp;
s.l(i) = 0;
solve m4 maximizing z using mip;
s.l(i) = 0;
solve m5 maximizing z using mip;

*-----------------------------------------------------------------
* reporting 
*-----------------------------------------------------------------

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


acronym TimeLimit;

$macro modelresult(name1,type,descr,modelid) \
   results(name1,type,descr,'vars')   = modelid.numvar; \
   results(name1,type,descr,'equs')   = modelid.numequ; \
   results(name1,type,descr,'obj')    = modelid.objval; \
   results(name1,type,descr,'time')   = modelid.resusd; \
   results(name1,type,descr,'nodes')  = modelid.nodusd; \
   results(name1,type,descr,'status')$(modelid.solvestat=3)  = timelimit;
   
   
modelresult('model 1','mip','indic',m1)
modelresult('model 2','minlp','left',m2)
modelresult('model 2a','minlp','left v2',m2a)
modelresult('model 3','minlp','both',m3)
modelresult('model 3a','minlp','both v2',m3a)
modelresult('model 4','mip','bigM',m4)
modelresult('model 5','mip','sos1',m5)

option results:3:3:1;
display size,results;

$onText

----    197 PARAMETER size  

n 100.000,    k  15.000


----    197 PARAMETER results  

                           vars        equs         obj        time       nodes      status

model 1 .mip/indic     5051.000    9901.000      24.589      59.468   46932.000
model 2 .minlp/left     101.000    4951.000      24.589      25.690       1.000
model 2a.minlp/left    5051.000    9901.000      24.589      46.380       3.000
model 3 .minlp/both     101.000    4951.000      24.589      19.550       1.000
model 3a.minlp/both    5051.000    9901.000      24.589      81.670      16.000
model 4 .mip/bigM       101.000    4951.000      24.589       1.719    7819.000
model 5 .mip/sos1     10001.000    9901.000      24.589    1000.453   58989.000   TimeLimit


$offText

*---------------------------------------------------------------------
* visualization
* takes last solution 
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


document.getElementById("expl").innerHTML = "We find k="+sx.length+
  " points out of n="+(sx.length+px.length)+
  ". The length of the shortest line between selected points is maximized. "+
  "This shortest line is colored red and has length "+
  Math.sqrt(shortest).toFixed(3) + ".";


</script>
$offecho

executetool 'win32.ShellExecute "%html%"';

$label skipplot
 