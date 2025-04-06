$onText

  Towers of Hanoi, network formulation

$offText


*-----------------------------------------------------------------------------------
* size of problem
*-----------------------------------------------------------------------------------

$set n 3

*-----------------------------------------------------------------------------------
* nodes
*-----------------------------------------------------------------------------------

$eval nn power(3,%n%)

set
  node /node1*node%nn%/
  disk /disk1*disk%n%/
  peg /pegA,pegB,PegC/
  nodes(node,disk,peg) / system.powersetRight /
;

scalars
   n  'number of disks' /%n%/
   nn 'number of nodes' /%nn%/
;

display disk,peg,node,nodes;

*-----------------------------------------------------------------------------------
* arcs
*-----------------------------------------------------------------------------------

set arc(node,node);

alias (node,node1,node2), (disk,disk1,disk2), (peg,peg1,peg2), (nodes,nodes1,nodes2);

set smallest(node,disk,peg) 'smallest disk on peg';
smallest(node,disk,peg) = smin(disk2$nodes(node,disk2,peg),ord(disk2)) = ord(disk);
display smallest;

parameter nodeVal(node,disk) 'peg number of (node,disk)';
nodeVal(node,disk) = sum(nodes(node,disk,peg),ord(peg));
display nodeVal;

set nodediff1(node,node) '(node1,node2) combos with one difference';
nodediff1(node1,node2) = sum(disk$(abs(nodeVal(node1,disk)-nodeVal(node2,disk))>0.5),1)=1;
display nodediff1;

set nodeDiff1disk(node,node,disk) 'augment nodediff1 with disk id';
nodeDiff1Disk(nodeDiff1(node1,node2),disk) = abs(nodeVal(node1,disk)-nodeVal(node2,disk))>0.5;
display nodeDiff1Disk;

set diskMoved(node,node,disk) 'feasible moves';
singleton set p1(peg),p2(peg);
loop(nodeDiff1disk(node1,node2,disk),
   p1(peg) = nodeval(node1,disk)=ord(peg);
   p2(peg) = nodeval(node2,disk)=ord(peg);
   diskMoved(node1,node2,disk) = smallest(node1,disk,p1) and smallest(node2,disk,p2);  
);
display diskMoved;

arc(node1,node2) = sum(diskMoved(node1,node2,disk),1);

* check
scalar narcs 'number of directed arcs in Hanoi graph';
narcs = 3*(power(3,n) - 1);
abort$(card(arc)<>narcs) "number of arcs is incorrect";

*----------------------------------------------------------------------
* shortest path model
*----------------------------------------------------------------------

Parameters
   supply(node)
   demand(node)  
;
supply(node)$(sum(nodes(node,disk,'pegA'),1) = n) = 1;
demand(node)$(sum(nodes(node,disk,'pegB'),1) = n) = 1;

binary variable f(node,node) 'flow';
variable z 'objective';

equations
   flowbal(node) 'flow balance'
   obj           'objective'
;

obj.. z =e= sum(arc,f(arc));

flowbal(node1)..
   sum(arc(node2,node1),f(node2,node1)) + supply(node1) =e= sum(arc(node1,node2),f(node1,node2)) + demand(node1);

model shortestpath /all/;
solve shortestpath minimizing z using rmip;
display f.l;

*----------------------------------------------------------------------
* reporting
*----------------------------------------------------------------------

set
    move/move1*move100/
    trace(move,node,node,disk,peg,peg)    
;

singleton sets
  cur(node) 'current node' /node1/
  next(node) 'next node'
;

cur(node) = supply(node)>0;

loop(move$card(cur),

    next(node) = f.l(cur,node)>0.5;

    loop(diskMoved(cur,next,disk),
        p1(peg) = nodeval(cur,disk)=ord(peg);
        p2(peg) = nodeval(next,disk)=ord(peg);
        trace(move,cur,next,disk,p1,p2) = yes;
    );

    cur(node) = next(node);  
);

option trace:0:0:1;
display trace;
