$onText

    Largest Empty Rotated Square.
    
    This version: exogenous angle
    This gives us a MIP model.


$offText



*---------------------------------------------------------------
* options
*---------------------------------------------------------------

* 0: no plot
* 1: produce HTML plot
$set htmlplot 1

* this model turned to linear
option mip=cplex;

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
* MIP MODEL
*---------------------------------------------------------------

scalars
   angle 'degrees' / 25 /
   theta 'angle in radians'
   M  'big-M'
;
M = 2 * maxSize;
theta = angle*pi/180;
display theta;


*
* transform data points
*
parameter q(i,c) 'transformed data points: rotate by -theta';
q(i,'x') =  p(i,'x')*cos(theta) + p(i,'y')*sin(theta);
q(i,'y') = -p(i,'x')*sin(theta) + p(i,'y')*cos(theta);
display q;


*
* transform corner points (for picture)
* not used in the model, but useful for visualization
*

set k 'corner points box' /0-0, 0-1, 1-0, 1-1/;
parameter box(k,c) 'box corners';   
box('0-0','x') = 0; box('0-0','y') = 0;
box('0-1','x') = 0; box('0-1','y') = maxsize;
box('1-0','x') = maxsize; box('1-0','y') = 0;
box('1-1','x') = maxsize; box('1-1','y') = maxsize;
display box;

parameter tbox(k,c) 'box corners (transformed)';
tbox(k,'x') =  box(k,'x')*cos(theta) + box(k,'y')*sin(theta);
tbox(k,'y') = -box(k,'x')*sin(theta) + box(k,'y')*cos(theta);
display tbox;


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
   sq(a) 'square location and size (transformed coordinates)'
   sq2(corners,c) 'corner points (original coordinates)'
;
sq2.lo(corners,c) = 0;
sq2.up(corners,c) = maxsize;

binary variable d(i,c,case) 'd=1 means: relax no-overlap constraint';
variable z 'objective';

Equations
   emptysq1(i,c) 'no-overlap constraint: less-than version'  
   emptysq2(i,c) 'no-overlap constraint: greater-than version'
   sumd(i)       '(at least) one no-overlap constraint must hold'
   transformx    "transform x',y' -> x back to original coordinates"
   transformy    "transform x',y' -> y back to original coordinates"
   objsq         'objective' 
;

* this is like the original axis-aligned square model
objsq.. z =e= sq('s');
emptysq1(i,c).. q(i,c) =l= sq(c) + d(i,c,'less')*M;
emptysq2(i,c).. q(i,c) =g= sq(c) + sq('s') - d(i,c,'greater')*M;
sumd(i)..  sum((c,case),d(i,c,case)) =e= 3;

* transform back to original coordinates
transformx(corners).. sq2(corners,'x') =e= (sq('x')+offset(corners,'x')*sq('s'))*cos(theta) - (sq('y')+offset(corners,'y')*sq('s'))*sin(theta); 
transformy(corners).. sq2(corners,'y') =e= (sq('x')+offset(corners,'x')*sq('s'))*sin(theta) + (sq('y')+offset(corners,'y')*sq('s'))*cos(theta); 

model emptysquare /all/;
solve emptysquare maximizing z using mip;

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

put "q=["/;
loop(i,
  put "  {i:'",i.tl:0,"',x:",q(i,'x'):0:4,",y:",q(i,'y'):0:4,"},"/;
);
put "]"/;

put "box={x:0,y:0,size:",maxsize:0:4,"}"/;
put "angle=",angle:0:4/; 

put "tbox=["/;
loop(k,
  put "  {k:'",k.tl:0,"',x:",tbox(k,'x'):0:4,",y:",tbox(k,'y'):0:4,"},"/;
);
put "]"/;

put "tr_sq={x:",sq.l('x'):0:4,",y:",sq.l('y'):0:4,",side:",sq.l('s'):0:4,",area:",(sq.l('s')**2):0:4,"}"/;

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

<h1>Data</h1>
<table>
<tr><td>
<div id="plotDiv0" style="width: 800px; height: 600px;"></div>
</td><td>
<div id="plotDiv1" style="width: 800px; height: 600px;"></div>
</td></tr></table>

<h1>Solution in Transformed Coordinates</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=2 class="brdr">Square</td></tr>
<tr><td class="brdr">&#x1D465;'</td><td class="brdr" id="tr_x"></td></tr>
<tr><td class="brdr">&#x1D466;'</td><td class="brdr" id="tr_y"></td></tr>
<tr><td class="brdr">side</td><td class="brdr" id="tr_s"></td></tr>
<tr><td class="brdr">area</td><td class="brdr" id="tr_area"></td></tr>
</table>
</td><td>
<div id="plotDiv2" style="width: 800px; height: 600px;"></div>
</td></tr></table>

