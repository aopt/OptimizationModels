$onText

   Find largest shapes that don't cover any points.
   
   Shapes:
      1. Square (MIP)
      2. Diamond (MIP)
      3. Rectangle (MISOCP)
      4. Circle (nonconvex NLP)
      5. 5 different "next best" rectangles
  

$offtext

*---------------------------------------------------------------
* options
*---------------------------------------------------------------

* 0: no plot
* 1: produce HTML plot)
$set htmlplot 1

option qcp=cplex,mip=cplex,miqcp=cplex,nlp=baron;

option seed=12345;

*---------------------------------------------------------------
* data
*---------------------------------------------------------------

scalar maxsize 'size of the box' / 10 /;

sets
   i     'points' /point1*point100/
   cr    'circle attributes' /x,y,r/
   c(cr) 'coordinates' /x,y/    
;

parameter p(i,c) 'points';
p(i,c) = uniform(0,maxsize);
display p;

*---------------------------------------------------------------
* 1. largest empty square model (MIP)
*---------------------------------------------------------------

set case 'for comparison' /less,greater/;

positive variable sq(*) 'square location and size';
binary variable d(i,c,case) 'd=1 means: relax no-overlap constraint';
variable z 'objective';

Equations
   emptysq1(i,c) 'no-overlap constraint: less-than version'  
   emptysq2(i,c) 'no-overlap constraint: greater-than version'
   sumd(i)       '(at least) one no-overlap constraint must hold'
   maxsq         'stay inside our box'
   objsq         'objective' 
;

objsq.. z =e= sq('side');
maxsq(c)..  sq(c) + sq('s') =l= maxsize;
emptysq1(i,c).. p(i,c) =l= sq(c) + d(i,c,'less')*maxsize;
emptysq2(i,c).. p(i,c) =g= sq(c) + sq('side') - d(i,c,'greater')*maxsize;
sumd(i)..  sum((c,case),d(i,c,case)) =e= 3;

model emptysquare /all/;
solve emptysquare maximizing z using mip;

parameter square(*) 'optimal values';
square(c) = sq.l(c);
square('side') = sq.l('side');
square('area') = sqr(sq.l('side'));
display square;

*---------------------------------------------------------------
* 2. largest empty diamond model (MIP)
*---------------------------------------------------------------

set pm   'var splitting for abs()' /'+','-'/;

positive variables
   diamnd(*)   'center + dist of diamond'
   absdiffd(i,c,*) 'Δ(i,c) = |p(i,c)-center(c)|'
;
binary variable delta 'for variable splitting';

variable dmin 'Manhattan distance to closest point';

equation
   eabsdiff1(i,c) '|p(i,c)-center(c)|'
   eabsdiff2(i,c) '|p(i,c)-center(c)|'
   eabsdiff3(i,c) '|p(i,c)-center(c)|'
   smallestd      'smallest distance'
   elbnd(c)       'diamond must be inside box'
   eubnd(c)       'diamond must be inside box'
;

eabsdiff1(i,c)..  absdiffd(i,c,'+')-absdiffd(i,c,'-') =e= p(i,c)-diamnd(c);
eabsdiff2(i,c)..  absdiffd(i,c,'+') =l= delta(i,c)*Maxsize;
eabsdiff3(i,c)..  absdiffd(i,c,'-') =l= (1-delta(i,c))*Maxsize;
smallestd(i)..    dmin =l= sum((c,pm),absdiffd(i,c,pm));
elbnd(c)..        diamnd(c) - dmin =g= 0; 
eubnd(c)..        diamnd(c) + dmin =l= maxsize; 

model emptydiamond /all-emptysquare/;
solve emptydiamond maximizing dmin using mip; 

parameter diamond(*) 'optimal values';
diamond(c) = diamnd.l(c);
diamond('L1 dist') = dmin.l;
diamond('diagonal') = 2*dmin.l;
diamond('side') = sqrt(2*sqr(dmin.l));
diamond('area') = 2*sqr(dmin.l);
display diamond;

*---------------------------------------------------------------
* largest empty rectangle model (MISOCP)
*---------------------------------------------------------------

set a 'attribute' /pos,side/;  
positive variable rect(a,c) 'rectangle location and size';
binary variable d(i,c,case) 'd=1 means: relax no-overlap constraint';
variables t 'to be maximized';

