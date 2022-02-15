$ontext

   Shortest Path Problem with Visualization

$offtext


*-----------------------------------------------------------
* directed network topology
* randomly generated data
*-----------------------------------------------------------

set
   n 'nodes (vertices)' /node1*node50/
   a(n,n) 'arcs (edges)'
;

alias (n,i,j);

* sparse random network
a(i,j) = uniform(0,1)<0.05;

option a:0:0:8;
display$(card(n)<=50) n,a;

*-----------------------------------------------------------
* summary of the data
*    - calculate number of arcs
*    - calculate the in-/out-degree for each node
*-----------------------------------------------------------

scalar numarcs 'number of arcs';
numarcs = card(a);
display numarcs;


parameter degree(*,*) 'in- and out-degree';
degree(n,'in-degree') = sum(a(i,n),1);
degree(n,'out-degree') = sum(a(n,i),1);
degree('min','in-degree') = smin(n,degree(n,'in-degree'));
degree('min','out-degree') = smin(n,degree(n,'out-degree'));
degree('max','in-degree') = smax(n,degree(n,'in-degree'));
degree('max','out-degree') = smax(n,degree(n,'out-degree'));
display degree;

*-----------------------------------------------------------
* diagonal
* do we have diagonal elements?
*-----------------------------------------------------------

set diagonal(n) 'diagonal elements';
diagonal(n) = a(n,n);
display diagonal;

*-----------------------------------------------------------
* random coordinates
* for plotting and for length calculation
*-----------------------------------------------------------

set xy /x,y/;
parameter coord(n,xy) 'x-y coordinates';
coord(n,xy) = uniform(0,100);
display coord;

*-----------------------------------------------------------
* shortest path model
*-----------------------------------------------------------

parameters
   inflow(n)   'exogenous inflow at node'    / node1   1.0 /
   outflow(n)  'exogenous outflow at node'   / node29  1.0 /
   length(i,j) 'arc lengths'
;
length(a(i,j)) = sqrt(sum(xy, sqr(coord(i,xy)-coord(j,xy))));
* all are very sparse, GAMS will exploit this

positive variable f(i,j) 'flow from node i -> node j';

variable totalLength 'objective: minimize';

equations
    nodeBalance(n) 'kirchoff equations'
    objective      'minimize'
;

objective.. totalLength =e= sum(a,length(a)*f(a));

nodeBalance(n)..
     sum(a(i,n), f(a)) + inflow(n) =e=
     sum(a(n,j), f(a)) + outflow(n);

model shortestPath /all/;
solve shortestPath using lp minimizing totalLength;

display f.l,totalLength.l;


*-----------------------------------------------------------
* form the path (not so easy)
* and create a solution report
*-----------------------------------------------------------

sets
  step /step1*step50/
  path(step,n) 'easier to read than f'
;
singleton set cur(i) 'current node';
cur(i)$inflow(i) = yes;
* while we have a current node
loop(step$card(cur),
* record current node
   path(step,cur) = yes;
* current node := next node
   cur(j) = f.l(cur,j)>0.5;
* to debug add this
*   display cur;
);
option path:0:0:1;
display path;


*-----------------------------------------------------------
* adding a different solution report
* uses path we just calculated
*-----------------------------------------------------------

parameter reportSP(*,*,*) 'shortest path solution with lengths';
reportSP(path(step,n),j)$(f.l(n,j)>0.5) = length(n,j);
reportSP('sum of lengths','','') = sum((step,i,j),reportSP(step,i,j));
reportSP('obj from model','','') = totalLength.l;
option reportSP:3:0:1;
display reportSP;



*-----------------------------------------------------------
* Plot network using put statement
* We generate some JavaScript code to hold the data
* For domumentation on plotting library, see:
* https://js.cytoscape.org/
*-----------------------------------------------------------

$set htmlfile network.html
$set datafile networkdata.js

