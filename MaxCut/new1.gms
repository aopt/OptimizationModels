

$onecho > translate.awk
{
  if (NR==1) {
     print "set i /node1*node" $1 "/;"
     print "parameter w(i,i) /"
     next
  }

  n1 = $1
  n2 = $2
  w = $3

  print "node" n1 "." "node" n2 " " w

}

END { print "/;"}
$offecho

$call awk -f translate.awk g05_100.0 > g05_100.inc



set i;
parameter w(i,i);
$include g05_100.inc

alias(i,j)
set a(i,j) 'arcs';
a(i,j) = w(i,j);

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
maxcut2.optfile=1;
solve maxcut1 maximizing z using miqcp;
report(maxcut1,"miqp (1)")
solve maxcut2 maximizing z using miqcp;
report(maxcut2,"miqp (2)")

* optimal obj should be 1430
$onecho > cplex.opt
qtolin 0
$offecho
