$onText

   Find smallest axis-aligned rectangle containing k out of n points.
     
   References:
      Timothy M. Chan, Sariel Har-Peled
      Smallest k-Enclosing Rectangle Revisited
      https://arxiv.org/abs/1903.06785

$offtext

*---------------------------------------------------------------
* options
*---------------------------------------------------------------

* 0: no plot
* 1: produce HTML plot)
$set htmlplot 1

option miqcp=antigone;

option seed=12345;

*---------------------------------------------------------------
* data
*---------------------------------------------------------------

scalar maxsize 'size of the outer box' / 10 /;

sets
   i   'points' /point1*point100/
   c   'coordinates' /x,y/    
;

parameter p(i,c) 'points';
p(i,c) = uniform(0,maxsize);
display p;


*---------------------------------------------------------------
* enclose all points (easy)
*---------------------------------------------------------------

Parameter
   rect1(c,*) 'contain all points'
;

rect1(c,'min') = smin(i,p(i,c));
rect1(c,'max') = smax(i,p(i,c));
display rect1;

*---------------------------------------------------------------
* enclose k points 
*---------------------------------------------------------------

scalar k 'number of points (subset)' /25/;

binary variable delta(i) 'point is selected';
variable
   rect2(c,*) 'contain k points'
   d(c)       'length of sides'
   area       'size of rectangle'    
;

* bounds
rect2.lo(c,'min') = smin(i,p(i,c));
rect2.lo(c,'max') = smin(i,p(i,c));
rect2.up(c,'min') = smax(i,p(i,c));
rect2.up(c,'max') = smax(i,p(i,c));

d.lo(c) = 0;
d.up(c) =  smax(i,p(i,c)) - smin(i,p(i,c));


equations
    obj      'objective: area of enclosing rectangle'
    count    'number of points to select'
    inside_min(i,c)  'points are inside'
    inside_max(i,c)  'points are inside'
    calcd(c)         'calculate d' 
;

count..  sum(i, delta(i)) =e= k;

* inside: delta(i)=1  ==> rect2(c,'min') <= p(i,c) <= rect2(c,'max') 
inside_min(i,c)..  rect2(c,'min') =l= delta(i)*p(i,c) + (1-delta(i))*maxsize;
inside_max(i,c)..  rect2(c,'max') =g= delta(i)*p(i,c);

calcd(c).. d(c) =e= rect2(c,'max')-rect2(c,'min');

obj.. area =e= d('x')*d('y');


model m /all/;
solve m minimizing area using miqcp;

display rect2.l,delta.l,area.l;


*---------------------------------------------------------------------
* visualization
*---------------------------------------------------------------------

$set html  plot.html
$set data  data.js

$if %htmlplot%==0 $goto skipplot


file fdata /%data%/; put fdata;

* points
put "p=["/;
loop(i,
  put "  {i:'",i.tl:0,"',x:",p(i,'x'):0:4,",y:",p(i,'y'):0:4,",delta:";
  put$(delta.l(i)>0.5) "'red'";
  put$(delta.l(i)<0.5) "'darkblue'";
  put "},"/;
);
put "]"/;
put "pnts={n:",(card(i)):0:0,
       ",map:'[0,",maxsize:0:0,"]&times;[0,",maxsize:0:0,"]'",
       ",minx:",(smin(i,p(i,'x'))):0:3,
       ",miny:",(smin(i,p(i,'y'))):0:3,
       ",maxx:",(smax(i,p(i,'x'))):0:3,
       ",maxy:",(smax(i,p(i,'y'))):0:3,
       ",avgx:",(sum(i,p(i,'x'))/card(i)):0:3,
       ",avgy:",(sum(i,p(i,'y'))/card(i)):0:3,
       ",k:",k:0:0,
       ",rxmin:",(rect2.l('x','min')):0:3,
       ",rxmax:",(rect2.l('x','max')):0:3,
       ",rymin:",(rect2.l('y','min')):0:3,
       ",rymax:",(rect2.l('y','max')):0:3,
       ",area:",(area.l):0:3,
       "}"/;

putclose;

$onecho > %html%
<html>
<script src="https://cdn.plot.ly/plotly-3.4.0.min.js" charset="utf-8"></script>
<script src="%data%" charset="utf-8"></script>
<style>
.brdr {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding-left: 4px;
  padding-right: 4px;
}
</style>

