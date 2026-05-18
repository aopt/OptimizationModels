$onText

    Largest Empty Rotated Square.
    
    This version: endogenous angle
    This gives us a MINLP model.

$offText



*---------------------------------------------------------------
* options
*---------------------------------------------------------------

* 0: no plot
* 1: produce HTML plot
$set htmlplot 1

* baron, antigone don't have sin(),cos() functions, so we use scip for this example
option minlp=xpress;

option seed=12345;

*---------------------------------------------------------------
* data
*---------------------------------------------------------------

scalar maxsize 'size of the box' / 10 /;

sets
   i     'points' /point1*point100/
   a     'square attributes' /x,y,s/
   c(a)  'coordinates' /x,y/    
;

parameter p(i,c) 'points';
p(i,c) = uniform(0,maxsize);
display p;


*---------------------------------------------------------------
* MINLP MODEL
*---------------------------------------------------------------

scalars  M  'big-M';
M = 2 * maxSize;

set 
   case 'for comparison' /less,greater/
   corners /00,01,10,11/   
;
table offset(corners,c) 'unit offset of corner points from lower-left' 
        x  y
    00  0  0
    01  0  1
    10  1  0  
    11  1  1
;

variable 
   q(i,c) 'transformed data points: rotate by -theta'
   sq(a) 'square location and size (transformed coordinates)'
   sq2(corners,c) 'corner points (original coordinates)'
   theta 'angle of rotation'
;
q.lo(i,c) = -2*maxsize;
q.up(i,c) = 2*maxsize;

theta.lo = 0;
theta.up = 90*pi/180;

sq.lo(a) = -2*maxsize;
sq.up(a) = 2*maxsize;

sq2.lo(corners,c) = 0;
sq2.up(corners,c) = maxsize;

binary variable d(i,c,case) 'd=1 means: relax no-overlap constraint';
variable z 'objective';

Equations
   transfdatax(i) 'transform data points: x coordinate'
   transfdatay(i) 'transform data points: y coordinate'
   emptysq1(i,c)  'no-overlap constraint: less-than version'  
   emptysq2(i,c)  'no-overlap constraint: greater-than version'
   sumd(i)        '(at least) one no-overlap constraint must hold'
   transformx     "transform x',y' -> x back to original coordinates"
   transformy     "transform x',y' -> y back to original coordinates"
   objsq          'objective' 
;

* transform data points
transfdatax(i).. q(i,'x') =e=  p(i,'x')*cos(theta) + p(i,'y')*sin(theta);
transfdatay(i).. q(i,'y') =e= -p(i,'x')*sin(theta) + p(i,'y')*cos(theta);


* this is like the original axis-aligned square model
objsq.. z =e= sq('s');
emptysq1(i,c).. q(i,c) =l= sq(c) + d(i,c,'less')*M;
emptysq2(i,c).. q(i,c) =g= sq(c) + sq('s') - d(i,c,'greater')*M;
sumd(i)..  sum((c,case),d(i,c,case)) =e= 3;

* transform back to original coordinates
transformx(corners).. sq2(corners,'x') =e= (sq('x')+offset(corners,'x')*sq('s'))*cos(theta) - (sq('y')+offset(corners,'y')*sq('s'))*sin(theta); 
transformy(corners).. sq2(corners,'y') =e= (sq('x')+offset(corners,'x')*sq('s'))*sin(theta) + (sq('y')+offset(corners,'y')*sq('s'))*cos(theta); 

*theta.fx = 0; 
*theta.fx = 25*pi/180; 
*theta.fx = 45*pi/180; 

model emptysquare /all/;
solve emptysquare maximizing z using minlp;

display theta.l, sq.l, sq2.l;


parameter square(*,*) 'optimal values';
square(corners,c) = sq2.l(corners,c);
square('side','-') = sq.l('s');
square('area','-') = sqr(square('side','-'));
display square;


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
  put "  {i:'",i.tl:0,"',x:",p(i,'x'):0:4,",y:",p(i,'y'):0:4,"},"/;
);
put "]"/;