Equations
   maxrect(c)        'stay inside box'
   emptyrect1(i,c)   'no-overlap: less-than version'
   emptyrect2(i,c)   'no-overlap: greater-than version'
   socp              '2nd order cone constraint'
;

maxrect(c)..  rect('pos',c) + rect('side',c) =l= maxsize;
emptyrect1(i,c).. p(i,c) =l= rect('pos',c) + d(i,c,'less')*maxsize;
emptyrect2(i,c).. p(i,c) =g= rect('pos',c) + rect('side',c) - d(i,c,'greater')*maxsize;
socp.. sqr(t) =l= rect('side','x')*rect('side','y');  

model maxrectangle /maxrect,emptyrect1,emptyrect2,socp,sumd/;
solve maxrectangle maximizing t using miqcp;

parameter rectangle(a,c) 'optimal rectangle';
rectangle(a,c) = rect.l(a,c);
display rectangle;

*---------------------------------------------------------------
* largest empty circle model (nonconvex NLP)
*---------------------------------------------------------------

Variables
    circle(cr)  'center+radius'
    diff(i,c)   'intermediate variables'
;

equations
   calcdiff(i,c)    'compute diff'
   emptycircle(i)   'no points inside circle'
   objcircle        'objective'
   bnd1(c)          'stay inside box'      
   bnd2(c)          'stay inside box' 
;

objcircle.. z =e= circle('r'); 
calcdiff(i,c).. diff(i,c) =e= p(i,c)-circle(c);
emptycircle(i).. sum(c, sqr(diff(i,c))) =g= sqr(circle('r'));
bnd1(c).. circle(c) =g= circle('r');
bnd2(c).. circle(c) =l= maxsize-circle('r');

circle.lo(cr) = 0;
circle.up(cr) = maxsize;

model maxcircle /objcircle,calcdiff,emptycircle,bnd1,bnd2/;
solve maxcircle maximizing z using nlp;

display circle.l;


*---------------------------------------------------------------
* five best rectangles
*---------------------------------------------------------------

scalar difftol 'min difference between rectangles |Δx|+|Δy|>difftol' /3/;

set
   run  'solve runs' /run1*run5/
   prevrun(run) 'previous runs'
;

parameter prevrect(run,*,*);

binary variable bindiff(run,c);
positive variable absdiff(run,c,pm);

equation
    difference1(run,c)
    difference2(run,c)
    difference3(run,c)
    difference4(run)
    
;

difference1(prevrun,c).. absdiff(prevrun,c,'+')-absdiff(prevrun,c,'-') =e= prevrect(prevrun,'pos',c) - rect('pos',c);
difference2(prevrun,c).. absdiff(prevrun,c,'+') =l= bindiff(prevrun,c)*maxsize;
difference3(prevrun,c).. absdiff(prevrun,c,'-') =l= (1-bindiff(prevrun,c))*maxsize;
difference4(prevrun).. sum((c,pm),absdiff(prevrun,c,pm)) =g= difftol;


model maxrectangle2 /maxrectangle,difference1,difference2,difference3,difference4/;


prevrect(run,'pos',c) = 0;
prevrun(run) = no;
loop(run,
   solve maxrectangle2 maximizing t using miqcp;
   display rect.l;
   prevrect(run,'pos',c) = rect.l('pos',c);
   prevrect(run,'side',c) = rect.l('side',c);
   prevrun(run) = yes;
   display prevrect;
);



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
put "pnts={n:",(card(i)):0:0,
       ",map:'[0,",maxsize:0:0,"]&times;[0,",maxsize:0:0,"]'",
       ",minx:",(smin(i,p(i,'x'))):0:3,
       ",miny:",(smin(i,p(i,'y'))):0:3,
       ",maxx:",(smax(i,p(i,'x'))):0:3,
       ",maxy:",(smax(i,p(i,'y'))):0:3,
       ",avgx:",(sum(i,p(i,'x'))/card(i)):0:3,
       ",avgy:",(sum(i,p(i,'y'))/card(i)):0:3,
       "}"/;
put "sq={x:",square('x'):0:3,
      ",y:",square('y'):0:3,
      ",side:",square('side'):0:3,
      ",area:",(sqr(square('side'))):0:3,
      "}"/;
