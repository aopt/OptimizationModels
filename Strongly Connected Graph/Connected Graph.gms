$onText

  1. Generate random nodes

$offText


$set numNodes 25

option seed=1234, reslim=1000;

*-------------------------------------------------------
* nodes
*-------------------------------------------------------
sets
    i 'nodes' /node1*node%numNodes%/
    c 'coordinates' /x,y/
;
alias (i,j);

parameters
   p(i,c)  'node locations (points)'
   d(i,j)  'distances'
;
p(i,c) = uniform(0,100);
d(i,j) = sqrt(sum(c,sqr(p(i,c)-p(j,c))));

option d:3:0:7;
display i,p,d;

*-------------------------------------------------------
* arcs
*-------------------------------------------------------

sets
   offd(i,j) 'off-diagonal: no self-loops'
   a1(i,j) 'directed arcs v1'
   a2(i,j) 'directed arcs v2'
;

* generate a sparse graph
offd(i,j) = ord(i)<>ord(j);

a1(offd)$(d(offd)<35) = uniform(0,1)<0.4;
a2(offd)$(d(offd)<40) = uniform(0,1)<0.5;

option a1:0:0:7,a2:0:0:7;

*-------------------------------------------------------
* strongly connected components (SCCs)
*-------------------------------------------------------

$ontext

This will show:

  Data set: i,a1 -> icomp1
  Number of strongly connected components:3
  Data set: i,a2 -> icomp2
  Number of strongly connected components:1

$offtext

sets
  comp 'strongly connected components (superset)' /comp1*comp100/
  icomp1(i,comp) 'node/component mapping for arc set a1'
  icomp2(i,comp) 'node/component mapping for arc set a2'
;

EmbeddedCode Python:

#------------------------------------------------------------------------------
# import nodes and arcs from GAMS
#------------------------------------------------------------------------------


# https://youcademy.org/tarjans-scc-algorithm/

def dfs(graph, node, counter, index, low_link, stack, on_stack, sccs):
  """
  Perform Depth-First Search (DFS) to find Strongly Connected Components (SCCs)
  
  Args:
    graph: Adjacency list representation of the graph
    node: Current node being processed
    counter: Counter for assigning discovery indices
    index: Mapping of node to its index in the DFS
    low_link: Mapping of node to its low-link value
    stack: Stack to keep track of nodes in the DFS search tree
    on_stack: Set of nodes currently on the stack
    sccs: List to store the found Strongly Connected Components
  """
  index[node] = counter
  low_link[node] = counter
  counter += 1
  stack.append(node)
  on_stack.add(node)

  # Iterate over all neighbors of the current node
  for neighbor in graph[node]:
    if neighbor not in index:
      # If the neighbor hasn't been visited, perfom dfs on it's subtree
      dfs(graph, neighbor, counter, index, low_link, stack, on_stack, sccs)
      # Update the low-link value based on the neighbor's low-link
      low_link[node] = min(low_link[node], low_link[neighbor])
    elif neighbor in on_stack:
      low_link[node] = min(low_link[node], index[neighbor])

  # Check if the current node is a root node for an SCC
  if low_link[node] == index[node]:
    scc = []
    # Pop all nodes from the stack upto
    # the root node and add them to current SCC
    while stack:
      top = stack.pop()
      on_stack.remove(top)
      scc.append(top)
      if top == node:
        break
    sccs.append(scc)

def tarjan_scc(graph):
  """
  Find the Strongly Connected Components (SCCs) in the given graph using Tarjan's algorithm.
  
  Args:
    graph: Adjacency list representation of the graph
  
  Returns:
    list: List of Strongly Connected Components (SCCs)
  """
  counter = 0 # Counter to set discovery indices
  index = {} # Map to store discovery index of each node
  low_link = {} # Map to store low-link value of each node
  stack = [] # Stack to store nodes which yet to be mapped to an SCC
  on_stack = set() # Set to store nodes which are present on stack
  sccs = [] # List to store all SCCs in the given graph

  for node in graph:
    if node not in index:
      # Current node is not visited yet
      # So let's perform a DFS and group nodes into SCC's
      dfs(graph, node, counter, index, low_link, stack, on_stack, sccs)

  return sccs

