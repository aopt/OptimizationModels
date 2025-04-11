$onText

 Continuous Facility Location
 
 Model 1:
 Find number of facilities needed to service all customers with
 constraint on the distance between facility and customer.
 
 Model 2:
 Given the number of facilities found in model 1, find an optimal
 location of these facilities (by minimizing the sum of squared
 distances) and the optimal assignment of customers to
 facilities.

$offText

*-----------------------------------------------------------------------------------------
* data
*-----------------------------------------------------------------------------------------

option seed = 12345;

Sets
   i 'demand points' /demand1*demand75/
   j 'facilities'    /facility1*facility10/
   c 'coordinates'   /x,y/
;

Parameters
   dloc(i,c) 'demand point locations'
   maxDist   'maximum distance allowed between facility and demand point' /0.25/
   wh        'width and height of our region' /1/
;

dloc(i,c) = uniform(0,wh);

*-----------------------------------------------------------------------------------------
* model 1: find minimum number of facilities needed
*-----------------------------------------------------------------------------------------
   
scalar M 'big M constant';
M = sqr(wh);

variables
    floc(j,c)   'facility locations'
    isOpen(j)   'facility is being used'
    assign(i,j) 'assign customers to facility'
    nOpen       'number of open facilities'
;
binary variables isOpen,assign;

equations
   distance(i,j)   'squared distance equation'
   assignDemand(i) 'assign customer to exactly one facility'
   closed(i,j)     'do not assign customers to closed facilties'
   numFacilities   'number of open facilities'
   order(j)        'optional: open facilities are first ones'
;

distance(i,j).. sum(c, sqr(dloc(i,c)-floc(j,c))) =l= sqr(maxDist) + M*(1-assign(i,j));

assignDemand(i).. sum(j, assign(i,j)) =e= 1;

closed(i,j).. assign(i,j) =l= isOpen(j);

numFacilities.. nOpen =e= sum(j, isOpen(j));

order(j+1).. isOpen(j) =g= isOpen(j+1);

model m1 /all/;
option miqcp=cplex;
solve m1 minimizing nOpen using miqcp;
abort$(m1.modelstat <> %modelStat.optimal% and m1.modelstat <> %modelStat.integerSolution%) "No solution";
display nOpen.l;

parameter res1(*) 'results model 1';
res1('facilities needed') = round(nOpen.l);
res1('sum squared distances') = sum((i,j)$(assign.l(i,j)>0.5),sum(c, sqr(dloc(i,c)-floc.l(j,c))));
res1('max squared distance') = smax((i,j)$(assign.l(i,j)>0.5),sum(c, sqr(dloc(i,c)-floc.l(j,c))));
res1('solver time') = m1.resusd;
res1('binary variables') = m1.numdvar;
display res1;

set f(j) 'open facilities';
f(j) = isOpen.l(j)>0.5;

set assign1(i,j) 'model1 results';
assign1(i,j) = assign.l(i,j)>0.5;

parameter floc1(j,c) 'model1 results';
floc1(f,c) = floc.l(f,c);  

*-----------------------------------------------------------------------------------------
* model 2: find optimal assignment of customer to open facilities
*-----------------------------------------------------------------------------------------


positive variable d(i,j) 'squared distance between customer and facility';

variable totdist 'sum of squared distances';

equations
   distance2(i,j)   'squared distance equation'
   assignDemand2(i) 'assign customer to exactly one facility'
   objective        'minimize sum of squared distances'
   orderx(j)        'order by x coordinate'
;

objective.. totdist =e= sum((i,f),d(i,f)); 

distance2(i,f).. d(i,f) =g= sum(c, sqr(dloc(i,c)-floc(f,c))) - M*(1-assign(i,f));

assignDemand2(i).. sum(f, assign(i,f)) =e= 1;

orderx(j+1)$f(j).. floc(j,'x') =l= floc(j+1,'x');

d.up(i,f) = sqr(maxDist);

