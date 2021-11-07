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

set
   n 'nodes (vertices)' /node1*node50/
   a(n,n) 'arcs (edges)'
;

alias (n,i,j);

* sparse random network
a(i,j)$(uniform(0,1)<0.05) = yes;
* a(i,j) = uniform(0,1)<0.05;

display$(card(n)<=50) n,a;

$stop

$ontext

   exercises:

     1.1. rerun the model a few times and observe results are the same
          GAMS uses a pseudo random number generator with a default seed
          set seed with "option seed=nnn;" or "execseed = nnnn;"
          if you want a new graph each run, use:
          execseed = 1+gmillisec(jnow);
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


$offtext

$stop

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

$offtext

$stop

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

$offtext

$stop

*-----------------------------------------------------------
* random coordinates
* for plotting and for length calculation
*-----------------------------------------------------------

set xy /x,y/;
parameter coord(n,xy) 'x-y coordinates';
coord(n,xy) = uniform(0,100);
display coord;

$ontext

  We could have used two parameters x and y.
  Sometimes combining things using an extra index
  can help in making model more manageable (fewer parameters)

$offtext

*-----------------------------------------------------------
* make a plot of the network
* optional part. Skip if you are not a Python programmer
*-----------------------------------------------------------

* uncomment to run the Python-related part
*$goto skip_python_section

* file names
$set pythonscript   network.py
$set picklefile     network.pkl

* I installed networkx here (change to your Python path)
$set py d:\python\python39\python.exe %pythonscript%


* part 1: export data as pickle file
embeddedCode Python:
import pickle
nodes = list(gams.get('n'))
arcs = list(gams.get('a'))
coord = list(gams.get('coord'))
data = {'nodes':nodes, 'arcs':arcs, 'coord':coord}
pickle.dump(data,open('%picklefile%', 'wb'))
endEmbeddedCode


* part 2: use pickle file to display network using networkx package
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

# make labels shorter for better display
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

$ontext

  Exercise:
    We used nx.convert_node_labels_to_integers to have short node labels.
    We can do this in GAMS instead
       3.1. by using a different set declaration.
       3.2. by keeping the original set and introducing mapping sets.

$offtext

$stop

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

$stop


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

$stop

$ontext

   Exercise 4: form path without using singleton sets

$offtext


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


$stop


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


$ontext

With an internet connection you can use:
  <script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.20.0/cytoscape.min.js"></script>
Without use:
  <script src="cytoscape.min.js"></script>

$offtext

$onecho > %htmlfile%
<html>
<head>
<title>GAMS Shortest Path Network</title>
<script src="cytoscape.min.js"></script>
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

execute 'shellexecute "%htmlfile%"';

$stop

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

option seed=12345;
* different seed may make the model infeasible

set
  sn(n) 'supply nodes'  /node3,node14,node32/
  dn(n) 'demand nodes'  /node18,node29,node31,node36,node34/
  tn(n) 'transhipment node'
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
* total demand distributed over supply nodes
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



$ontext


  exercises:

   5.1. Adapt the HTML report to display these results
   5.2. Convert the original trnsport.gms model to a
        min-cost flow problem.



$offtext
