$ontext

  Standard Graph Coloring Model

  References:
      http://math.ucdenver.edu/~sborgwardt/wiki/index.php/An_Integer_Linear_Programming_Approach_to_Graph_Coloring

$offtext

*
* random graph
*
set
   v 'vertices' /n1*n20/
   e(v,v) 'edges'
   c 'colors' /orange,lightblue,yellow,green,chocolate,grey/
;

alias(v,i,j);
e(i,j)$(ord(i)<ord(j)) = uniform(0,1)<0.2;

*
* model
*
binary variables
    x(v,c) 'assign color to node'
    w(c)   'color is used'
;

variable
    numColors 'number of colors needed'
;

equations
    objective         'minimize number of colors used'
    assign(v)         'every node should have exactly one color'
    sameColor(i,j,c)  'adjacent vertices cannot have the same color'
;

objective..  numColors =e= sum(c, w(c));
assign(v)..  sum(c, x(v,c)) =e= 1;
sameColor(e(i,j),c).. x(i,c)+x(j,c) =l= w(c);

model color /all/;
option optcr=0;
solve color minimizing numColors using mip;


display x.l,w.l,numColors.l;


*-----------------------------------------------------------
* visualization using GraphViz
*-----------------------------------------------------------

file gv1 /graph1.gv/;
put gv1;
put "graph neato{"/;
loop(c$(w.l(c)>0.5),
   put "node [shape=circle,style=filled,color=",c.tl:0,"] ";
   loop(v$(x.l(v,c)>0.5), put v.tl:0," ");
   put/;
);

put "edge [color=black]"/;
loop(e(i,j), put i.tl:0,"--",j.tl:0/;);
putclose"}"/;