put "box={x:0,y:0,size:",maxsize:0:4,"}"/;
put "angle=",theta.l:0:4/; 
put "angledeg=",(theta.l*180/pi):0:4/; 
put "side=",square('side','-'):0:4/;
put "area=",square('area','-'):0:4/;


put "cp=["/;
loop(corners,
  put "  {k:'",corners.tl:0,"',x:",square(corners,'x'):0:4,",y:",square(corners,'y'):0:4,"},"/;
);
put "]"/;
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

<h1>Solution in Original Coordinates</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=3 class="brdr">Rotated Square</td></tr>
<tr><td class="brdr"></td><th class="brdr">&#x1D465;</th><th class="brdr">&#x1D466;</th></tr>
<tr><td class="brdr">Corner 1</td><td class="brdr" id="c00_x"></td><td class="brdr" id="c00_y"></td></tr>
<tr><td class="brdr">Corner 2</td><td class="brdr" id="c01_x"></td><td class="brdr" id="c01_y"></td></tr>
<tr><td class="brdr">Corner 3</td><td class="brdr" id="c10_x"></td><td class="brdr" id="c10_y"></td></tr>
<tr><td class="brdr">Corner 4</td><td class="brdr" id="c11_x"></td><td class="brdr" id="c11_y"></td></tr>
<tr><td class="brdr">Angle</td><td class="brdr" id="sol_angle"></td><td class="brdr"></td></tr>
<tr><td class="brdr">Side</td><td class="brdr" id="sol_side"></td><td class="brdr"></td></tr>
<tr><td class="brdr">Area</td><td class="brdr" id="sol_area"></td><td class="brdr"></td></tr>

</table>
</td><td>
<div id="plotDiv3" style="width: 800px; height: 600px;"></div>
</td></tr></table>


<script>
px = p.map((x) => x['x'])
py = p.map((x) => x['y'])


document.getElementById("c00_x").innerHTML = cp[0]['x'];
document.getElementById("c00_y").innerHTML = cp[0]['y'];
document.getElementById("c01_x").innerHTML = cp[1]['x'];
document.getElementById("c01_y").innerHTML = cp[1]['y'];
document.getElementById("c10_x").innerHTML = cp[2]['x'];
document.getElementById("c10_y").innerHTML = cp[2]['y'];
document.getElementById("c11_x").innerHTML = cp[3]['x'];
document.getElementById("c11_y").innerHTML = cp[3]['y'];

document.getElementById("sol_angle").innerHTML = angledeg+'°';
document.getElementById("sol_side").innerHTML = side;
document.getElementById("sol_area").innerHTML = area;


var path2 = `M ${cp[0]['x']} ${cp[0]['y']} L ${cp[1]['x']} ${cp[1]['y']}  L ${cp[3]['x']} ${cp[3]['y']} L ${cp[2]['x']} ${cp[2]['y']} Z`;


var data1 = {
  x: px,
  y: py,
  mode: 'markers',
  type: 'scatter',
  name: 'data points',
  color: 'darkblue'
};

var layout4 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  title: {text:'Solution'},
  shapes: [{type:'rect',
            xref:'x',
            yref:'y',
            x0:box['x'],
            y0:box['y'],
            x1:box['x']+box['size'],
            y1:box['y']+box['size'],
            line:{color:'black',width:2,opacity:0.5},
            fillcolor:'rgba(0, 250, 250, 0.2)',
            name:'box',
            showlegend:true
            },
           {type:'path',
            path:path2,
            xref:'x',
            yref:'y',
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 150, 150, 0.5)',
            name:'optimal square',
            showlegend:true
            }, 

          ]
}


var trc1 = [data1];

var options1 = {staticPlot: true, displayModeBar: false, responsive: false};
Plotly.newPlot('plotDiv3', trc1, layout4, options1);

</script>
$offecho

executetool 'win32.ShellExecute "%html%"';

$label skipplot