def loadDataFromGAMS(nodeset,arcset):
   # set up graph in format required by tarjan routine
   # dictionary with {node:list_of_nodes} where
   # list containts nodes pointed to by node
   graph = {node:[] for node in gams.get(nodeset)}
   for a in gams.get(arcset):
       graph[a[0]].append(a[1])    
   return(graph)

def saveResultsToGAMS(sccs,icompset):
   # GAMS set is defined over (node,comp)
   icomp = []
   for comp,arr in enumerate(sccs):     
      scomp = f"comp{comp+1}"
      for node in arr:
         icomp.append((node,scomp))
   gams.set(icompset,icomp)      

def run(nodeset,arcset,icompset):
   gams.printLog(f"Data set: {nodeset},{arcset} -> {icompset}")
   graph = loadDataFromGAMS(nodeset,arcset)
   sccs = tarjan_scc(graph)
   gams.printLog(f"Number of strongly connected components:{len(sccs)}")
   saveResultsToGAMS(sccs,icompset)
   
run("i","a1","icomp1")
run("i","a2","icomp2")

endEmbeddedCode icomp1,icomp2 


parameter ncomp(*) 'number of disconnected components';
option ncomp:0;
ncomp("a1") = sum(comp$sum(icomp1(i,comp),1),1);
ncomp("a2") = sum(comp$sum(icomp2(i,comp),1),1);
display a1,icomp1,a2,icomp2;


*-------------------------------------------------------
* reporting macros
*-------------------------------------------------------


parameter results(*,*);

acronym Optimal,IntFeas;
$macro collect_stats(id,m) \
     results('Variables',id) = m.numvar; \
     results('  Discrete',id) = m.numdvar; \
     results('Equations',id) = m.numequ; \
     results('Modelstat',id) = m.modelstat; \
     results('Modelstat',id)$(m.modelstat=1) = Optimal; \
     results('Modelstat',id)$(m.modelstat=8) = IntFeas; \
     results('Objective',id) = m.objval; \
     results('Solver time',id) = m.etSolver; \
     results('Nodes',id) = m.nodusd; \
     results('Gap%',id)$(m.solvestat=3) = 100*abs(m.objest - m.objval)/abs(m.objest); \
     display results;

     

*-------------------------------------------------------
* flow model 1
* data set a2
*-------------------------------------------------------

* we need to add a source and destination index
alias(i,s,t);

set
   a(i,j) 'arcs'
;

parameter
  supply1(i,s) 'supply at supply nodes'
  demand1(i,t) 'demand at demand nodes'
  M1           'big M'
  cost(i,j)    'cost coefficients'
;

supply1(s,s) = 1;
demand1(t,t) = 1;
M1 = sqr(card(i))-card(i);

binary variables
   f1(i,j,s,t) 'flow i → j on path s → t'
   u(i,j) 'arc is used'
;
variable z;

equations
    nodebal1(i,s,t)   'node balance'
    usage1a(i,j,s,t)  'usage of arc (disaggregated version)'
    usage1b(i,j)      'usage of arc (aggregated version)'
    obj1              'objective'
;

nodebal1(i,s,t)$offd(s,t)..
   sum(a(j,i),f1(a,s,t)) + supply1(i,s) =e=
   sum(a(i,j),f1(a,s,t)) + demand1(i,t);
   
* u(i,j) = 0 => f1(i,j,src,dst) = 0
* two versions (aggregated and disaggregated)

usage1a(a(i,j),s,t)$offd(s,t).. f1(i,j,s,t) =l= u(i,j);
usage1b(a(i,j)).. sum(offd(s,t),f1(i,j,s,t)) =l= M1*u(i,j);

obj1.. z =e= sum(a,cost(a)*u(a));

model flowmodel1a /nodebal1,usage1a,obj1/;
model flowmodel1b /nodebal1,usage1b,obj1/;


