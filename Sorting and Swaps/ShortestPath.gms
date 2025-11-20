$onText

   Shortest Path: minimize number of swaps when sorting
   
$offText

*--------------------------------------------------------
* data: from data file
*--------------------------------------------------------

set
   nodes 'all possible unique orderings'
   arcs(nodes,nodes) 'formed by a swap'
;

$offlisting
$include networkdata.inc

sets
   start(nodes)  'initial configuration' /BDADDDBCCC/
   final(nodes)  'sorted configuration'  /ABBCCCDDDD/
;

alias (n,n1,n2,nodes);

*--------------------------------------------------------
* summary of network
*--------------------------------------------------------

parameter counts(*) 'nodes/arcs';
counts('nodes') = card(nodes);
counts('arcs') = card(arcs);
option counts:0;
display counts;

*--------------------------------------------------------
* shortest path LP
*--------------------------------------------------------

positive variables f(n1,n2) 'flow along arcs';

variable z 'objective';

Equations
    obj       'objective'
    nodbal(n) 'node balance'
;

parameter
   supply(n) 'exogenous inflow'
   demand(n) 'exogenous outflow'
;

supply(start) = 1;
demand(final) = 1;

obj.. z =e= sum(arcs,f(arcs));

nodbal(n)..  sum(arcs(n1,n),f(arcs)) + supply(n) =e= sum(arcs(n,n1),f(arcs)) + demand(n);

model spath /all/;
option limrow=0,limcol=0,solprint=off;
solve spath minimizing z using lp;

display f.l;

*--------------------------------------------------------
* reporting: path
*--------------------------------------------------------

sets
    step 'for reporting' /step0*step50/
    visit(step,nodes) 'path'
;
singleton set curr(nodes) 'current node';
curr(n) = start(n);
loop(step$card(curr),
   visit(step,curr) = yes;
   curr(n2) = f.l(curr,n2)>0.5;
);
option visit:0:0:1;
display start,final,visit;