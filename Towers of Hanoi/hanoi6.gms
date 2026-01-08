$onText

   Towers of Hanoi, network formulation

   4 disks, 4 pegs
    
$offText


*-----------------------------------------------------------------------------------
* size of problem
*-----------------------------------------------------------------------------------

$set n 4
$set makeplot 1

*-----------------------------------------------------------------------------------
* nodes
*-----------------------------------------------------------------------------------

$eval nn power(4,%n%)

set
  node /node1*node%nn%/
  disk /disk1*disk%n%/
  peg /pegA,pegB,PegC,PegD/
  nodes(node,disk,peg) / system.powersetRight /
;

scalars
   n  'number of disks' /%n%/
   nn 'number of nodes' /%nn%/
   p  'number of pegs'
;
p = card(peg);

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
scalars
   narcs 'number of directed arcs in Hanoi graph'
   narcs2 'card(arc)'   
;
narcs = p*(p-1)*[power(p,n) - power(p-2,n)]/2;
narcs2 = card(arc);
abort$(narcs<>narcs2) "number of arcs is incorrect",narcs,narcs2;


*----------------------------------------------------------------------
* shortest path model
*----------------------------------------------------------------------

Sets
  initial(disk,peg) 'initial inventory (state)' / (disk1*disk4).pegA /
  final(disk,peg) 'final inventory (state)'     / (disk1*disk4).pegB /
;


Parameters
   supply(node)
   demand(node)  
;
supply(node)$(sum(nodes(node,initial),1) = n) = 1;
demand(node)$(sum(nodes(node,final),1) = n) = 1;

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

*-----------------------------------------------------------------------------------
* Visualization
*-----------------------------------------------------------------------------------

abort.noError$(n>6 or %makeplot%=0) "skipping plot";

$set svg hanoiplots6.html

file fname /%svg%/;
put fname;

put '<style>table,th,td {border-collapse: collapse;}</style>'/;
put '<h2>Towers of Hanoi Extension 2 Network Results</h2>'/;
put 'Number of pegs: ',card(peg):0:0,'<br>'/;
put 'Number of disks: %n% <br>'/;
put 'Number of moves: ',z.l:0:0,'<br>'/;
put 'Network has ',nn:0:0,' nodes and ',narcs:0:0,' arcs<br><br>';

put '<table border="1">'/;
put '<tr>'/;

$eval n2 %n%+2

scalar nd,x,y,w,k /0/;
parameter pegpos(peg) 'x position of pegs';
pegpos(peg) = 3*ord(peg);

cur(node) = supply(node)>0;

loop(move$card(cur),
   if (k=4,
       put "</tr><tr>"/;
       k = 0;
    );
   k = k + 1;

   put '<td style="text-align: center">'/;
   put '<svg height="100" width="300" viewBox="0 0 12 %n2%">'/;
   
   loop(peg,
* draw peg
      put '<line x1="',(pegpos(peg)):0:0,'" y1="1" x2="',(pegpos(peg)):0:0,'" y2="%n2%" style="stroke:brown;stroke-width:0.1"/>'/;
* draw disk
      nd = sum(nodes(cur,disk,peg),1);
      loop(nodes(cur,disk,peg),
         y = n+1-nd+1;
         w = ord(disk)*3/n;
         x = pegpos(peg)-0.5*w;
*         display x,w,y;
         put '<rect x="',x:0:2,'" y="',y:0:2,'" height="1" width="',w:0:2,'" fill="lightblue"/>'/;
         put '<text x="',pegpos(peg):0:2,'" y="',(y+0.6):0:2,'" dominant-baseline="middle" text-anchor="middle" font-size="0.6">',(ord(disk)):0:0,'</text>'/;
         nd = nd-1;
      );
   );
   put '</svg><br>',cur.tl:0/;
   put '</td>'/;
   
   next(node) = f.l(cur,node)>0.5;
   cur(node) = next(node);  

);

put '</tr></table>';
putclose;
executetool 'win32.ShellExecute "%svg%"';