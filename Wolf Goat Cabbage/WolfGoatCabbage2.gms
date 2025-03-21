$onText

   Same problem as WolfGoatCabbage.gms, but now as shortest path problem

$offText


*----------------------------------------------------------------------
* nodes
*----------------------------------------------------------------------

* for ordering of displays we want to have this first
set dummy /'initial'/;


sets
   side 'left or right bank' /L,R/
   item /wolf,goat,cabbage/
   node /node1*node16/
   left(node) /node1*node8/
   right(node) /node9*node16/
;

alias (side,nodeloc);

* enumerate states: location of node + inventory 
set state(node,nodeloc,side,item)  'state: node location + inventory' /
* node (or boat) is on the left bank
       (node1.L).(L.wolf,L.goat,L.cabbage)     
       (node2.L).(L.wolf,L.goat,R.cabbage)    
       (node3.L).(L.wolf,R.goat,L.cabbage)    
       (node4.L).(L.wolf,R.goat,R.cabbage)    
       (node5.L).(R.wolf,L.goat,L.cabbage)    
       (node6.L).(R.wolf,L.goat,R.cabbage)    
       (node7.L).(R.wolf,R.goat,L.cabbage)    
       (node8.L).(R.wolf,R.goat,R.cabbage)
       
* node (or boat) is on the right bank
       (node9.R).(L.wolf,L.goat,L.cabbage)     
       (node10.R).(L.wolf,L.goat,R.cabbage)    
       (node11.R).(L.wolf,R.goat,L.cabbage)    
       (node12.R).(L.wolf,R.goat,R.cabbage)    
       (node13.R).(R.wolf,L.goat,L.cabbage)    
       (node14.R).(R.wolf,L.goat,R.cabbage)    
       (node15.R).(R.wolf,R.goat,L.cabbage)    
       (node16.R).(R.wolf,R.goat,R.cabbage)    
    /
;

* display state  
option state:0:2:2;
display state;

* drop node location index to form inventory parameter
parameter inv(node,side,item) 'inventory';
inv(node,side,item) = sum(state(node,nodeloc,side,item),1); 
option inv:0:1:2;
display inv;


* not all nodes are allowed
* we could have done this by hand by dropping nodes from the
* state set. Instead, let's see how this looks like in code.
set
   combo  'combinations not allowed'  /combo1,combo2/
   forbidden(combo,item) /
         combo1.(wolf,goat)
         combo2.(goat,cabbage)
   /
   nodex(node) 'forbidden node when left unattended'
 ;

* populate nodex with forbidden nodes
* check inventory of side where node is not located 
loop((combo,nodeloc,side)$(ord(side)<>ord(nodeloc)),
  nodex(node)$(sum(forbidden(combo,item)$state(node,nodeloc,side,item),1) = 2) = yes;
);
display nodex;

set rnode(node) 'reduced node set';
rnode(node) = yes;
rnode(nodex) = no;
display rnode;



*----------------------------------------------------------------------
* arcs
* we have a directed arc from:
*  1. L->R and R->L
*  2. with 0 or 1 passengers
*----------------------------------------------------------------------

alias (rnode,n1,n2);

set
  otherside(node,node) 'nodes are at opposite side'
  arc(node,node)       'edges'
  pax(node,node,*)     'passengers along arc' 
;

otherside(left(n1),right(n2)) = yes;
otherside(right(n1),left(n2)) = yes;
display otherside;

Parameter
    diff(node,node,item) 'differences in L inventory between node1->node2'
    numdiff(node,node) 'number of differences in L inventory'
    sumdiff(node,node) 'sum of differences in L inventory'
;
diff(otherside(n1,n2),item) = inv(n1,'L',item)-inv(n2,'L',item);
numdiff(otherside(n1,n2)) = sum(item,abs(diff(n1,n2,item)));
sumdiff(otherside(n1,n2)) = sum(item,diff(n1,n2,item));

sets
   diff0(node,node) 'no difference in inventory: trip with zero passengers'
   diff1(node,node) 'one difference in inventory: trip with one passenger'
;   
diff0(otherside) = numdiff(otherside) = 0;
diff1(left(n1),right(n2)) = numdiff(n1,n2)=1 and sumdiff(n1,n2)=1;
diff1(right(n1),left(n2)) = numdiff(n1,n2)=1 and sumdiff(n1,n2)=-1;
display diff0,diff1;

* zero passengers: inventory stays the same
arc(otherside)$(numdiff(otherside)=0) = yes;

* one passenger: move item from node1->node2
arc(diff1) = yes;

* pax moved
pax(arc(diff1),item) = abs(diff(diff1,item))=1;
pax(arc(diff0),'empty') = yes;
display pax;


*----------------------------------------------------------------------
* shortest path model
*----------------------------------------------------------------------

Parameters
   supply(node)  / node1 1 /
   demand(node)  / node16 1 /
;

binary variable f(node,node) 'flow';
variable z 'objective';

equations
   flowbal(node) 'flow balance'
   obj           'objective'
;

obj.. z =e= sum(arc,f(arc));

flowbal(n1)..
   sum(arc(n2,n1),f(n2,n1)) + supply(n1) =e= sum(arc(n1,n2),f(n1,n2)) + demand(n1);

model shortestpath /all/;
solve shortestpath minimizing z using rmip;
display f.l;


*----------------------------------------------------------------------
* reporting
*----------------------------------------------------------------------

set
   trip /trip1*trip10/
   trace(*,*,*,*,side,item) 'results from LP model'
;
singleton sets
  n(node) 'current node' /node1/
  next(node) 'next node'
;

alias(item,item2);

trace('initial','node1','','',side,item)$inv('node1',side,item) = yes;
loop(trip$card(n),
     next(node) = f.l(n,node)>0.5;
* with passenger     
     trace(trip,n,next,item,side,item2)$(pax(n,next,item) and inv(next,side,item2))= yes;
* without passenger
     trace(trip,n,next,'',side,item2)$(sum(pax(n,next,item),1)=0 and inv(next,side,item2)) = yes;
     n(node) = next(node);
);
option trace:0:4:2;
display trace;