<h1>Solution in Original Coordinates</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=3 class="brdr">Rotated Square</td></tr>
<tr><td class="brdr"></td><th class="brdr">&#x1D465;</th><th class="brdr">&#x1D466;</th></tr>
<tr><td class="brdr">Corner 1</td><td class="brdr" id="c00_x"></td><td class="brdr" id="c00_y"></td></tr>
<tr><td class="brdr">Corner 2</td><td class="brdr" id="c01_x"></td><td class="brdr" id="c01_y"></td></tr>
<tr><td class="brdr">Corner 3</td><td class="brdr" id="c10_x"></td><td class="brdr" id="c10_y"></td></tr>
<tr><td class="brdr">Corner 4</td><td class="brdr" id="c11_x"></td><td class="brdr" id="c11_y"></td></tr>
</table>
</td><td>
<div id="plotDiv3" style="width: 800px; height: 600px;"></div>
</td></tr></table>


<script>
px = p.map((x) => x['x'])
py = p.map((x) => x['y'])
qx = q.map((x) => x['x'])
qy = q.map((x) => x['y'])

document.getElementById("tr_x").innerHTML = tr_sq['x'];
document.getElementById("tr_y").innerHTML = tr_sq['y'];
document.getElementById("tr_s").innerHTML = tr_sq['side'];
document.getElementById("tr_area").innerHTML = tr_sq['area'];

document.getElementById("c00_x").innerHTML = cp[0]['x'];
document.getElementById("c00_y").innerHTML = cp[0]['y'];
document.getElementById("c01_x").innerHTML = cp[1]['x'];
document.getElementById("c01_y").innerHTML = cp[1]['y'];
document.getElementById("c10_x").innerHTML = cp[2]['x'];
document.getElementById("c10_y").innerHTML = cp[2]['y'];
document.getElementById("c11_x").innerHTML = cp[3]['x'];
document.getElementById("c11_y").innerHTML = cp[3]['y'];

var path2 = `M ${cp[0]['x']} ${cp[0]['y']} L ${cp[1]['x']} ${cp[1]['y']}  L ${cp[3]['x']} ${cp[3]['y']} L ${cp[2]['x']} ${cp[2]['y']} Z`;


var data1 = {
  x: px,
  y: py,
  mode: 'markers',
  type: 'scatter',
  name: 'data points',
  color: 'darkblue'
};

var data2 = {
  x: qx,
  y: qy,
  mode: 'markers',
  type: 'scatter',
  name: 'transformed',
  color: 'darkblue'
};

var layout1 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  title: {text:'Original Data'},
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
            }
          ]
}

var path = `M ${tbox[0]['x']} ${tbox[0]['y']} L ${tbox[1]['x']} ${tbox[1]['y']}  L ${tbox[3]['x']} ${tbox[3]['y']} L ${tbox[2]['x']} ${tbox[2]['y']} Z`;


var layout2 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  title: {text:'Transformed Data'},
  shapes: [{type:'path',
            path:path,
            xref:'x',
            yref:'y',
            line:{color:'black',width:2,opacity:0.5},
            fillcolor:'rgba(0, 250, 250, 0.2)',
            name:'transformed box',
            showlegend:true
            }
          ]

}


var layout3 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  title: {text:'Transformed Solution'},
  shapes: [
           {type:'path',
            path:path,
            xref:'x',
            yref:'y',
            line:{color:'black',width:2,opacity:0.5},
            fillcolor:'rgba(0, 250, 250, 0.2)',
            name:'transformed box',
            showlegend:true
            },
           {type:'rect',
            xref:'x',
            yref:'y',
            x0:tr_sq['x'],
            y0:tr_sq['y'],
            x1:tr_sq['x']+tr_sq['side'],
            y1:tr_sq['y']+tr_sq['side'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 150, 150, 0.5)',
            name:'optimal square',
            showlegend:true
            },
            
          ]

}


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
var trc2 = [data2];

var options1 = {staticPlot: true, displayModeBar: false, responsive: false};
Plotly.newPlot('plotDiv0', trc1, layout1, options1);
Plotly.newPlot('plotDiv1', trc2, layout2, options1);
Plotly.newPlot('plotDiv2', trc2, layout3, options1);
Plotly.newPlot('plotDiv3', trc1, layout4, options1);

</script>
$offecho

executetool 'win32.ShellExecute "%html%"';

$label skipplot
