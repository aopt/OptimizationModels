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
 
 Model 3:
 We can minimize the distances using a MISOCP (Mixed-Integer
 Second Order Cone program). This takes forever for n=75
 so we skip this here.
 
 Model 4:
 This is a Medoid version: the candidate locations are the
 demand points. This is formulated as a multi-objective
 model, but we can run the objectives (min facilities,
 min sum distances) separately by changing the weights.
 
 Model 5:
 Produce efficient frontier between maxDist and numFacs
 based on Medoid model 4.
 
 Reporting is done using HTML + Plotly. 


$offText


option reslim=1000;
option miqcp=cplex;
option seed=12345;

* third model (MISOCP) is very expensive
* it is better to skip this
* runmodel3=0 : skip model 3
* runmodel3<>0 : run model 3
$set runmodel3 0

* enable (1) or disable (0) symmetry breakers
$set symm 1

* set to 0 if no HTML report
$set runhtml 1  

*-----------------------------------------------------------------------------------------
* data
*-----------------------------------------------------------------------------------------

Sets
   dummy 'for ordering of displays' /numFacs,MaxDist,time/
   i 'demand points'        /demand1*demand75/
   j 'possible facilities'  /facility1*facility10/
   c 'coordinates'          /x,y/
;

Parameters
   dloc(*,c) 'demand point locations'
   maxDist   'maximum distance allowed between facility and demand point (for 1x1 map)' /0.25/
   wh        'width and height of our region' /1/
   symm      "0:don't use 1:use symmetry breakers" /%symm%/
;

maxDist = maxDist*wh;

dloc(i,c) = uniform(0,wh);
dloc('min',c) = smin(i,dloc(i,c));
dloc('max',c) = smax(i,dloc(i,c));
display maxDist,dloc;

*-----------------------------------------------------------------------------------------
* model 1: find minimum number of facilities needed
*          we put some effort into finding small big-M values
*          this is a bit of overkill 
*-----------------------------------------------------------------------------------------


*
* for proper big M calculation we need to know farthest possible distances
*
sets
  LU 'lower or upper' /L,U/
  b(LU,LU) 'box' /L.L, L.U, U.L, U.U/
;
alias (LU,LUx,LUy);
Parameters
    corners(LU,LU,c) 'corners of box for facility locations'
    farthest(i) 'max possible squared distance between demand point i and possible location of facility'
;
corners('L',LUy,'x') = dloc('min','x');
corners('U',LUy,'x') = dloc('max','x');
corners(LUx,'L','y') = dloc('min','y');
corners(LUx,'U','y') = dloc('max','y');
display corners;

farthest(i) = smax(b,sum(c,sqr(dloc(i,c)-corners(b,c))));
display farthest;


*
* model 1:  MIQCP
*
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

distance(i,j).. sum(c, sqr(dloc(i,c)-floc(j,c))) =l= sqr(maxDist)*assign(i,j) + farthest(i)*(1-assign(i,j));

assignDemand(i).. sum(j, assign(i,j)) =e= 1;

closed(i,j).. assign(i,j) =l= isOpen(j);

numFacilities.. nOpen =e= sum(j, isOpen(j));

order(j+1)$symm.. isOpen(j) =g= isOpen(j+1);

* facility locations should be inside the box formed by the demand points 
floc.lo(j,c) = smin(b,corners(b,c));
floc.up(j,c) = smax(b,corners(b,c));

*
* solve
*
model m1 /all/;
solve m1 minimizing nOpen using miqcp;
abort$(m1.modelstat <> %modelStat.optimal% and m1.modelstat <> %modelStat.integerSolution%) "No solution";


*
* collect results
*
set f(j) 'open facilities';
f(j) = isOpen.l(j)>0.5;
display nOpen.l,j,f;

parameter res1(*) 'results model 1';
res1('facilities needed (min)') = round(nOpen.l);
res1('sum squared distances') = sum((i,j)$(assign.l(i,j)>0.5),sum(c, sqr(dloc(i,c)-floc.l(j,c))));
res1('max squared distance') = smax((i,j)$(assign.l(i,j)>0.5),sum(c, sqr(dloc(i,c)-floc.l(j,c))));
res1('sum distances') = sum((i,j)$(assign.l(i,j)>0.5),sqrt(sum(c, sqr(dloc(i,c)-floc.l(j,c)))));
res1('max distance') = smax((i,j)$(assign.l(i,j)>0.5),sqrt(sum(c, sqr(dloc(i,c)-floc.l(j,c)))));
res1('solver time') = m1.resusd;
res1('nodes') = m1.nodusd;
res1('binary variables') = m1.numdvar;
display res1;