put "d={x:",diamond('x'):0:3,
       ",y:",diamond('y'):0:3,
       ",area:",diamond('area'):0:3,
       ",side:",diamond('side'):0:3,
       ",diagonal:",diamond('diagonal'):0:3,
       "}"/;  
put "r={x:",rectangle('pos','x'):0:3,
       ",y:",rectangle('pos','y'):0:3,
       ",sx:",rectangle('side','x'):0:3,
       ",sy:",rectangle('side','y'):0:3,
       ",a:",(rectangle('side','x')*rectangle('side','y')):0:3,"}"/;
put "circle={x:",circle.l('x'):0:3,",y:",circle.l('y'):0:3,",r:",circle.l('r'):0:3,
        ",a:",(pi*sqr(circle.l('r'))):0:3,"}"/;
put "rs=["/;
loop(run,
  put "  {x:",prevrect(run,'pos','x'):0:3,
      ",y:",prevrect(run,'pos','y'):0:3,
      ",sx:",prevrect(run,'side','x'):0:3,
      ",sy:",prevrect(run,'side','y'):0:3,
      ",a:",(prevrect(run,'side','x')*prevrect(run,'side','y')):0:3,
      "},"/;
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

<h1>Largest Empty Square</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=2 class="brdr">square</th></tr>
<tr><td class="brdr">&#x1D465;</td><td class="brdr" id="sq_x">0</td></tr>
<tr><td class="brdr">&#x1D466;</td><td class="brdr" id="sq_y">0</td></tr>
<tr><td class="brdr">side</td><td class="brdr" id="sq_s">0</td></tr>
<tr><td class="brdr">area</td><td class="brdr" id="sq_area">0</td></tr>
</table>
</td><td>
<div id="plotDiv1" style="width: 800px; height: 600px;"></div>
</td></tr></table>

<h1>Largest Empty Diamond</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=2 class="brdr">diamond</th></tr>
<tr><td class="brdr">&#x1D465;</td><td class="brdr" id="d_x"></td></tr>
<tr><td class="brdr">&#x1D466;</td><td class="brdr" id="d_y"></td></tr>
<tr><td class="brdr">diagonal</td><td class="brdr" id="d_diag"></td></tr>
<tr><td class="brdr">side</td><td class="brdr" id="d_side"></td></tr>
<tr><td class="brdr">area</td><td class="brdr" id="d_area"></td></tr>
</table>
</td><td>
<div id="plotDiv1a" style="width: 800px; height: 600px;"></div>
</td></tr></table>

<h1>Largest Empty Rectangle</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=2 class="brdr">rectangle</td></tr>
<tr><td class="brdr">&#x1D465;</td><td class="brdr" id="r_x">0</td></tr>
<tr><td class="brdr">&#x1D466;</td><td class="brdr" id="r_y">0</td></tr>
<tr><td class="brdr">side &#x1D465;</td><td class="brdr" id="r_s1">0</td></tr>
<tr><td class="brdr">side &#x1D466;</td><td class="brdr" id="r_s2">0</td></tr>
<tr><td class="brdr">area</td><td class="brdr" id="r_area">0</td></tr>
</table>
</td><td>
<div id="plotDiv2" style="width: 800px; height: 600px;"></div>
</td></tr></table>

<h1>Largest Empty Circle</h1>
<table><tr><td>
<table class="brdr">
<tr><th colspan=2 class="brdr">circle</td></tr>
<tr><td class="brdr">&#x1D465;</td><td class="brdr" id="c_x">0</td></tr>
<tr><td class="brdr">&#x1D466;</td><td class="brdr" id="c_y">0</td></tr>
<tr><td class="brdr">radius</td><td class="brdr" id="c_r">0</td></tr>
<tr><td class="brdr">area</td><td class="brdr" id="c_area">0</td></tr>
</table>
</td><td>
<div id="plotDiv3" style="width: 800px; height: 600px;"></div>
</td></tr></table>


<h1>Five largest rectangles</h1>
<table><tr><td>
<table class="brdr">
<tr><th class="brdr">rectangles</th><th class="brdr">rect1</th><th class="brdr">rect2</th><th class="brdr">rect3</th><th class="brdr">rect4</th><th class="brdr">rect5</th></tr>
<tr><td class="brdr">&#x1D465;</td><td class="brdr" id="r_x1">0</td><td class="brdr" id="r_x2">0</td><td class="brdr" id="r_x3">0</td><td class="brdr" id="r_x4">0</td><td class="brdr" id="r_x5">0</td></tr>
<tr><td class="brdr">&#x1D466;</td><td class="brdr" id="r_y1">0</td><td class="brdr" id="r_y2">0</td><td class="brdr" id="r_y3">0</td><td class="brdr" id="r_y4">0</td><td class="brdr" id="r_y5">0</td></tr>
<tr><td class="brdr">side &#x1D465;</td><td class="brdr" id="r_sx1">0</td><td class="brdr" id="r_sx2">0</td><td class="brdr" id="r_sx3">0</td><td class="brdr" id="r_sx4">0</td><td class="brdr" id="r_sx5">0</td></tr>
<tr><td class="brdr">side &#x1D466;</td><td class="brdr" id="r_sy1">0</td><td class="brdr" id="r_sy2">0</td><td class="brdr" id="r_sy3">0</td><td class="brdr" id="r_sy4">0</td><td class="brdr" id="r_sy5">0</td></tr>
<tr><td class="brdr">area</td><td class="brdr" id="r_a1">0</td><td class="brdr" id="r_a2">0</td><td class="brdr" id="r_a3">0</td><td class="brdr" id="r_a4">0</td><td class="brdr" id="r_a5">0</td></tr>
</table>
</td><td>
<div id="plotDiv4" style="width: 800px; height: 600px;"></div>
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

document.getElementById("sq_x").innerHTML = sq['x'];
document.getElementById("sq_y").innerHTML = sq['y'];
document.getElementById("sq_s").innerHTML = sq['side'];
document.getElementById("sq_area").innerHTML = sq['area'];

document.getElementById("d_x").innerHTML = d['x'];
document.getElementById("d_y").innerHTML = d['y'];
document.getElementById("d_diag").innerHTML = d['diagonal'];
document.getElementById("d_side").innerHTML = d['side'];
document.getElementById("d_area").innerHTML = d['area'];


document.getElementById("r_x").innerHTML = r['x'];
document.getElementById("r_y").innerHTML = r['y'];
document.getElementById("r_s1").innerHTML = r['sx'];
document.getElementById("r_s2").innerHTML = r['sy'];
document.getElementById("r_area").innerHTML = r['a'];

document.getElementById("c_x").innerHTML = circle['x'];
document.getElementById("c_y").innerHTML = circle['y'];
document.getElementById("c_r").innerHTML = circle['r'];
document.getElementById("c_area").innerHTML = circle['a'];

document.getElementById("r_x1").innerHTML = rs[0]['x'];
document.getElementById("r_y1").innerHTML = rs[0]['y'];
document.getElementById("r_sx1").innerHTML = rs[0]['sx'];
document.getElementById("r_sy1").innerHTML = rs[0]['sy'];
document.getElementById("r_a1").innerHTML = rs[0]['a'];

document.getElementById("r_x2").innerHTML = rs[1]['x'];
document.getElementById("r_y2").innerHTML = rs[1]['y'];
document.getElementById("r_sx2").innerHTML = rs[1]['sx'];
document.getElementById("r_sy2").innerHTML = rs[1]['sy'];
document.getElementById("r_a2").innerHTML = rs[1]['a'];

document.getElementById("r_x3").innerHTML = rs[2]['x'];
document.getElementById("r_y3").innerHTML = rs[2]['y'];
document.getElementById("r_sx3").innerHTML = rs[2]['sx'];
document.getElementById("r_sy3").innerHTML = rs[2]['sy'];
document.getElementById("r_a3").innerHTML = rs[2]['a'];

document.getElementById("r_x4").innerHTML = rs[3]['x'];
document.getElementById("r_y4").innerHTML = rs[3]['y'];
document.getElementById("r_sx4").innerHTML = rs[3]['sx'];
document.getElementById("r_sy4").innerHTML = rs[3]['sy'];
document.getElementById("r_a4").innerHTML = rs[3]['a'];

document.getElementById("r_x5").innerHTML = rs[4]['x'];
document.getElementById("r_y5").innerHTML = rs[4]['y'];
document.getElementById("r_sx5").innerHTML = rs[4]['sx'];
document.getElementById("r_sy5").innerHTML = rs[4]['sy'];
document.getElementById("r_a5").innerHTML = rs[4]['a'];


px = p.map((x) => x['x'])
py = p.map((x) => x['y'])

var data1 = {
  x: px,
  y: py,
  mode: 'markers',
  type: 'scatter',
  name: 'data points',
  color: 'darkblue'
};

var layout0 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
}