file fln /%datafile%/;
put fln;
put 'networkdata=['/;
loop(n,
    put$(ord(n)>1) ",";
    put "{data:{id:",(ord(n)):0:0;
    put$(inflow(n)=0 and outflow(n)=0) ",color:'black'";
    put$(inflow(n)>0) ",color:'blue'";
    put$(outflow(n)>0) ",color:'green'";
    put$(inflow(n)=0 and outflow(n)=0) ",size:1";
    put$(inflow(n)>0 or outflow(n)>0) ",size:2";
    put "},position:{x:",coord(n,'x'):0:3;
    put ",y:",coord(n,'y'):0:3,"}}"/;
);
loop(a(i,j),
    put ",{data:{id:'",(ord(i)):0:0,'-',(ord(j)):0:0,"',";
    put "source:",(ord(i)):0:0,",target:",(ord(j)):0:0;
    put$(f.l(i,j)>0.5) ",color:'red',width:0.2";
    put$(f.l(i,j)<0.5) ",color:'grey',width:0.1";
    put "}}"/;
);
put '];'/;

put "table='<h4>GAMS Shortest Path</h4>"
    "Number of nodes: ",(card(n)):0:0,"<br>"
    "Number of arcs: ",(card(a)):0:0,"<br><br>"
    "<table><tr><th>From</th><th>To</th><th>Length</th></tr>'+"/;
loop((path(step,n),j)$(f.l(n,j)>0.5),
   put "'<tr><td>",n.tl:0,"</td><td>",j.tl:0,"</td><td><pre>",length(n,j):10:3,"</pre></td></tr>'+"/;
);
put "'<tr><td colspan=2>Total length</td><td><pre>",totalLength.l:10:3,"</pre></td></tr>'+"/;

put "'</table><br>';";
putclose;

$ontext

With an internet connection you can use:
  <script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.20.0/cytoscape.min.js"></script>
Without use a local .js file:
  <script src="cytoscape.min.js"></script>

$offtext

$onecho > %htmlfile%
<html>
<head>
<title>GAMS Shortest Path Network</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.20.0/cytoscape.min.js"></script>
<script src="networkdata.js"></script>
</head>

<style>
#cy {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0px;
    left: 100px;
}

table,th, td {
 border: 1px solid black;
 border-collapse: collapse;
 padding-left: 10px;
 padding-right: 10px;
}

</style>

<body>
    <div id="cy"></div>
    <div id="my-table"></div>
    <div><button onclick="buttonClicked()" id="btn">Animate Flow</button></div>
    <script>
      document.getElementById('my-table').innerHTML = table
      var cy = cytoscape({
        container: document.getElementById('cy'),
        elements: networkdata,
        style: [
          {
            selector: 'node',
            style: {
                // shape: 'circle',
                'background-color': 'data(color)',
                label: 'data(id)',
                width: 'data(size)', height: 'data(size)',
               'font-size': 1.5
            }
          },
          {
            selector: 'edge',
            style: { 'width': 'data(width)', 'line-color': 'data(color)',
                     'mid-target-arrow-shape': 'triangle',
                     'mid-target-arrow-color': 'data(color)',
                     'arrow-scale': 0.15, 'curve-style': 'bezier' }
                    //'line-style': 'dashed', 'line-dash-pattern': [6, 3]

          }
        ],
        layout: { name: 'preset' }
      });


      const loopAnimation = (ele, i) => {
         const opts = {
           style: {'line-dash-offset': -100 * i }
          };
          const durOptions = { duration: 10000 };
          return ele.animation(opts, durOptions).play()
          .promise('complete')
          .then(() => loopAnimation(ele, i + 1));
      };

      var reds = cy.edges().filter(function(ele) { return ele.data('color') == 'red'; });
      reds.forEach((edge) => {
          loopAnimation(edge, 1);
      });


     var animated = false;
     const btn = document.getElementById("btn");

     function buttonClicked(b) {
       if (animated) {
         reds.style({'line-style':'solid', 'width':0.2});
         btn.innerHTML = "Animate flow";
       }
       else {
         reds.style({'line-style':'dashed', 'line-dash-pattern': [0.6, 1.1], 'width':0.4});
         btn.innerHTML = "Stop animation";
       }
       animated = !animated;
     }
    </script>
</body>
</html>
$offecho

*$libInclude win32 shellexecute  "%htmlfile%"
* for older gams systems use:
execute 'shellexecute "%htmlfile%"';

