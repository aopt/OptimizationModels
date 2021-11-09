$ontext

   Two related network models

     1.  Shortest Path
     2.  Min Cost Flow

  Subjects:

     - Modeling of networks
     - Plotting of GAMS generated networks
          Python Networkx package
          Javascript cytoscape.js

$offtext

*-----------------------------------------------------------
* directed network topology
* randomly generated data
*-----------------------------------------------------------

* show initial seed (question 1.1)
scalar defaultSeed 'default initial seed';
defaultSeed =  execseed;
display defaultSeed;


$ontext

set
   n 'nodes (vertices)' /node1*node50/
   a(n,n) 'arcs (edges)'
;

alias (n,i,j);

$offtext

* using format of question 1.3
set n 'nodes (vertices)' /node1*node50/;
alias (n,i,j);
set a(i,j) 'arcs (edges)';


* sparse random network
a(i,j)$(uniform(0,1)<0.05) = yes;
* a(i,j) = uniform(0,1)<0.05;

* question 1.4
option a:0:0:8;
display$(card(n)<=50) n,a;

*$stop

$ontext

   exercises:

     1.1. rerun the model a few times and observe results are the same
          GAMS uses a pseudo random number generator with a default seed
          set seed with "option seed=nnn;" or "execseed = nnnn;"
          if you want a new graph each run, use:
          execseed = 1+gmillisec(jnow);
          How would one figure out the default initial seed (3141)?
     1.2  check that a(n,n)$(uniform(0,1)<0.05) = yes;
          is doing something else than a(i,j)$(uniform(0,1)<0.05) = yes;
     1.3  Reorganize things a little bit so we can declare
             set a(i,j) 'arcs'
          instead of
             set a(n,n) 'arcs'
     1.4  Get better display with
            option a:0:0:8;
            display a;
          may require pw=200 command line setting to get all 8 columns
     1.5  calculate the density of this graph: |A|/(n*n) where |A| is the
          number of arcs.


    answers:

    1.1   scalar defaultSeed 'default initial seed';
          defaultSeed =  execseed;
          display defaultSeed;
          (this needs to be added before using the uniform function)
    1.2   a(n,n)$(uniform(0,1)<0.05) = yes;
          display a;
    1.3   set n 'nodes (vertices)' /node1*node50/;
          alias (n,i,j);
          set a(i,j) 'arcs';
    1.5   scalar density 'density of the graph a';
          density = card(a)/sqr(card(n));
          display density;

$offtext

*$stop

*-----------------------------------------------------------
* summary of the data
*    - calculate number of arcs
*    - calculate the in-/out-degree for each node
*-----------------------------------------------------------

scalar numarcs 'number of arcs';
*numarcs = sum((i,j)$a(i,j),1);   (alternatives)
*numarcs = sum(a(i,j),1);
*numarcs = sum(a,1);
numarcs = card(a);
display numarcs;


parameter degree(*,*) 'in- and out-degree';

*degree(n,'in-degree') = sum(i$a(i,n),1);  (alternative)
degree(n,'in-degree') = sum(a(i,n),1);
degree(n,'out-degree') = sum(a(n,i),1);
degree('min','in-degree') = smin(n,degree(n,'in-degree'));
degree('min','out-degree') = smin(n,degree(n,'out-degree'));
degree('max','in-degree') = smax(n,degree(n,'in-degree'));
degree('max','out-degree') = smax(n,degree(n,'out-degree'));
display degree;


$ontext

  exercises:
      2.1  Why is row with "min" missing in the output?
      2.2 try
             EPS+smin(n,degree(n,'in-degree'))
          for min
          (EPS will usually be zero when exported)
      2.3 add average in/out-degree to this table
      2.4 explain why (and check) this is card(a)/card(n)
      2.5 Define
              degree = in-degree+out-degree.
          Add a column for degree.
          This would also remove the need for this EPS trick.

  answers:
      Meke sure to use the default seed (i.e. no seed)
      2.1  The minimum in-degree and out-degree is zero
      2.2  degree('min','in-degree') = EPS+smin(n,degree(n,'in-degree'));
           degree('min','out-degree') = EPS+smin(n,degree(n,'out-degree'));
     2.3/2.4/2.5: see below. Note I added set d to make the code more compact

$offtext