model m2 /objective,distance2,assignDemand2/;
solve m2 minimizing totdist using miqcp;
abort$(m2.modelstat <> %modelStat.optimal% and m2.modelstat <> %modelStat.integerSolution%) "No solution";

display totdist.l, assign.l

parameter res2(*) 'results model 2';
res2('sum squared distances') = sum((i,f)$(assign.l(i,f)>0.5),sum(c, sqr(dloc(i,c)-floc.l(f,c))));
res2('max squared distance') = smax((i,f)$(assign.l(i,f)>0.5),sum(c, sqr(dloc(i,c)-floc.l(f,c))));
res2('solver time') = m2.resusd;
res2('binary variables') = m2.numdvar;
display res2;

set assign2(i,j) 'model2 results';
assign2(i,f) = assign.l(i,f)>0.5;

parameter floc2(j,c) 'model2 results';
floc2(f,c) = floc.l(f,c);  


*-----------------------------------------------------------------------------------------
* visualization
*-----------------------------------------------------------------------------------------

$set htmlfile report.html
$set datafile data.js


file fdata /%datafile%/;
put fdata;
put "datatable=`"/;
put '<table>'/;
put '<tr><td>Demand points</td><td align="right"><pre>',card(i):0:0,'</pre></td></tr>'/;
put '<tr><td>Map size (width and height)</td><td align="right"><pre>',wh:7:3,'</pre></td></tr>'/;
put '<tr><td>Max distance customer → facility</td><td align="right"><pre>',maxDist:7:3,'</pre></td></tr>'/;
put '<tr><td>Max squared distance customer → facility</td><td align="right"><pre>',sqr(maxDist):7:3,'</pre></td></tr>'/;
put '</table>'/;
put "`;"/;
put "points=["/;
loop(i,
   put "{x:",dloc(i,'x'):6:4,",y:",dloc(i,'y'):6:4,"},"/;
);
put "];"/;
put "m1table=`"/;
put '<table>'/;
put '<tr><td>Number facilities needed</td><td align="right"><pre>',res1('facilities needed'):0:0,'</pre></td></tr>'/;
put '<tr><td>Sum squared distances</td><td align="right"><pre>',res1('sum squared distances'):7:3,'</pre></td></tr>'/;
put '<tr><td>Max squared distance</td><td align="right"><pre>',res1('max squared distance'):7:3,'</pre></td></tr>'/;
put '<tr><td>Solver time</td><td align="right"><pre>',res1('solver time'):7:3,'</pre></td></tr>'/;
put '<tr><td>Binary variables</td><td align="right"><pre>',res1('binary variables'):0:0,'</pre></td></tr>'/;
put '</table>'/;
put "`;"/;
put "floc1=["/;
loop(f,
   put "{x:",floc1(f,'x'):6:4,",y:",floc1(f,'y'):6:4,"},"/;
);
put "];"/;
put "assign1=["/;
loop(assign1(i,f(j)),
   put "{i:",ord(i):0:0,",f:",ord(j):0:0,"},"/;
);
put "];"/;
put "m2table=`"/;
put '<table>'/;
put '<tr><td>Sum squared distances</td><td align="right"><pre>',res2('sum squared distances'):7:3,'</pre></td></tr>'/;
put '<tr><td>Max squared distance</td><td align="right"><pre>',res2('max squared distance'):7:3,'</pre></td></tr>'/;
put '<tr><td>Solver time</td><td align="right"><pre>',res2('solver time'):7:3,'</pre></td></tr>'/;
put '<tr><td>Binary variables</td><td align="right"><pre>',res2('binary variables'):0:0,'</pre></td></tr>'/;
put '</table>'/;
put "`;"/;
put "floc2=["/;
loop(f,
   put "{x:",floc2(f,'x'):6:4,",y:",floc2(f,'y'):6:4,"},"/;
);
put "];"/;
put "assign2=["/;
loop(assign2(i,f(j)),
   put "{i:",ord(i):0:0,",f:",ord(j):0:0,"},"/;
);
put "];"/;

putclose;