var layoutSquare = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  shapes: [{type:'rect',
            xref:'x',
            yref:'y',
            x0:sq['x'],
            y0:sq['y'],
            x1:sq['x']+sq['side'],
            y1:sq['y']+sq['side'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            name:'largest square',
            showlegend:true
            }
          ]
}

var path = `M ${d['x']-0.5*d['diagonal']} ${d['y']} L ${d['x']} ${d['y']+0.5*d['diagonal']}  L ${d['x']+0.5*d['diagonal']} ${d['y']} L ${d['x']} ${d['y']-0.5*d['diagonal']} Z`;

var layoutDiamond = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  shapes: [{type:'path',
            path:path,
            xref:'x',
            yref:'y',
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            name:'largest diamond',
            showlegend:true
            }
          ]
}


var layout2 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  shapes: [{type:'rect',
            xref:'x',
            yref:'y',
            x0:r['x'],
            y0:r['y'],
            x1:r['x']+r['sx'],
            y1:r['y']+r['sy'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            name:'largest rectangle',
            showlegend:true
            }
          ]
}

var layout3 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  shapes: [{type:'circle',
            xref:'x',
            yref:'y',
            x0:circle['x']-circle['r'],
            y0:circle['y']-circle['r'],
            x1:circle['x']+circle['r'],
            y1:circle['y']+circle['r'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            name:'largest circle',
            showlegend:true
            }
          ]
}