*-------------------------------------------------------
* flow model 2
*-------------------------------------------------------

parameter
  supply2(i,s) 'supply at supply nodes'
  demand2(i,s) 'demand at demand nodes'
;

supply2(s,s) = card(i)-1;
demand2(offd(i,s)) = 1;

integer variables f2(i,j,s) 'flow i → j on path from s';

equations
    nodebal2(i,s)   'node balance'
    usage2a(i,j,s)  'usage of arc (disaggregated version)'
    usage2b(i,j)    'usage of arc (aggregated version)'
    obj2            'objective'
;

nodebal2(i,s)..
   sum(a(j,i),f2(a,s)) + supply2(i,s) =e=
   sum(a(i,j),f2(a,s)) + demand2(i,s);
   
* use(i,j) = 0 => flow2(i,j,src) = 0
* again: two versions
usage2a(a(i,j),s).. f2(a,s) =l= card(i)*u(a);
usage2b(a).. sum(s,f2(a,s)) =l= M1*u(a);

model flowmodel2a /nodebal2,usage2a,obj1/;
model flowmodel2b /nodebal2,usage2b,obj1/;

*-------------------------------------------------------
* flow model 2 but with a given number of arcs as target 
*-------------------------------------------------------

scalar numArcsUsed 'target number of arcs';
numArcsUsed = card(i)*2;

* deviations from target
positive variable d1,d2;

equation fixNumArcs 'stay close to target number of arcs';
fixNumArcs.. sum(a,u(a)) =e= numArcsUsed + d1 - d2;

equation obj2 'weighted multiple objective';
* most emphasis on target number of arcs
obj2.. z =e= sum(a,cost(a)*u(a)) + 1e4*(d1+d2); 

model flowmodel2afx /nodebal2,usage2a,obj2,fixNumArcs/;


*-------------------------------------------------------
* Solve models
*-------------------------------------------------------


* use the second data set
a(i,j) = a2(i,j);

* choose min number of arcs or weight by length
* the latter will prefer shorter arcs which may be
* giving better look graphs.
*cost(a) = 1; 
cost(a) = d(a);

* relax the flow variables
f1.prior(i,j,s,t) = INF;
f2.prior(i,j,s) = INF;

solve flowmodel1a using mip minimizing z;
collect_stats('model 1a',flowmodel1a)
solve flowmodel1b using mip minimizing z;
collect_stats('model 1b',flowmodel1b)

solve flowmodel2a using mip minimizing z;
collect_stats('model 2a',flowmodel2a)
solve flowmodel2b using mip minimizing z;
collect_stats('model 2b',flowmodel2b)

solve flowmodel2afx using mip minimizing z;
collect_stats('model 2afx',flowmodel2afx)


parameter usol(i,j) 'solution of last solve';
usol(a) = round(u.l(a));


*-------------------------------------------------------
* visualization
*-------------------------------------------------------

$set htmlfile report.html

file html /%htmlfile%/ 
put html;

$onPutS
<html>
<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
<script src="https://cdn.plot.ly/plotly-3.0.1.min.js" charset="utf-8"></script>
<style>
table,th, td {
    border: 1px solid black;
    border-collapse: collapse;
    padding-left: 10px;
    padding-right: 10px;
}
p { max-width:800px; }
</style>

<script>

$offPut

* export GAMS data to JS

* nodes
alias (comp,comp1,comp2);
put "nodes=["/;
loop((icomp1(i,comp1),icomp2(i,comp2)),
   put "{x:",p(i,'x'):0:3,",y:",p(i,'y'):0:3,",comp1:",ord(comp1):0:0,",comp2:",ord(comp2):0:0,"},"/;
);
put "];"/;

* arc set 1
put "arcs1=["/;
loop(a1(i,j),
  put "{i:",ord(i):0:0,",j:",ord(j):0:0,"},"/;
);
put "];"/;

* arc set 2
put "arcs2=["/;
loop(a2(i,j),
  put "{i:",ord(i):0:0,",j:",ord(j):0:0,"},"/;
);
put "];"/;

