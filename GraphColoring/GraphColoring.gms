$ontext

  Standard Graph Coloring Model

  References:
      http://math.ucdenver.edu/~sborgwardt/wiki/index.php/An_Integer_Linear_Programming_Approach_to_Graph_Coloring

$offtext

*---------------------------------------------------------------
* random graph
*
* sparse undirected network:
* arcs only from i->j when i<j
*---------------------------------------------------------------

set
   n 'nodes' /n1*n20/
   a(n,n) 'arcs'
   c 'colors' /orange,lightblue,yellow,green,chocolate,grey/
;

alias(n,i,j);

a(i,j)$(ord(i)<ord(j)) = uniform(0,1)<0.2;

*---------------------------------------------------------------
* model
*---------------------------------------------------------------

binary variables
   x(n,c) 'assign color to node'
   u(c)   'color is used'
;

variable
   numColors 'number of colors needed'
;

equations
   objective            'minimize number of colors used'
   assign(n)            'every node should have exactly one color'
   notSameColor(i,j,c)  'adjacent vertices cannot have the same color'
   order(c)             'ordering constraint (optional)'
;

objective..  numColors =e= sum(c, u(c));

assign(n)..  sum(c, x(n,c)) =e= 1;

notSameColor(a(i,j),c).. x(i,c)+x(j,c) =l= u(c);

order(c-1).. u(c) =l= u(c-1);

model color /all/;
option optcr=0;
solve color minimizing numColors using mip;


display x.l,u.l,numColors.l;


*-----------------------------------------------------------
* visualization using GraphViz
*-----------------------------------------------------------

file gv1 /graph1.gv/;
put gv1;
put "graph neato{"/;
loop(c$(u.l(c)>0.5),
   put "node [shape=circle,style=filled,color=",c.tl:0,"] ";
   loop(n$(x.l(n,c)>0.5), put n.tl:0," ");
   put/;
);

put "edge [color=black]"/;
loop(a(i,j), put i.tl:0,"--",j.tl:0/;);
putclose"}"/;