var layout4 = {
  autosize: false,
  width: 650,
  height: 600,
  showlegend: true,
  shapes: [{type:'rect',
            xref:'x',
            yref:'y',
            x0:rs[0]['x'],
            y0:rs[0]['y'],
            x1:rs[0]['x']+rs[0]['sx'],
            y1:rs[0]['y']+rs[0]['sy'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            name:'largest rectangle',
            showlegend:true
            },
            {type:'rect',
            xref:'x',
            yref:'y',
            x0:rs[1]['x'],
            y0:rs[1]['y'],
            x1:rs[1]['x']+rs[1]['sx'],
            y1:rs[1]['y']+rs[1]['sy'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            },
            {type:'rect',
            xref:'x',
            yref:'y',
            x0:rs[2]['x'],
            y0:rs[2]['y'],
            x1:rs[2]['x']+rs[2]['sx'],
            y1:rs[2]['y']+rs[2]['sy'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            },
            {type:'rect',
            xref:'x',
            yref:'y',
            x0:rs[3]['x'],
            y0:rs[3]['y'],
            x1:rs[3]['x']+rs[3]['sx'],
            y1:rs[3]['y']+rs[3]['sy'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            },
            {type:'rect',
            xref:'x',
            yref:'y',
            x0:rs[4]['x'],
            y0:rs[4]['y'],
            x1:rs[4]['x']+rs[4]['sx'],
            y1:rs[4]['y']+rs[4]['sy'],
            line:{color:'darkred',width:2,opacity:0.5},
            fillcolor:'rgba(0, 255, 255, 0.5)',
            },
          ]
}


var trc1 = [data1];
var options1 = {staticPlot: true, displayModeBar: false, responsive: false};
Plotly.newPlot('plotDiv0', trc1, layout0, options1);
Plotly.newPlot('plotDiv1', trc1, layoutSquare, options1);
Plotly.newPlot('plotDiv1a', trc1, layoutDiamond, options1);
Plotly.newPlot('plotDiv2', trc1, layout2, options1);
Plotly.newPlot('plotDiv3', trc1, layout3, options1);
Plotly.newPlot('plotDiv4', trc1, layout4, options1);
</script>
</html>
$offecho

executetool 'win32.ShellExecute "%html%"';

$label skipplot