set assign1(i,j) 'model1 results';
assign1(i,j) = assign.l(i,j)>0.5;

parameter floc1(j,c) 'model1 results';
floc1(f,c) = floc.l(f,c);  


*-----------------------------------------------------------------------------------------
* model 2: find optimal assignment of customer to open facilities
*          minimize sum of squared distances
*-----------------------------------------------------------------------------------------


positive variable d2(i,j) 'squared distance between customer and facility';

variable totdist2 'sum of squared distances';

equations
   distance2(i,j)   'squared distance equation'
   assignDemandf(i) 'assign customer to exactly one facility'
   objective2       'minimize sum of squared distances'
   orderx(j)        'order by x coordinate'
;

objective2.. totdist2 =e= sum((i,f),d2(i,f)); 

distance2(i,f).. d2(i,f) =g= sum(c, sqr(dloc(i,c)-floc(f,c))) - farthest(i)*(1-assign(i,f));

assignDemandf(i).. sum(f, assign(i,f)) =e= 1;

orderx(j+1)$(f(j) and symm).. floc(j,'x') =l= floc(j+1,'x');

d2.up(i,f) = sqr(maxDist);

model m2 /objective2,distance2,assignDemandf,orderx/;
solve m2 minimizing totdist2 using miqcp;
abort$(m2.modelstat <> %modelStat.optimal% and m2.modelstat <> %modelStat.integerSolution%) "No solution";

display totdist2.l, assign.l

parameter res2(*) 'results model 2';
res2('sum squared distances (min)') = sum((i,f)$(assign.l(i,f)>0.5),sum(c, sqr(dloc(i,c)-floc.l(f,c))));
res2('max squared distance') = smax((i,f)$(assign.l(i,f)>0.5),sum(c, sqr(dloc(i,c)-floc.l(f,c))));
res2('sum distances') = sum((i,f)$(assign.l(i,f)>0.5),sqrt(sum(c, sqr(dloc(i,c)-floc.l(f,c)))));
res2('max distance') = smax((i,f)$(assign.l(i,f)>0.5),sqrt(sum(c, sqr(dloc(i,c)-floc.l(f,c)))));
res2('solver time') = m2.resusd;
res2('nodes') = m2.nodusd;
res2('binary variables') = m2.numdvar;
display res2;

set assign2(i,j) 'model2 results';
assign2(i,f) = assign.l(i,f)>0.5;

parameter floc2(j,c) 'model2 results';
floc2(f,c) = floc.l(f,c);


*-----------------------------------------------------------------------------------------
* model 3: find optimal assignment of customer to open facilities
*          minimize sum of distances
*          MISOCP formulation
* this is too slow for larger data sets
*-----------------------------------------------------------------------------------------

$if %runmodel3%==0 $goto skipmodel3

positive variable
   dall(i,j) 'distance between all customers and facilities'
   d(i,j)    'distance between assigned customers and facilities or 0' 
;

free variables
   totdist 'sum of distances'
   diff(i,j,c) 'facility - customer'
;

equations
   objective       'minimize sum of distances'
   socp(i,j)       'second order cone constraint'
   ediff(i,j,c)    'difference coordinatewise'
   calcd(i,j)      'big-M version of implication'
;

objective.. totdist =e= sum((i,f),d(i,f));
ediff(i,f,c).. diff(i,f,c) =e= dloc(i,c)-floc(f,c);
socp(i,f).. sqr(dall(i,f)) =g= sum(c,sqr(diff(i,f,c)));
calcd(i,f).. d(i,f) =g= dall(i,f) - sqrt(farthest(i))*(1-assign(i,f));

dall.up(i,f) = sqrt(farthest(i));
d.up(i,f) = sqrt(farthest(i));

model m3 /objective,ediff,socp,calcd,assignDemandf,orderx/;
m3.optfile=1;
solve m3 minimizing totdist using miqcp;
abort$(m3.modelstat <> %modelStat.optimal% and m3.modelstat <> %modelStat.integerSolution%) "No solution";

display totdist.l, assign.l