set d /in-degree,out-degree,degree/;
parameter degree2(*,d) 'answer to questions 2.3-2.5';
degree2(n,'in-degree') = sum(a(i,n),1);
degree2(n,'out-degree') = sum(a(n,i),1);
degree2(n,'degree') = sum(a(n,i),1)+sum(a(i,n),1);
degree2('min',d) = smin(n,degree2(n,d));
degree2('max',d) = smax(n,degree2(n,d));
degree2('avg',d) = sum(n,degree2(n,d))/card(n);
display degree2;


$ontext

----    140 PARAMETER degree2  answer to questions 2.3-2.5

         in-degree  out-degree      degree

node1                    1.000       1.000
node2        4.000       3.000       7.000
node3        4.000       2.000       6.000
node4        1.000       5.000       6.000
...
node48       1.000                   1.000
node49       4.000       3.000       7.000
node50       3.000       2.000       5.000
min                                  1.000
max          7.000       6.000      11.000
avg          2.680       2.680       5.360


avg in-degree = avg in-degree = card(a)/card(n) = avg degree/2

each arc is connected to 2 arcs (1 in, and 1 out)
so the avg in-degree (or out-degree) is num arcs/num nodes.

$offtext

*$stop

*-----------------------------------------------------------
* diagonal
* do we have diagonal elements?
*-----------------------------------------------------------

set diagonal(n) 'diagonal elements';
diagonal(n) = a(n,n);
display diagonal;

$ontext

   exercises:
       3.1 add abort statement
            abort$card(diagonal) "Diagonal is not empty";
       3.2 we can remove diagonals by
             a(n,n) = no;
       3.3 can we just leave diagonal in? What would be the effect
           on a min clost flow / shortest path model?

   answers
       3.3 Not needed to remove unless we have a negative cycle.
           The model does not work if there are negative
           cycles.

$offtext

*$stop

*-----------------------------------------------------------
* random coordinates
* for plotting and for length calculation
*-----------------------------------------------------------

set xy /x,y/;
parameter coord(n,xy) 'x-y coordinates';
coord(n,xy) = uniform(0,100);
display coord;


*-----------------------------------------------------------
* make a plot of the network
* optional part. Skip if you are not a Python programmer
*-----------------------------------------------------------


$goto skip_python_section


* file names
$set pythonscript   network.py
$set picklefile     network.pkl

* my installation
* I installed networkx here (change to your Python path)
$set py d:\python\python39\python.exe %pythonscript%


* part 1: export data as pickle file
embeddedCode Python:
import pickle
nodes = list(gams.get('n'))
arcs = list(gams.get('a'))
coord = list(gams.get('coord'))
data = {'nodes':nodes,'arcs':arcs, 'coord':coord}
pickle.dump(data,open('%picklefile%', 'wb'))
endEmbeddedCode


* part 2: use pickle file to display network using networkx package
* you may need to install the networkx package, e.g. by
*     pip install networkx
$onecho > %pythonscript%
import pickle
import networkx as nx
import matplotlib.pyplot as plt

data = pickle.load(open('%picklefile%', 'rb'))

print(f"Imported data has {len(data['nodes'])} nodes and {len(data['arcs'])} arcs")

DG = nx.DiGraph()
DG.add_nodes_from(data['nodes'])
DG.add_edges_from(data['arcs'])
print(DG)

# make labels shorter
DG = nx.convert_node_labels_to_integers(DG,first_label=1)

# transform coordinates
# coord looks like:
#   [(('node1','x'),11.6),(('node1','y'),84.3),...]
# we transform it into:
#   xypos = {1:[11.6,84.3],...} (a dict)
# note that coord is missing if the coordinate is zero
# so we need to be careful.
xypos = { i : [0.0,0.0] for i in range(1,len(data['nodes'])+1) }
xymap = { 'x':0, 'y':1 }
nodemap = { n:(i+1) for i,n in enumerate(data['nodes'])}
for (n,xy),v in data['coord']:
   xypos[nodemap[n]][xymap[xy]] = v

nx.draw(DG, pos=xypos, with_labels=True)
plt.show()
$offecho


* note: gams will not continue until you close the picture
execute "%py%";

$label skip_python_section

*$stop

