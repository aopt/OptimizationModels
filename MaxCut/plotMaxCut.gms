$ontext

   MAX-CUT Problem with Visualization

   No weights: each arc counts as 1

$offtext


*-----------------------------------------------------------
* undirected network topology
* randomly generated data
*-----------------------------------------------------------

set
  i 'nodes' /node1*node35/
  a(i,i) 'arcs'
;
alias (i,j,n);

*-----------------------------------------------------------
* random coordinates
* for plotting
*-----------------------------------------------------------

set xy /x,y/;
parameter coord(n,xy) 'x-y coordinates';
coord(n,xy) = uniform(0,100);
display coord;

*-----------------------------------------------------------
* points that are close get a higher probability to get a link
* may be that makes the graph a bit prettier.
*-----------------------------------------------------------

set lt(i,j) 'we populate only upper-triangular part';
lt(i,j) = ord(i)<ord(j);

parameter
   dist(i,j) 'distance'
   maxdist 'maximum distance we can have'
;
dist(lt(i,j)) = sqrt(sum(xy,sqr(coord(i,xy)-coord(j,xy))));
maxdist = smax(lt,dist(lt));
* select short arcs with higher probability than long ones.
a(lt)$(dist(lt)<maxdist/5) = uniform(0,1)<0.5;
a(lt)$(dist(lt)>=maxdist/5) = uniform(0,1)<0.05;

display$(card(i)<=50) i,a;


*-----------------------------------------------------------
* summary of the data
*-----------------------------------------------------------

scalar
  numnodes 'number of nodes'
  numarcs 'number of arcs';
numnodes = card(i);
numarcs = card(a);
display numnodes,numarcs;


*-----------------------------------------------------------
* MAX-CUT Model
*-----------------------------------------------------------

binary variables
   x(i) 'node is in S'
;

variable z 'objective';

equations
   obj1
;

obj1.. z =e= sum(a(i,j),sqr(x(i)-x(j)));


model maxcut1 /obj1/;
option miqcp=cplex;
solve maxcut1 maximizing z using miqcp;


* remove possible noise
x.l(i) = round(x.l(i));

set ecut(i,j) 'maximum cut';
ecut(a(i,j)) = x.l(i)<>x.l(j);

option x:0;
display x.l,ecut,z.l;

*-----------------------------------------------------------
* Plot network using put statement
* We generate some JavaScript code to hold the data
* For documentation on plotting library, see:
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
    put$(x.l(n)=0) ",color:'green'";
    put$(x.l(n)=1) ",color:'blue'";
    put ",size:2";
    put "},position:{x:",coord(n,'x'):0:3;
    put ",y:",coord(n,'y'):0:3,"}}"/;
);
loop(a(i,j),
    put ",{data:{id:'",(ord(i)):0:0,'-',(ord(j)):0:0,"',";
    put "source:",(ord(i)):0:0,",target:",(ord(j)):0:0;
    put$ecut(a) ",color:'red',width:0.1";
    put$(not ecut(a)) ",color:'grey',width:0.1";
    put "}}"/;
);
put '];'/;


put "table='<h4>GAMS MAX-CUT</h4>"
    "Number of nodes: ",(card(n)):0:0,"<br>"
    "Number of arcs: ",(card(a)):0:0,"<br><br>"
    "Cut size (red arcs): ",(card(ecut)):0:0,"<br>"
    "Grey arcs (not in cut): ",(card(a)-card(ecut)):0:0,"<br>"
put "';";
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
<title>GAMS MAX-CUT</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.20.0/cytoscape.min.js"></script>
<script src="networkdata.js"></script>
</head>

<style>
#cy {
    width: calc(100% - 200px);
    height: 100%;
    position: absolute;
    top: 0px;
    left: 200px;
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
    <script>
      document.getElementById('my-table').innerHTML = table
      var cy = cytoscape({
        container: document.getElementById('cy'),
        elements: networkdata,
        style: [
          {
            selector: 'node',
            style: {
                'background-color': 'data(color)',
                label: 'data(id)',
                width: 'data(size)', height: 'data(size)',
               'font-size': 1.5
            }
          },
          {
            selector: 'edge',
            style: { 'width': 'data(width)', 'line-color': 'data(color)',
                     'curve-style': 'bezier' }
          }
        ],
        layout: { name: 'preset' }
      });

    </script>
</body>
</html>
$offecho

$libInclude win32 shellexecute  "%htmlfile%"
* for older gams systems use:
*execute 'shellexecute "%htmlfile%"';