parameter res3(*) 'results model 3';
res3('sum squared distances') = sum((i,f)$(assign.l(i,f)>0.5),sum(c, sqr(dloc(i,c)-floc.l(f,c))));
res3('max squared distance') = smax((i,f)$(assign.l(i,f)>0.5),sum(c, sqr(dloc(i,c)-floc.l(f,c))));
res3('sum distances (min)') = sum((i,f)$(assign.l(i,f)>0.5),sqrt(sum(c, sqr(dloc(i,c)-floc.l(f,c)))));
res3('max distance') = smax((i,f)$(assign.l(i,f)>0.5),sqrt(sum(c, sqr(dloc(i,c)-floc.l(f,c)))));
res3('solver time') = m3.resusd;
res3('nodes') = m3.nodusd;
res3('binary variables') = m3.numdvar;
display res3;

set assign3(i,j) 'model3 results';
assign3(i,f) = assign.l(i,f)>0.5;

parameter floc3(j,c) 'model3 results';
floc3(f,c) = floc.l(f,c);

$onecho > cplex.opt
mipstart 1
mipstrategy 4
$offecho

$label skipmodel3


*-----------------------------------------------------------------------------------------
* Model 4: k-mediods model
*-----------------------------------------------------------------------------------------

alias (i,ii);
parameter dist(i,ii) 'any distance measure, here the euclidean distance';
dist(i,ii) = sqrt(sum(c, sqr(dloc(i,c)-dloc(ii,c))));

scalars
   w1 'obj weight: distance'
   w2 'obj weight: number of facilities'
;

binary variables
   facSelect(i) 'select point i as facility'
   assigni(i,ii) 'assign demand point i to facility ii'
;

positive variables
    totDist  'obj1: sum of distances'
    numFacs  'obj2: number of facilities'
;

variable z 'objective';

Equations
   objMultiple 'weighted sum objective'
   objDist     'obj1: sum of distances'
   objNumFacs  'obj2: number of facilities'
   eAssign(i)  'each customer must be assigned to one facility' 
   close(i,i)  'if point i is not a facility, then we can not serve customers from there'
;

set ok(i,ii) 'allowed assignments';
ok(i,ii) =  sqrt(sum(c, sqr(dloc(i,c)-dloc(ii,c)))) <= maxDist;

* bi-objective
objMultiple.. z =e= w1*totDist+w2*numFacs;
objDist..     totDist =e= sum(ok(i,ii),dist(ok)*assigni(ok));
objNumFacs..  numFacs =e= sum(i,facSelect(i));

* constraints
eAssign(i)..  sum(ok(i,ii),assigni(ok)) =e= 1;
close(ok(i,ii)).. assigni(ok) =l= facSelect(ii);

model m4 /objMultiple,objDist,objNumFacs,eAssign,close/;

parameter res4(*) 'results model 4';

* we solve in two phases:
* 1. minimize number of facilities needed
* 2. fix numFacs and minimize sum of distances

w1 = 0; w2 = 1;
solve m4 minimizing z using mip;
display numfacs.l;
res4('solver time (min numFacs)') = m4.resusd;
res4('nodes (min numFacs)') = m4.nodusd;
res4('binary variables (min numFacs)') = m4.numdvar;
res4('number of facilities') = round(numFacs.l);

numfacs.fx = round(numfacs.l);
w1 = 1; w2 = 0;
solve m4 minimizing z using mip;
res4('solver time (min totDist)') = m4.resusd;
res4('nodes (min totDist)') = m4.nodusd;
res4('binary variables (min totDist)') = m4.numdvar;


res4('sum squared distances') = sum(ok(i,ii)$(assigni.l(i,ii)>0.5),sum(c, sqr(dloc(i,c)-dloc(ii,c))));
res4('max squared distance') = smax(ok(i,ii)$(assigni.l(i,ii)>0.5),sum(c, sqr(dloc(i,c)-dloc(ii,c))));
res4('sum distances (min)') = sum(ok(i,ii)$(assigni.l(i,ii)>0.5),sqrt(sum(c, sqr(dloc(i,c)-dloc(ii,c)))));
res4('max distance') = smax(ok(i,ii)$(assigni.l(i,ii)>0.5),sqrt(sum(c, sqr(dloc(i,c)-dloc(ii,c)))));
display res4;

set assign4(i,i) 'model4 results';
assign4(ok) = assigni.l(ok)>0.5;

set facSelected(i) 'facilities selected';
facSelected(i) = facSelect.l(i) > 0.5;
display facSelected;

parameter ordFac(i) 'numbering for coloring';
ordFac(FacSelected) = facSelected.pos;
display ordFac;

*-----------------------------------------------------------------------------------------
* Model 5: trace trade-off between max distance and number of facilities
*-----------------------------------------------------------------------------------------