$ontext

  Exercise:
    We used nx.convert_node_labels_to_integers to have short node labels.
    We can do this in GAMS instead
       3.1. by using a different set declaration.
       3.2. by keeping the original set and introducing mapping sets.


  Answers:
      3.1. Change
             set n 'nodes (vertices)' /node1*node50/;
           to
             set n 'nodes (vertices)' /1*50/;
          In the python code I did:
            1. remove DG = nx.convert_node_labels_to_integers(DG,first_label=1)
            2. change xypos = { i : [0.0,0.0] for i in range(1,len(data['nodes'])+1) }
               to     xypos = { i : [0.0,0.0] for i in data['nodes'] }
            3. remove nodemap = { n:(i+1) for i,n in enumerate(data['nodes'])}
            4. change xypos[nodemap[n]][xymap[xy]] = v
               to     xypos[n][xymap[xy]] = v
      3.2  Change back:
             set n 'nodes (vertices)' /node1*node50/;
           Before the Python introduce a mapping set:

$offtext


* map to shorter names
set
   n2 'alternative names' /1*50/
   map(n,n2) 'map between different names'
   a2(n2,n2)  'arcs with new names'
;
parameter coord2(n2,xy) 'coordinates with new names';
alias(n2,i2,j2);
map(n,n2)$(ord(n)=ord(n2)) = yes;
a2(i2,j2) = sum(a(i,j)$(map(i,i2) and map(j,j2)),1);
coord2(n2,xy) = sum(map(n,n2),coord(n,xy));
display n2,a2,coord2;


$ontext
           We can also make n2 a dynamic set. E.g.:

           set
              n2_0  'static set' /1*9999/
              n2(n2_0) 'alternative names (dynamic set)'
              map(n,n2_0) 'map between different names'
              a2(n2_0,n2_0)  'arcs with new names'
           ;
           n2(n2_0)$(ord(n2_0)<=card(n)) = yes;
           parameter coord2(n2_0,xy) 'coordinates with new names';

           basically use n2_0 in declarations and n2 everywhere else.

           Now just pass on n2,a2,coord2 to the embedded Python code.

           Using mapping sets is quite a useful construct.
$offtext

*$stop


*-----------------------------------------------------------
* shortest path model
*-----------------------------------------------------------

parameters
   inflow(n)   'exogenous inflow at node'    / node1  1.0 /
   outflow(n)  'exogenous outflow at node'   / node50 1.0 /
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

* alternative: sum((i,j)$a(i,j), length(i,j)*f(i,j))
objective.. totalLength =e= sum(a,length(a)*f(a));

nodeBalance(n)..
     sum(a(i,n), f(a)) + inflow(n) =e=
     sum(a(n,j), f(a)) + outflow(n);

model shortestPath /all/;
solve shortestPath using lp minimizing totalLength;

display f.l,totalLength.l;

*$stop


*-----------------------------------------------------------
* form the path (not so easy)
* and create a solution report
*-----------------------------------------------------------

sets
  step /step1*step50/
  path(step,n) 'easier to read than f'
;
singleton set cur(i) 'current node';
cur('node1') = yes;
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


$ontext

   Exercise 4: form path without using singleton sets

$offtext


set
   cur2(i) 'current node'
   next2(i) 'next node'
   path2(step,n) 'easier to read than f'
;
cur2('node1') = yes;
* while we have a current node
loop(step$card(cur2),
* record current node
   path2(step,cur2) = yes;
* current node := next node
   next2(j) = sum(cur2,f.l(cur2,j))>0.5;
   cur2(j) = next2(j);
* to debug add this
*   display cur2;
);
option path2:0:0:1;
display path2;


*$stop

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


*$stop


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
    put "{data:{id:",(ord(n)):0:0,",col:";
    put$(inflow(n)=0 and outflow(n)=0) "'black'";
    put$(inflow(n)>0) "'blue'";
    put$(outflow(n)>0) "'green'";
    put ",size:"
    put$(inflow(n)=0 and outflow(n)=0) "1";
    put$(inflow(n)>0 or outflow(n)>0) "2";
    put "},position:{x:",coord(n,'x'):0:3;
    put ",y:",coord(n,'y'):0:3,"}}"/;
);
loop(a(i,j),
    put ",{data:{id:'",(ord(i)):0:0,'-',(ord(j)):0:0,"',";
    put "source:",(ord(i)):0:0,",target:",(ord(j)):0:0,",col:";
    put$(f.l(i,j)>0.5) "'red'";
    put$(f.l(i,j)<0.5) "'grey'";
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

put "'</table>';";
putclose;


$onecho > %htmlfile%
<html>
<head>
<title>GAMS Shortest Path Network</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.20.0/cytoscape.min.js"></script>
<script src="%datafile%"></script>
</head>

<style>
#cy {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0px;
    left: 0px;
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
                shape: 'circle',
                'background-color': 'data(col)',
                label: 'data(id)',
                width: 'data(size)', height: 'data(size)',
               'font-size': 1.5
            }
          },
          {
            selector: 'edge',
            style: { width: 0.1, 'line-color': 'data(col)',
                     'mid-target-arrow-shape': 'triangle',
                     'mid-target-arrow-color': 'data(col)',
                     'arrow-scale': '0.15' }
          }
        ],
        layout: { name: 'preset' }
      });
    </script>