<h1>Data</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=2 class="brdr">points</th></tr>
<tr><td class="brdr">&#x1D45B;</td><td class="brdr" id="d_n"></td></tr>
<tr><td class="brdr">map</td><td class="brdr" id="d_map"></td></tr>
<tr><td class="brdr">min &#x1D465;</td><td class="brdr" id="d_minx"></td></tr>
<tr><td class="brdr">max &#x1D465;</td><td class="brdr" id="d_maxx"></td></tr>
<tr><td class="brdr">avg &#x1D465;</td><td class="brdr" id="d_avgx"></td></tr>
<tr><td class="brdr">min &#x1D466;</td><td class="brdr" id="d_miny"></td></tr>
<tr><td class="brdr">max &#x1D466;</td><td class="brdr" id="d_maxy"></td></tr>
<tr><td class="brdr">avg &#x1D466;</td><td class="brdr" id="d_avgy"></td></tr>
</table>
</td><td>
<div id="plotDiv0" style="width: 800px; height: 600px;"></div>
</td></tr></table>


<h1>Smallest Rectangle</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=2 class="brdr">solution</th></tr>
<tr><td class="brdr">&#x1D45B;</td><td class="brdr" id="d_n2"></td></tr>
<tr><td class="brdr">&#x1D458;</td><td class="brdr" id="d_k"></td></tr>
<tr><td class="brdr">&#x1D465;min</td><td class="brdr" id="xmin">0</td></tr>
<tr><td class="brdr">&#x1D465;max</td><td class="brdr" id="xmax">0</td></tr>
<tr><td class="brdr">&#x1D466;min</td><td class="brdr" id="ymin">0</td></tr>
<tr><td class="brdr">&#x1D466;max</td><td class="brdr" id="ymax">0</td></tr>
<tr><td class="brdr">area</td><td class="brdr" id="area">0</td></tr>
</table>
</td><td>
<div id="plotDiv1" style="width: 800px; height: 600px;"></div>
</td></tr></table>


<script>

document.getElementById("d_n").innerHTML = pnts['n'];
document.getElementById("d_map").innerHTML = pnts['map'];
document.getElementById("d_minx").innerHTML = pnts['minx'];
document.getElementById("d_maxx").innerHTML = pnts['maxx'];
document.getElementById("d_miny").innerHTML = pnts['miny'];
document.getElementById("d_maxy").innerHTML = pnts['maxy'];
document.getElementById("d_avgx").innerHTML = pnts['avgx'];
document.getElementById("d_avgy").innerHTML = pnts['avgy'];

document.getElementById("d_n2").innerHTML = pnts['n'];
document.getElementById("d_k").innerHTML = pnts['k'];
document.getElementById("xmin").innerHTML = pnts['rxmin'];
document.getElementById("xmax").innerHTML = pnts['rxmax'];
document.getElementById("ymin").innerHTML = pnts['rymin'];
document.getElementById("ymax").innerHTML = pnts['rymax'];
document.getElementById("area").innerHTML = pnts['area'];



px = p.map((x) => x['x'])
py = p.map((x) => x['y'])
delta = p.map((x) => x['delta'])

var data1 = {
  x: px,
  y: py,
  mode: 'markers',
  type: 'scatter',
  name: 'data points',
  color: 'darkblue'
  
};

var layout1 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: false,
  title: {text:"Data Points"},
}


var data2 = {
  x: px,
  y: py,
  mode: 'markers',
  type: 'scatter',
  name: 'solution',
  marker: { color: delta },
  showlegend: false,

};

var layout2 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: false,
  title: {text:"Solution"},
  shapes: [{type:'rect',
            xref:'x',
            yref:'y',
            x0:pnts['rxmin'],
            y0:pnts['rymin'],
            x1:pnts['rxmax'],
            y1:pnts['rymax'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            },]
}


var trc1 = [data1];
var options1 = {staticPlot: true, displayModeBar: false, responsive: false};
Plotly.newPlot('plotDiv0', trc1, layout1, options1);

var trc2 = [data2];
var options2 = {staticPlot: true, displayModeBar: false, responsive: false};
Plotly.newPlot('plotDiv1', trc2, layout2, options2);


</script>
</html>
$offecho

executetool 'win32.ShellExecute "%html%"';

$label skipplot

