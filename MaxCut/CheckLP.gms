

*---------------------------------------------------------
* undirected graph
*---------------------------------------------------------


set
  i 'nodes' /node1*node10/
  a(i,i) 'arcs'
;
alias (i,j);

* sparse undirected network
a(i,j)$(ord(i)<ord(j)) = uniform(0,1)<0.25;

parameter w(i,j) 'weights';
w(a) = uniform(0,1);

display$(card(i)<=50) i,a,w;



*------------------------------------------------------------------
* reporting macros
*------------------------------------------------------------------

parameter results(*,*);

acronym Optimal;

* macros for reporting
$macro report(m,label)  \
    results('|i|',label) = card(i); \
    results('|a|',label) = card(a); \
    results('variables',label)  = m.numvar;  \
    results(' discrete',label)  = m.numdvar;  \
    results('equations',label)  = m.numequ;  \
    results('status',label)= m.solvestat; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('obj',label) = z.l; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd; \
    display results;


*---------------------------------------------------------
* maxcut model 1: MIQP
*---------------------------------------------------------

binary variables
   x(i) 'node is in S'
;

variable z 'objective';

equations
   obj1
   obj2
;

obj1.. z =e= sum(a(i,j),w(i,j)*sqr(x(i)-x(j)));
obj2.. z =e= sum(a(i,j),w(i,j)*(x(i)+x(j)-2*x(i)*x(j)));

x.fx('node1')=1;

model maxcut1 /obj1/;
model maxcut2 /obj2/;
option miqcp=cplex,threads=0,optcr=0;
maxcut1.optfile=1;
maxcut2.optfile=2;
solve maxcut1 maximizing z using miqcp;
report(maxcut1,"miqp (1)")
solve maxcut2 maximizing z using miqcp;
report(maxcut2,"miqp (2)")

* optimal obj should be 536

$onecho > cplex.opt
writelp x1.lp
qtolin 0
$offecho

$onecho > cplex.op2
writelp x2.lp
qtolin 0
$offecho