</body>
</html>
$offecho

*execute 'shellexecute "%htmlfile%"';

*$stop

*-----------------------------------------------------------
* min cost flow
* generalization of the shortest path problem
* we introduce:
*  - demand,supply and transshipment nodes
*  - costs
*  - link capacities
*-----------------------------------------------------------


*
* random data
*

option seed = 12345;

set
  sn(n) 'supply nodes'  /node3,node14,node32/
  dn(n) 'demand nodes'  /node18,node29,node31,node36,node34/
  tn(n) 'transshipment node'
;

tn(n)$(not sn(n) and not dn(n)) = yes;
display sn,dn,tn;

inflow(n) = 0;
outflow(n) = 0;

scalars
   supplyDemand 'supply equals demand' / 100 /
   s 'sum'
;
* total supply distributed over supply nodes
inflow(sn) = uniform(1,10);
s = sum(sn,inflow(sn));
inflow(sn) = supplyDemand*inflow(sn)/s;
* total demand distributed over demand nodes
outflow(dn) = uniform(1,10);
s = sum(dn,outflow(dn));
outflow(dn) = supplyDemand*outflow(dn)/s;
display inflow,outflow;

parameter
   capacity(n,n) 'on arcs'
   cost(n,n)     'on arcs'
;
capacity(a) = uniform(20,50);
cost(a) = 0.1*length(a);

variable totalCost;

equation objective2 'new obj with costs';
objective2.. totalCost =e= sum(a, cost(a)*f(a));

* capacities are modeled as bounds on f
f.up(a) = capacity(a);

* reuse the nodeBalance equation as is
model mcf /objective2, nodeBalance/;
solve mcf using lp minimizing totalCost;

display f.l;


*$stop


$ontext


  exercises:

   5.1. Adapt the HTML report to display these results
   5.2. Convert the original trnsport.gms model to a
        min-cost flow problem.



$offtext


*-----------------------------------------------------------
* answer 5.1
* we don't print the path (there is no single path) bu instead
* the flow (and the corresponding capacities).
* Also the flow is now fractional, so we use a small
* tolerance (0.001) to determine we have a flow along an
* arc.
*-----------------------------------------------------------

$set htmlfile2 network2.html
$set datafile2 networkdata2.js

file fln2 /%datafile2%/;
put fln2;
put 'networkdata=['/;
loop(n,
    put$(ord(n)>1) ",";
    put "{data:{id:",(ord(n)):0:0,",col:";
    put$tn(n) "'black'";
    put$sn(n) "'blue'";
    put$dn(n) "'green'";
    put ",size:"
    put$tn(n) "1";
    put$(sn(n) or dn(n)) "2";
    put "},position:{x:",coord(n,'x'):0:3;
    put ",y:",coord(n,'y'):0:3,"}}"/;
);
loop(a(i,j),
    put ",{data:{id:'",(ord(i)):0:0,'-',(ord(j)):0:0,"',";
    put "source:",(ord(i)):0:0,",target:",(ord(j)):0:0,",col:";
    put$(f.l(i,j)>=0.001) "'red'";
    put$(f.l(i,j)<0.001) "'grey'";
    put "}}"/;
);
put '];'/;

put "table='<h4>GAMS Min-Cost Flow Model</h4>"
    "Number of nodes: ",(card(n)):0:0,"<br>"
    "Number of arcs: ",(card(a)):0:0,"<br><br>"
    "<table><tr><th colspan=2>Supply Nodes</th></tr><tr><td>Node</td><td>Supply</td></tr>'+"/;