variable zmaxdist 'objective: minimize maxdist';

ok(i,ii) = yes;

equations
*   maxDistance(i,ii) 'assign(i,ii)=1 ==> dist(i,ii) <= maxdist'
   maxDistance(i) 'assign(i,ii)=1 ==> dist(i,ii) <= maxdist'
;
scalar fxNumFacs 'fixed number of facilities';

*maxDistance(i,ii).. assigni(i,ii)*dist(i,ii) =l= zmaxdist;
maxDistance(i).. sum(ii,assigni(i,ii)*dist(i,ii)) =l= zmaxdist;

zmaxDist.lo = 0;

model m5 /maxDistance,objNumFacs,eAssign,close/;

set k /k1*k10/;
parameter m5results(k,*);
loop (k,
   numFacs.fx = ord(k);
   solve m5 minimizing zmaxdist using mip;
   abort$(m5.modelstat <> %modelStat.optimal% and m5.modelstat <> %modelStat.integerSolution%) "No solution";
   m5results(k,'numFacs') = ord(k);
   m5results(k,'maxDist') = zmaxdist.l;
   m5results(k,'time') = m5.resusd;
   m5results(k,'nodes') = m5.nodusd;
);
display m5results;


*-----------------------------------------------------------------------------------------
* reporting and visualization (models 1, 2 and 4)
*-----------------------------------------------------------------------------------------

$if %runhtml%==0 $stop

$set htmlfile report.html
$set datafile data.js

$macro tablerow(txt,num) '<tr><td>txt</td><td align="right"><pre>',num,'</pre></td></tr>'/;
$macro tableheaderrow(txt1,txt2) '<tr><th>txt1</th><th>txt2</th></tr>'/;
$macro tablerow2(num1,num2) '<tr><td align="right"><pre>',num1,'</td><td align="right"><pre>',num2,'</pre></td></tr>'/;

file fdata /%datafile%/;
put fdata;

* demand points
put "datatable=`"/;
put '<table>'/;
put tablerow(Demand points,card(i):0:0)
put tablerow(Max distance customer → facility,maxDist:7:3)
put '</table>'/;
put "`;"/;
put "points=["/;
loop(i,
   put "{x:",dloc(i,'x'):6:4,",y:",dloc(i,'y'):6:4,"},"/;
);
put "];"/;

* model 1
put "m1table=`"/;
put '<table>'/;
put tablerow(Number facilities needed (min),res1('facilities needed (min)'):0:0)
put tablerow(Sum distances,res1('sum distances'):8:3)
put tablerow(Sum squared distances,res1('sum squared distances'):8:3)
put tablerow(Max distance,res1('max distance'):8:3)
put tablerow(Binary variables,res1('binary variables'):0:0);
put tablerow(Solver time,res1('solver time'):8:3)
put tablerow(Nodes,res1('nodes'):0:0)
put '</table>'/;
put "`;"/;
put "floc1=["/;
loop(f,
   put "{x:",floc1(f,'x'):8:4,",y:",floc1(f,'y'):8:4,"},"/;
);
put "];"/;
put "assign1=["/;
loop(assign1(i,f),
   put "{i:",ord(i):0:0,",f:",f.pos:0:0,"},"/;
);
put "];"/;

* model 2
put "m2table=`"/;
put '<table>'/;
put tablerow(Sum squared distances (min),res2('sum squared distances (min)'):8:3)
put tablerow(Sum distances,res2('sum distances'):8:3)
put tablerow(Max distance,res2('max distance'):8:3)
put tablerow(Binary variables,res2('binary variables'):0:0)
put tablerow(Solver time,res2('solver time'):8:3)
put tablerow(Nodes,res2('nodes'):0:0)
put '</table>'/;
put "`;"/;
put "floc2=["/;
loop(f,
   put "{x:",floc2(f,'x'):6:4,",y:",floc2(f,'y'):6:4,"},"/;
);
put "];"/;
put "assign2=["/;
loop(assign2(i,f),
   put "{i:",ord(i):0:0,",f:",f.pos:0:0,"},"/;
);
put "];"/;

