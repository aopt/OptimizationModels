$ontext
Problem from


Suppose we have a weighted complete graph with n vertices. We want to colour
each vertex one of k colours. The cost of any colouring is the sum of the
weights of all edges that connect vertices of the same colour.

For my use case, n will be around 20-50. For k = 2, 3 brute force worked
fine, but I would ideally like a solution for any k. It is also the case
that the graphs I'm dealing with have reasonable sparsity, but again,
I would ideally like to solve the general case.

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
* MIP model
*---------------------------------------------------------------

binary variable y(i,j) 'nodes have the same color';

equations
   objective2    'linearized objective'
   ybound(i,j,c) 'x(i,c)=x(j,c)=1 => y(i,j)=1'
;

objective2..        cost =e= sum(a,w(a)*y(a));
ybound(a(i,j),c)..  y(i,j) =g= x(i,c)+x(j,c)-1;

model color2 /objective2,assign,ybound/;

* optionally relax y to continuous between 0 and 1
y.prior(a) = INF;

solve color2 minimizing cost using mip;


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

