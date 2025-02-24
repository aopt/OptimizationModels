$onText

 Implementation of Dijkstra's algorithm for the shortest path problem.
 
 From: https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm


  1. Dijkstra's shortest path algorithm implemented in GAMS
  2. Dijkstra's shortest path algorithm implemented in Python
  3. Shortest path as LP
  4. Visualization of network and shortest path
  
$offText


*-----------------------------------------------------
* set up network
*-----------------------------------------------------

set i 'nodes' /node1*node50/;
alias (i,j,v);

set a(i,j) 'arcs of sparse network';
* no self loops and density of 15%
a(i,j)$(ord(i)<>ord(j)) = uniform(0,1)<0.15;

singleton sets
   source(i) /node1/
   sink(i)   /node49/   
;
* sink is chosen so optimal path needs quite a few hops

parameter cost(i,j) 'random costs (lengths)';
cost(a) = uniform(1,10);

option a:0:0:7, cost:3:0:6;
display$(card(i)<=50)
   "============== data ==============",
   i,source,sink,a,cost;


*=====================================================
* 1.  Dijkstra GAMS algorithm
*=====================================================

*-----------------------------------------------------
* data structures
*-----------------------------------------------------

sets
   prev(i,j) 'i is previous wrt j'
   Q(i)      'unvisited nodes'   
;
parameter dist(i) 'distance from source';

* initialize
Q(i) = yes;
dist(i) = INF;
dist(source) = 0;


*-----------------------------------------------------
* algorithm
*-----------------------------------------------------

scalar mindist;
singleton set u(i);
scalar alt;

* if multiple assignments to singleton set,
* only the last one will remain. This will
* guarantee a singleton set will hold
* 0 or 1 elements.
option strictSingleton=0;

while(card(Q)>0,

* find node in Q with minimum distance from the source
   mindist = smin(q,dist(q));
   u(Q) = dist(Q)=mindist;

* remove u from Q
   Q(u) = no;

* loop over neighbors of u in Q
   loop(a(u,v)$Q(v),
      alt = dist(u) + cost(a);
      if(alt < dist(v),
         dist(v) = alt;
         prev(i,v) = no;
         prev(u,v) = yes;
      );
   );   
);

option prev:0:0:7,dist:3:0:6;
display
   "============== Dijkstra (GAMS) ==============",
   prev,dist;
parameter results(*,*);
results('Dijkstra (GAMS)','obj') = dist(sink);
display results;

*-----------------------------------------------------
* recover path
* more complicated than the algorithm itself
*-----------------------------------------------------

set s /step1*step25/;
singleton sets
   n(i) 'current node'
   p(i) 'previous node'   
;
parameter steps(s,i,j) 'cost for each step taken';
option steps:3:0:1;
steps(s,i,j) = 0;

* initialization
n(sink) = yes;

* loop from last (sink) to first (source)
repeat
   p(i) = no;
* loop finds v given n
* body of loop is executed 0 or 1 times
   loop(prev(v,n),
* make room by moving all steps one down   
      steps(s,i,j) = steps(s-1,i,j);
      steps('step1',prev) = cost(prev);
      p(v) = yes;
   );
   n(i) = p(i);  
until card(n)=0;

display steps;


*=====================================================
* 2.  Dijkstra Python algorithm
*=====================================================

parameters
   psteps(s,i,j) 'results from python code'
   pobj   'objective function value'
;

* just in case we have arcs with costs=0
cost(a)$(cost(a)=0) = eps;

embeddedCode Python:

#-- import GAMS data
import gams.transfer as gt

nodes=list(gams.get('i'))
print(f"i={nodes}")

source=list(gams.get('source'))[0]
print(f"source={source}")

sink=list(gams.get('sink'))[0]
print(f"sink={sink}")

m = gt.Container(gams.db)
dfcost = m.data["cost"].records
print(dfcost)

#-- data structures
successors = {v:[] for v in nodes}
cost = {}
for index, row in dfcost.iterrows():
    u = row['i']
    v = row['j']
    successors[u].append(v)
    cost[(u,v)] = row['value']    

#print(successors)

#-- initialization
Q=set(nodes)
inf=float('inf')
dist = {v:inf for v in nodes}
dist[source] = 0
prev = {v:None for v in nodes}