$onecho > %htmlfile%
<html>
<script src="https://cdn.plot.ly/plotly-3.0.1.min.js" charset="utf-8"></script>
<script src="%datafile%" charset="utf-8"></script>
<style>
table,th, td {
    border: 1px solid black;
    border-collapse: collapse;
    padding-left: 10px;
    padding-right: 10px;
}
p { max-width:800px; }
</style>
<body>
<h1>Facility Location Model</h1>
<h2>Data: demand points</h2>
<p>The location of the demand points are randomly generated and drawn from the uniform distribution.</p>
<div id="dataTable"></div>
<div id="myPlot1" style="width:100%;max-width:700px;height:700px"></div>

<p>

<h2>Model 1: results</h2>

<p>Model 1 finds the minimum number of facilities needed to serve all customers and
obey the maximum distance constraint. To make the model quadratic, the constraint is
formulated as a maximum quadratic distance constraint. It is noted that the solution
is <b>not</b> an assignment with shortest distances between customers and facilities.</p>

<div id="m1Table"></div>
<div id="myPlot2" style="width:100%;max-width:700px;height:700px"></div>

<h2>Model 2: results</h2>

<p>Model 2 find the best location of the facilities and the optimal assignment of
customers to the facilities. It uses the number of facilities found in model 1.</p>

<div id="m2Table"></div>
<div id="myPlot3" style="width:100%;max-width:700px;height:700px"></div>

<script>

colors = [
    '#1f77b4',  // muted blue
    '#ff7f0e',  // safety orange
    '#2ca02c',  // cooked asparagus green
    '#d62728',  // brick red
    '#9467bd',  // muted purple
    '#8c564b',  // chestnut brown
    '#e377c2',  // raspberry yogurt pink
    '#7f7f7f',  // middle gray
    '#bcbd22',  // curry yellow-green
    '#17becf'   // blue-teal
];

document.getElementById('dataTable').innerHTML = datatable;
document.getElementById('m1Table').innerHTML = m1table;
document.getElementById('m2Table').innerHTML = m2table;

// extract coordinates as arrays 
xpoints = points.map(({x})=>x);
ypoints = points.map(({y})=>y);
xfloc1 = floc1.map(({x})=>x);
yfloc1 = floc1.map(({y})=>y);
xfloc2 = floc2.map(({x})=>x);
yfloc2 = floc2.map(({y})=>y);

trace1 = {
  x: xpoints,
  y: ypoints,
  mode: 'markers',
  type: 'scatter',
  marker: { color: 'black' }
};

trace2 = {
  x: xfloc1,
  y: yfloc1,
  mode: 'markers',
  type: 'scatter',
  marker: { color: colors },
};

trace3 = {
  x: xfloc2,
  y: yfloc2,
  mode: 'markers',
  type: 'scatter',
  marker: { color: colors },
};


assignments = [];
for (k=0; k < assign1.length; ++k) {
   item = assign1[k];
   i = item['i']-1;
   f = item['f']-1;
   asg = {
      type:'line',
      x0:xpoints[i],
      y0:ypoints[i],
      x1:xfloc1[f],
      y1:yfloc1[f],
      line: { color:colors[f] }
      }
   assignments.push(asg);   
} 
var layout2 = {showlegend: false, shapes:assignments};

assignments2 = [];
for (k=0; k < assign2.length; ++k) {
   item = assign2[k];
   i = item['i']-1;
   f = item['f']-1;
   asg = {
      type:'line',
      x0:xpoints[i],
      y0:ypoints[i],
      x1:xfloc2[f],
      y1:yfloc2[f],
      line: { color:colors[f] }
      }
   assignments2.push(asg);   
} 
var layout3 = {showlegend: false, shapes:assignments2};


Plotly.newPlot('myPlot1', [trace1]);
Plotly.newPlot('myPlot2', [trace1,trace2], layout2);
Plotly.newPlot('myPlot3', [trace1,trace3], layout3);

</script>
</body>
</html>
$offEcho

executetool 'win32.ShellExecute "%htmlfile%"';