put "ncomp1=",ncomp('a1'):0:0,";"/;
put "ncomp2=",ncomp('a2'):0:0,";"/;

* MIP solution
put "sol=["/;
loop((i,j)$usol(i,j),
  put "{i:",ord(i):0:0,",j:",ord(j):0:0,"},"/;
);
put "];"/;


$onPut


// extract coordinates as arrays
xpoints = nodes.map(({x})=>x);
ypoints = nodes.map(({y})=>y);


n = nodes.length;
na1 = arcs1.length;
na2 = arcs1.length;


// color array
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

function formColorArray(comp) {
    scolor = [];
    for (i=0; i<n; ++i) {
       c = nodes[i][comp]-1;
       scolor.push(colors[c % colors.length]);
    }
    return scolor; 
}
scol1 = formColorArray("comp1");
scol2 = formColorArray("comp2");

// plotly trace for node plot
trace1 = {
  x: xpoints,
  y: ypoints,
  mode: 'markers',
  type: 'scatter',
  marker: { color: 'black' }
};

// plotly trace for component plot

trace2 = {
  x: xpoints,
  y: ypoints,
  mode: 'markers',
  type: 'scatter',
  marker: { color:scol1, size:8 }
};

trace3 = {
  x: xpoints,
  y: ypoints,
  mode: 'markers',
  type: 'scatter',
  marker: { color:scol2, size:8 }
};


// annotations are used to plot arrows

function formAnnotations(arcs,comp,scolor) {
    annots = [];  // array with annotations
    for (k=0; k < arcs.length; ++k) {
       // (i,j) are node numbers (zero based) 
       i = arcs[k]['i']-1;
       j = arcs[k]['j']-1;
       // colors are component numbers (zero based)
       ci = scolor[i];
       cj = scolor[j];
       // if different then use a light gray arrow
       if (ci===cj) {
          col = ci;
       }
       else {
          col = 'LightGray';
       }
       
       // populate annotation
       ann = {
         ax:xpoints[i], ay:ypoints[i],
         x:xpoints[j], y:ypoints[j],
         axref:"x", ayref:"y",
         xref:"x", yref:"y",
         text:'',  // if you want only the arrow
         showarrow:true,
         arrowhead:3,
         arrowsize:1.4,
         arrowwidth:1.3,   
         arrowcolor:col,
       }
       annots.push(ann);
    }
    return annots;
}

var layout2 = {showlegend: false, annotations:formAnnotations(arcs1,"comp1",scol1) };
var layout3 = {showlegend: false, annotations:formAnnotations(arcs2,"comp2",scol2) };
var layout4 = {showlegend: false, annotations:formAnnotations(sol,"comp2",scol2) };

</script>

<body>
<h1>Generating Connected Graphs</h1>

<h2>Nodes</h2>
<p>The locations of the \(n=%numnodes%\) points are randomly generated and drawn from the uniform distribution.</p>
<div id="myPlot1" style="width:100%;max-width:800px;height:600px"></div>
<script>Plotly.newPlot('myPlot1', [trace1]);</script>

<h2>Arcs</h2>

<h3>Data set 1</h3>

We used simple GAMS code to generate <script>document.write(na1)</script>
arcs. The number of disconnected components is <script>document.write(ncomp1)</script>.

<div id="myPlot2" style="width:100%;max-width:800px;height:600px"></div>
<script>Plotly.newPlot('myPlot2', [trace2], layout2);</script>

<h3>Data set 2</h3>

This data set is yielding a strongly connected graph.

<div id="myPlot3" style="width:100%;max-width:800px;height:600px"></div>
<script>Plotly.newPlot('myPlot3', [trace3], layout3);</script>

<h3>MIP model results</h3>

<div id="myPlot4" style="width:100%;max-width:800px;height:600px"></div>
<script>Plotly.newPlot('myPlot4', [trace3], layout4);</script>

</body>
</html>
$offPut


executetool 'win32.ShellExecute "%htmlfile%"';


