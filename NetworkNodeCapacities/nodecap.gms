$onText

   Model 1: basic min cost flow model with arc capacities and costs
   Model 2a: formulate node capacities as side constraints
   Model 2b: id, but remove duplicate expressions
   Model 3: handle node capacities within network by
            duplicating the nodes
   
$offText

option lp=cplex;

*----------------------------------------------------
* network topology
* both a small and medium sized data set
*----------------------------------------------------

* small data set. set to 0 or 1.
$set small 1    

$ifthen %small%==1
set
   i0 'superset of nodes' /node1*node6, nodedup1*nodedup6/
   i(i0) 'current nodes' /node1*node6/
   a(i0,i0) 'current arcs'
   sup(i0) 'supply nodes' /node1/
   dem(i0) 'demand nodes' /node6/
;
scalars
   supdem 'supply and demand quantities' /100/
   density 'fraction of arcs generated' /0.6/
;
$else
set
   i0 'superset of nodes' /node1*node50, nodedup1*nodedup50/
   i(i0) 'current nodes' /node1*node50/
   a(i0,i0) 'current arcs'
   sup(i0) 'supply nodes' /node1*node5/
   dem(i0) 'demand nodes' /node6*node10/
;
scalars
   supdem 'supply and demand quantities' /100/
   density 'fraction of arcs generated' /0.15/
;
$endif

alias (i0,j0), (i,j);


*----------------------------------------------------
* capacity, cost data
*----------------------------------------------------

Parameters
   cap(i0,j0) 'arc capacity'
   cost(i0,j0) 'arc cost'
   supply(i0) 'supply at supply nodes'
   demand(i0) 'demand at demand nodes'
   nodecap(i0) 'node capacity'
;

*----------------------------------------------------
* random data
*----------------------------------------------------

scalar printFlag 'if nonzero we display things';
printFlag = card(i)<=50;

* sparse network: not all a(i,j) exist
* no self loops
a(i,j)$(not sameas(i,j)) = uniform(0,1)<density;

cap(a) = uniform(10,80);
cost(a) = uniform(0,10);

supply(sup) = supdem;
demand(dem) = supdem;

* assume balanced supply and demand
abort$(sum(i,supply(i))<>sum(i,demand(i))) "total supply does not equal total demand";

* node cap should be >= supply or demand for supply and demand nodes
* otherwise the model would be infeasible
nodecap(i) = 20;
nodecap(sup) = supdem;
nodecap(dem) = supdem;

* for small networks print things
* for larger cases use the gdx viewer
* optional option for better, more compact display
$if %small%==0 option a:0:0:6, cap:3:0:5, cost:3:0:5;
display$printFlag i,a,sup,dem,cap,cost,supply,demand;


*----------------------------------------------------
* Model 1: 
* LP formulation of min cost flow network with
* arc capacities only
*----------------------------------------------------

variable totalcost;
positive variable f(i0,j0) 'flow';

Equations
    obj        'objective'  
    nodbal(i0)  'node balance'
;

obj.. totalcost =e= sum(a,cost(a)*f(a));

nodbal(i).. sum(a(j,i), f(a))+supply(i) =e= sum(a(i,j), f(a))+demand(i);

f.up(a) = cap(a);

model model1 /all/;

solve model1 using lp minimizing totalcost;
$if %small%==0 option f:3:0:5;
display totalcost.l,f.l;


*----------------------------------------------------
* reporting 
*----------------------------------------------------
parameter results(*,*);
results('model1: no node cap','obj') = totalcost.l;
display results;

parameter nodeflow(i0,*) 'flow through nodes';
nodeflow(i,'inflow') = sum(a(j,i), f.l(a))+supply(i);
nodeflow(i,'outflow') = sum(a(i,j), f.l(a))+demand(i);
display nodeflow;


*----------------------------------------------------
* Model 2a:
* add node capacity as constraints
* no longer a network model: will do LP iterations
* after network solve
*----------------------------------------------------

equation node_inflow_lim(i0);
node_inflow_lim(i).. sum(a(j,i), f(a))+supply(i) =l= nodecap(i);

model model2a /model1+node_inflow_lim/;

solve model2a using lp minimizing totalcost;
display totalcost.l,f.l;

results('model2a: side constraint','obj') = totalcost.l;
display results;


*----------------------------------------------------
* Model 2b:
* add node capacity as constraints, but remove duplicate
* expressions
* this is so close to a network problem that solvers can
* use the network solver exclusively to find the optimal
* solution. 
*----------------------------------------------------

positive variables
  nf(i0)  'inflow/outflow of node i'
;

equations
   def_inflow(i0)
   def_outflow(i0)
;

def_inflow(i).. nf(i) =e= sum(a(j,i), f(a))+supply(i);
def_outflow(i).. nf(i) =e= sum(a(i,j), f(a))+demand(i);

nf.up(i) = nodecap(i);

model model2b /obj,def_inflow,def_outflow/;

solve model2b using lp minimizing totalcost;
$if %small%==0 option nf:3:0:6;
display totalcost.l,f.l,nf.l;

results('model2b: sparse reformulation','obj') = totalcost.l;
display results;


*----------------------------------------------------
* Model 3:
* add node capacities by duplicating all nodes
*----------------------------------------------------

* pairs of original and duplicate nodes
* i.e. node1.nodedup1, node2.nodedup2, ...
set pairs(i0,i0) 'node pairs';
pairs(i0,i0+card(i)) = yes;


loop(pairs(i,j0),
* copy out links from nodeX to nodedupX
    a(j0,j) = a(i,j);
* remove old outlinks from nodeX 
    a(i,j) = no;
* add the link nodeX -> nodedupX
    a(i,j0) = yes;
* move cost, cap and demand
* supply does not need to be moved
    cost(j0,j) = cost(i,j);
    cost(i,j) = 0;
    cap(j0,j) = cap(i,j);
    cap(i,j) = 0;
    cap(i,j0) = nodecap(i);
    demand(j0) = demand(i);
    demand(i) = 0;
);

* the set i should now contain all nodes
i(i0) = yes;

display$printFlag i,a,cost,cap,supply,demand;

* redo the bounds as cap has changed
f.up(a) = cap(a);

* get rid of older values so displays are clean
f.l(i0,j0) = 0;

solve model1 using lp minimizing totalcost;
display totalcost.l,f.l;
results('model1: duplicated nodes','obj') = totalcost.l;
display results;
 