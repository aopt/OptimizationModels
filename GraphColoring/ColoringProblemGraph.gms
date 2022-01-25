$ontext

   Produce picture of graph after coloring

$offtext


*---------------------------------------------------------------
* random graph
*
* sparse undirected network:
* arcs only from i->j when i<j
*---------------------------------------------------------------

set
   n 'nodes' /n1*n10/
   a(n,n) 'arcs'
   c 'colors' /orange,lightblue,brown/
;

alias(n,i,j);

a(i,j)$(ord(i)<ord(j)) = yes;

parameter w(n,n) 'weights';
w(a) = uniform(0,1);
display w;


*---------------------------------------------------------------
* MIQP model
*---------------------------------------------------------------

binary variables
   x(n,c) 'assign color to node'
;

variable
   cost 'number of arcs with same colored nodes'
;

equations
   objective            'minimize cost'
   assign(n)            'every node should have exactly one color'
;

objective..  cost =e= sum((a(i,j),c),w(a)*x(i,c)*x(j,c));

assign(n)..  sum(c, x(n,c)) =e= 1;

model color1 /all/;
option optcr=0, miqcp=cplex, threads=16;
solve color1 minimizing cost using miqcp;


*---------------------------------------------------------------
* reporting
*---------------------------------------------------------------

display x.l,cost.l;


parameter wx 'obj contribution';
wx(a(i,j)) = w(a)*sum(c,x.l(i,c)*x.l(j,c));
display wx;

*-----------------------------------------------------------
* visualization using GraphViz
*-----------------------------------------------------------


file gv2 /graph2.gv/;
put gv2;
put "graph neato{"/;
loop((n,c)$(x.l(n,c)>0.5),
   put "node [shape=circle,style=filled,color=",c.tl:0,"] ",n.tl:0/;
);


parameter ncol(n);
ncol(n) = sum(c, ord(c)*round(x.l(n,c)));

loop(a(i,j),
   if (ncol(i)=ncol(j),
       loop(c$(x.l(i,c)>0.5),
       put "edge [color=",c.tl:0,",penwidth=4] ",i.tl:0,"--",j.tl:0/;
       );
   else
      put "edge [color=grey,penwidth=1] ",i.tl:0,"--",j.tl:0/;
   )
);

putclose"}"/;