* model 4
put "m4table=`"/;
put '<table>'/;
put tablerow(Number of facilities,res4('number of facilities'):0:0)
put tablerow(Sum squared distances,res4('sum squared distances'):8:3)
put tablerow(Sum distances (min),res4('sum distances (min)'):8:3)
put tablerow(Max distance,res4('max distance'):8:3)
put tablerow(Binary variables (min numFacs),res4('binary variables (min numFacs)'):0:0)
put tablerow(Solver time (min numFacs),res4('solver time (min numFacs)'):8:3)
put tablerow(Nodes (min numFacs),res4('nodes (min numFacs)'):0:0)
put tablerow(Binary variables (min totDist),res4('binary variables (min totDist)'):0:0)
put tablerow(Solver time (min totDist),res4('solver time (min totDist)'):8:3)
put tablerow(Nodes (min totDist),res4('nodes (min totDist)'):0:0)
put '</table>'/;
put "`;"/;
put "assign4=["/;
loop(assign4(i,ii),
   put "{i:",ord(i):0:0,",ii:",ord(ii):0:0,",cl:",ordFac(ii):0:0,"},"/;
);
put "];"/;


* model 5
put "frontier=["/;
loop(k,
   put "{maxdist:",m5results(k,'maxDist'):8:3,",numfacs:",m5results(k,'numFacs'):8:3,"},"/;
);
put "];"/;
put "m5table=`"/;
put '<table>'/;
put tableheaderrow(numFacs,maxDist)
loop(k,
   put tablerow2(m5results(k,'numFacs'):8:3,m5results(k,'maxDist'):8:3)
);
put '</table>'/;
put "`;"/;
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

<h2>Model 4: results</h2>

<p>Model 4 uses the demand points as candidate locations for the facilities. This
is an easy MIP. It is solved here in two stages: first find the optimal number of
facilities and then find the best locations.</p>

<div id="m4Table"></div>
<div id="myPlot4" style="width:100%;max-width:700px;height:700px"></div>

<h2>Model 5: results</h2>

<p>Model 5 is tracing the trade-off between <span style="font-family: courier;">maxdist</span> (the maximum distance
limit) and <span style="font-family: courier;">numfacs</span> (the number of facilities). The results are based on
Medoid based model: the candidate locations of the facilities is the set of demand
points.</p>

<div id="m5Table"></div>
<div id="myPlot5" style="width:100%;max-width:700px;height:700px"></div>

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
document.getElementById('m4Table').innerHTML = m4table;
document.getElementById('m5Table').innerHTML = m5table;

// extract coordinates as arrays 
xpoints = points.map(({x})=>x);
ypoints = points.map(({y})=>y);
xfloc1 = floc1.map(({x})=>x);
yfloc1 = floc1.map(({y})=>y);
xfloc2 = floc2.map(({x})=>x);
yfloc2 = floc2.map(({y})=>y);
numfacs = frontier.map(({numfacs})=>numfacs);
maxdist = frontier.map(({maxdist})=>maxdist);


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

trace4 = {
  x: numfacs,
  y: maxdist,
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
      line: { color:colors[f],width:2 }
      }
   assignments.push(asg);   
} 
var layout2 = {showlegend: false, shapes:assignments};

assignments2 = [];
for (k=0; k < assign2.length; ++k) {
   item = assign2[k];
   i = item['i']-1;
   f = item['f']-1;
   ff = f % colors.length;
   asg = {
      type:'line',
      x0:xpoints[i],
      y0:ypoints[i],
      x1:xfloc2[f],
      y1:yfloc2[f],
      line: { color:colors[ff],width:2 }
      }
   assignments2.push(asg);   
} 
var layout3 = {showlegend: false, shapes:assignments2};


assignments4 = [];
for (k=0; k < assign4.length; ++k) {
   item = assign4[k];
   i = item['i']-1;
   ii = item['ii']-1;
   cl = item['cl']-1;
   ff = cl % colors.length;
   asg = {
      type:'line',
      x0:xpoints[i],
      y0:ypoints[i],
      x1:xpoints[ii],
      y1:ypoints[ii],
      line: { color:colors[ff],width:2 }
      }
   assignments4.push(asg);   
} 
var layout4 = {showlegend: false, shapes:assignments4};


var layout5 = {
                xaxis : {title:{text:'number of facilities'}},
                yaxis : {title:{text:'max distance'}},
              }

Plotly.newPlot('myPlot1', [trace1]);
Plotly.newPlot('myPlot2', [trace1,trace2], layout2);
Plotly.newPlot('myPlot3', [trace1,trace3], layout3);
Plotly.newPlot('myPlot4', [trace1], layout4);
Plotly.newPlot('myPlot5', [trace4], layout5);



</script>
</body>
</html>
$offEcho

executetool 'win32.ShellExecute "%htmlfile%"';