#-- run algorithm
while len(Q)>0:
    u = min(Q, key=lambda n:dist[n])
    Q.remove(u)
    
    for v in successors[u]:
        if v in Q:
           alt = dist[u] + cost[(u,v)]
           if alt < dist[v]:
              dist[v] = alt
              prev[v] = u
              
print(f"optimal total cost: {dist[sink]}")

#-- recover path
path = []
u = sink
while u is not None:
   path.insert(0,u)
   u = prev[u]
   
print(path)

#-- move things back to GAMS

stepsdata = [(f"step{i}",path[i-1],path[i],cost[(path[i-1],path[i])]) for i in range(1,len(path))]
gams.set("psteps",stepsdata)
gams.set("pobj",[dist[sink]])

endEmbeddedCode psteps,pobj



option psteps:3:0:1;
display
   "============== Dijkstra (Python) ==============",
   psteps,pobj;

results('Dijkstra (Python)','obj') = pobj;
display results;



*=====================================================
* 3.  LP Model
*=====================================================

parameters supply(i), demand(i);
supply(source) = 1;
demand(sink) = 1;

positive variables x(i,j) 'flow along i->j';
variable z 'objective';

equations
   obj 'objective'
   nodebal(i) 'node balance'
;

obj.. z =e= sum((i,j),cost(i,j)*x(i,j));
nodebal(i).. sum(a(j,i),x(a)) + supply(i) =e= sum(a(i,j),x(a)) + demand(i);

model m /all/;
solve m minimizing z using lp;

display
   "============== LP model ==============",
   x.l,z.l;
results('LP','obj') = z.l;
display results;

*-----------------------------------------------------
* recover path
*-----------------------------------------------------

parameters
   lpsteps(s,i,j) 'results from LP model'
;
singleton set next(i) 'next node';

n(i) = source(i);
loop(s$card(n),
     next(i) = x.l(n,i)>0.5;
     lpsteps(s,n,next) = cost(n,next);
     n(i) = next(i);
);
option lpsteps:3:0:1;
display lpsteps;


*=====================================================
* 4.  Visualization
*=====================================================


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
loop(i,
    put$(ord(i)>1) ",";
    put "{data:{id:",(ord(i)):0:0;
    put$(supply(i)=0 and demand(i)=0) ",color:'black'";
    put$(supply(i)>0) ",color:'blue'";
    put$(demand(i)>0) ",color:'green'";
    put$(supply(i)=0 and demand(i)=0) ",size:1";
    put$(supply(i)>0 or demand(i)>0) ",size:2";
    put "}}"/;
);
loop(a(i,j),
    put ",{data:{id:'",(ord(i)):0:0,'-',(ord(j)):0:0,"',";
    put "source:",(ord(i)):0:0,",target:",(ord(j)):0:0;
    put$(x.l(i,j)>0.5) ",color:'red',width:0.2";
    put$(x.l(i,j)<0.5) ",color:'grey',width:0.1";
    put "}}"/;
);
put '];'/;

put "table='<h4>GAMS Shortest Path</h4>"
    "Number of nodes: ",(card(i)):0:0,"<br>"
    "Number of arcs: ",(card(a)):0:0,"<br><br>"
    "<table><tr><th>From</th><th>To</th><th>cost</th></tr>'+"/;
loop((s,i,j)$lpsteps(s,i,j),
   put "'<tr><td>",i.tl:0,"</td><td>",j.tl:0,"</td><td><pre>",cost(i,j):10:3,"</pre></td></tr>'+"/;
);
put "'<tr><td colspan=2>Total cost</td><td><pre>",z.l:10:3,"</pre></td></tr>'+"/;

put "'</table><br>';";
putclose;


$ontext

With an internet connection you can use:
  <script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.30.4/cytoscape.min.js"></script>
Without use a local .js file:
  <script src="cytoscape.min.js"></script>

$offtext

$onecho > %htmlfile%
<html>
<head>
<title>GAMS Shortest Path Network</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.30.4/cytoscape.min.js"></script>
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

          }
        ],
        layout: { name: 'cose' }
      });


      const loopAnimation = (ele, i) => {
          const offset = { style: {'line-dash-offset': -100 * i } };
          const duration = { duration: 10000 };
          return ele.animation(offset, duration).play()
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

execute "%htmlfile%";

