$ontext

  Given n circles or disks (with different radii), find the smallest
  enclosing circle.
  
  We use a NLP model and a SOCP model

$offtext


*---------------------------------------------------------------------
* options
*---------------------------------------------------------------------

* 0: no plot
* 1: produce html plot
$set htmlplot 1

* 0: don't remove circles contained in another circle
* 1: do remove them
$set drop 0
 
option nlp=conopt, qcp = cplex;

*---------------------------------------------------------------------
* data
*---------------------------------------------------------------------

sets
  i 'inner circles' /circle1*circle15/
  a 'attributes for storing results' /x,y,r/
  k(a) 'coordinate' /x,y/
;

alias (i,j);

Parameters
 circles(*,*)   'coordinates of center and radius'
;

circles(i,k) = uniform(0,25);
circles(i,'r') = uniform(1,7);
display circles;


*---------------------------------------------------------------------
* preprocessing
* remove circles inside another one
*---------------------------------------------------------------------
scalar d 'distance between centers';

set ne(i,j) ' not the same';
ne(i,j) = ord(i)<>ord(j);

circles(i,'candrop')=0;
loop(ne(i,j)$(circles(i,'r')<=circles(j,'r') and circles(i,'candrop')=0),

   d = sqrt(sum(k, sqr(circles(i,k)-circles(j,k))));
   circles(i,'candrop')$(d + circles(i,'r') <= circles(j,'r')) = 1;

);
display circles;

set keep(i) 'circle is not dropped from data set';
keep(i) = yes;
keep(i)$%drop% = circles(i,'candrop')=0;
display keep;

*---------------------------------------------------------------------
* NLP Model
*---------------------------------------------------------------------

variables
   c(k)   'center'
   r      'radius'
;

r.lo = smax(keep(i),circles(i,'r'));

*
* initial point calculation
*
parameters
   dist(i) 'distance'
   init(a) 'initial values'
;
init(k) = sum(keep(i),circles(i,k))/card(keep);
dist(keep(i)) = sqrt(sum(k, sqr(init(k)-circles(i,k))));
init('r') = smax(keep(i), dist(i) + circles(i,'r'));
c.l(k) = init(k);
r.l = init('r');

Equations
   inside(i)
;

inside(keep(i))..
  sum(k,sqr(c(k)-circles(i,k))) =l= sqr(r-circles(i,'r'));

model m1 /all/;
solve m1 minimizing r using nlp;

parameter results(*,*);
results('init',a) = init(a);
results('NLP',k) = c.l(k);
results('NLP','r') = r.l;

display results;

*---------------------------------------------------------------------
* SOCP Model
*---------------------------------------------------------------------

variables
   diffc(i,k) 'difference between outer center and inner centers' 
   diffr(i) 'difference between outer radius and inner radii' 
;
positive variable diffr;

* no need for bound on r
r.lo = -INF;

Equations
   calcdiffc(i,k)
   calcdiffr(i)
   inside2(i)
;

calcdiffc(keep(i),k).. diffc(i,k) =e= c(k)-circles(i,k);
calcdiffr(keep(i))..   diffr(i) =e= r-circles(i,'r');
inside2(keep(i))..     sum(k,sqr(diffc(i,k))) =l= sqr(diffr(i));

model m2 /all-m1/;
solve m2 minimizing r using qcp;

results('SOCP',k) = c.l(k);
results('SOCP','r') = r.l;

display results;


*---------------------------------------------------------------------
* visualization
*---------------------------------------------------------------------

$set html  plot.html
$set data  data.js


$if %htmlplot%==0 $goto skipplot

file fdata /%data%/; put fdata;


* plot first not dropped (large) circles
* then plot dropped circles. 
set
   sd /keep,drop,outer/
   sdi(sd,*)   
;
sdi('keep',i)$(not circles(i,'candrop')) = yes;
sdi('drop',i)$circles(i,'candrop') = yes;
sdi('outer','optimal') = yes;
sdi('outer','initial') = yes;

circles('initial','r') = init('r');
circles('initial',k) = init(k);
circles('optimal','r') = r.l;
circles('optimal',k) = c.l(k);
display sdi,circles;

Scalars
   firstred /1/
   firstblue /1/
;

alias (*,item);

* circles
put "circles = ["/;
loop(sdi(sd,item),
  put " {"/;
  put "   type:'circle',"/;
  put "   xref:'x',"/;
  put "   yref:'y',"/;
  put "   x0:",(circles(item,'x')-circles(item,'r')):0:4,","/;
  put "   y0:",(circles(item,'y')-circles(item,'r')):0:4,","/;
  put "   x1:",(circles(item,'x')+circles(item,'r')):0:4,","/;
  put "   y1:",(circles(item,'y')+circles(item,'r')):0:4,","/;
  if (sameas(item,'optimal'),
     put "   line:{color:'Black'},"/;
     put "   name:'optimal solution',"/;
     put "   showlegend:true,"/;
  elseif sameas(item,'initial'),
     put "   line:{color:'Grey'},"/;
     put "   name:'initial solution',"/;
     put "   showlegend:true,"/;
  elseif circles(item,'candrop'),
     put "   line:{color:'Red'},"/;
     put "   fillcolor:'Pink',"/;
     put$firstred "   name:'dropped',"/;
     put$firstred "   showlegend:true,"/;
     firstred = 0;
  else
     put "   line:{color:'Blue'},"/;
     put "   fillcolor:'LightSkyBlue',"/;
     put$firstblue "   name:'data',"/;
     put$firstblue "   showlegend:true,"/;
     firstblue = 0;
  );
  put "   opacity:0.5,"/;  
  put " },"/;
);
put "];"/;

scalars xmin,xmax,ymin,ymax,range0,range1;
xmin = min(init('x')-init('r'),c.l('x')-r.l);
xmax = max(init('x')+init('r'),c.l('x')+r.l);
ymin = min(init('y')-init('r'),c.l('y')-r.l);
ymax = max(init('y')+init('r'),c.l('y')+r.l);
range0 = floor(min(xmin,ymin));
range1 = ceil(max(xmax,ymax));

put "range0=",range0:0:4,";"/;
put "range1=",range1:0:4,";"/;

putclose;

$onecho > %html%
<html>
<script src="https://cdn.plot.ly/plotly-3.4.0.min.js" charset="utf-8"></script>
<script src="%data%" charset="utf-8"></script>
<h1>Smallest Encompassing Circle</h1>
<div id="plotDiv"></div>
<script>

var layout = {
  autosize: false,
  width: 700,
  height: 650,
  showlegend: true,
  shapes: circles,
  xaxis: { range: [range0,range1] },
  yaxis: { range: [range0,range1] } 
}
var options = {staticPlot: true, displayModeBar: false};
Plotly.newPlot('plotDiv', [], layout, options);
</script>
</html>
$offecho

executetool 'win32.ShellExecute "%html%"';

$label skipplot