loop(sn(n),
    put "'<tr><td>",n.tl:0,"</td><td><pre>",inflow(n):10:3,"</pre></td></tr>'+"/;
);
put "'<tr><td>Total</td><td><pre>",(sum(n,inflow(n))):10:3,"</pre></td></tr>'+"/;
put "'</table><br><br><table><tr><th colspan=2>Demand Nodes</th></tr><tr><td>Node</td><td>Demand</td></tr>'+"/;
loop(dn(n),
    put "'<tr><td>",n.tl:0,"</td><td><pre>",outflow(n):10:3,"</pre></td></tr>'+"/;
);
put "'<tr><td>Total</td><td><pre>",(sum(n,outflow(n))):10:3,"</pre></td></tr>'+"/;
put "'</table><br><br>'+"/;
put "'<table><tr><th colspan=4>Flows</th></tr><tr><td>From</td><td>To</td><td>Flow</td><td>Capacity</td></tr>'+"/;
loop((i,j)$(f.l(i,j)>0.001),
    put "'<tr><td>",i.tl:0,"</td><td>",j.tl:0,"</td><td><pre>",f.l(i,j):10:3,"</pre></td><td><pre>",capacity(i,j):10:3,"</pre></td></tr>'+"/;
);
put "'</table>';"/;
putclose;


$onecho > %htmlfile2%
<html>
<head>
<title>GAMS Min-Cost Flow Network</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.20.0/cytoscape.min.js"></script>
<script src="%datafile2%"></script>
</head>

<style>
#cy {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0px;
    left: 0px;
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
                shape: 'circle',
                'background-color': 'data(col)',
                label: 'data(id)',
                width: 'data(size)', height: 'data(size)',
               'font-size': 1.5
            }
          },
          {
            selector: 'edge',
            style: { width: 0.1, 'line-color': 'data(col)',
                     'mid-target-arrow-shape': 'triangle',
                     'mid-target-arrow-color': 'data(col)',
                     'arrow-scale': '0.15' }
          }
        ],
        layout: { name: 'preset' }
      });
    </script>
</body>
</html>
$offecho

execute 'shellexecute "%htmlfile2%"';


*-----------------------------------------------------------
* transpotation model as network
* extra dummy demadnd node so we can balance supply and demand
*-----------------------------------------------------------

set
  nod 'nodes' /seattle,  san-diego, new-york, chicago, topeka, dummy /
  arcs(nod,nod) 'arcs' /  (seattle, san-diego) . (new-york, chicago, topeka, dummy) /

  supn(nod) 'supply nodes' / seattle,  san-diego /
  demn(nod) 'demand nodes' / new-york, chicago, topeka, dummy /
;

alias (nod,nod2);
display nod,arcs;

Parameter
   plantCapacity(supn) 'capacity of plant i in cases'
        / seattle     350
          san-diego   600  /

   marketDemand(demn) 'demand at market j in cases'
        / new-york    325
          chicago     300
          topeka      275  /;

marketDemand('dummy') = sum(supn,plantCapacity(supn)) - sum(demn,marketDemand(demn));
* now we have a balanced problem

Table dist(supn,demn) 'distance in thousands of miles'
               new-york       chicago        topeka
   seattle          2.5           1.7           1.8
   san-diego        2.5           1.8           1.4;

Scalar freight 'freight in dollars per case per thousand miles' / 90 /;

Parameter transCost(nod,nod2) 'transport cost in thousands of dollars per case';
transCost(supn,demn) = freight * dist(supn,demn) / 1000;

parameters
    Inflow2(nod)
    Outflow2(nod)
;
Inflow2(supn) = plantCapacity(supn);
Outflow2(demn) = marketDemand(demn);


positive variables ship(nod,nod2) 'shipment along link';

equations
   nodBal(nod) 'node balance'
   objective3
;

objective3.. totalCost =e= sum(arcs, ship(arcs)*transCost(arcs));

nodBal(nod)..
     sum(arcs(nod2,nod), ship(arcs)) + inflow2(nod) =e=
     sum(arcs(nod,nod2), ship(arcs)) + outflow2(nod);

model tp /objective3,nodBal/;
solve tp using lp minimizing totalCost;

display ship.l,totalCost.l;

$ontext

You should see something like:

----    780 VARIABLE ship.L  shipment along link

             new-york     chicago      topeka       dummy

seattle                   300.000                  50.000
san-diego     325.000                 275.000


----    780 VARIABLE totalCost.L           =      153.675

(Note that there are multiple optimal solutions).

$offtext






