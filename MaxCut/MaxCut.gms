$onText

   MAX CUT (undirected graphs)

   Random graphs

$offtext

* allow all cores to be used
option threads=0;

*---------------------------------------------------------
* undirected graph
*---------------------------------------------------------


set
  i 'nodes' /node1*node70/
  a(i,i) 'arcs'
;
alias (i,j);

* sparse undirected network
a(i,j)$(ord(i)<ord(j)) = uniform(0,1)<0.2;

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
   obj1 'quadratic objective'
;

obj1.. z =e= sum(a(i,j),w(i,j)*sqr(x(i)-x(j)));


model maxcut1 /obj1/;
option miqcp=cplex;
solve maxcut1 maximizing z using miqcp;

parameter ecut(i,j) 'maximum cut';
ecut(a(i,j)) = w(i,j)*sqr(x.l(i)-x.l(j));

option x:0;
display x.l,ecut,z.l;

report(maxcut1,"miqp")

*---------------------------------------------------------
* as maxcut model 1 but prevent automatic linearization
*---------------------------------------------------------

$onecho > cplex.opt
qtolin 0
$offecho

maxcut1.optfile=1;
solve maxcut1 maximizing z using miqcp;
report(maxcut1,"miqp/nolin")


*---------------------------------------------------------
* maxcut model 2:
*---------------------------------------------------------

binary variables
   e(i,i) 'arc e is in cut'
;


equations
   obj2     'linear objective'
   e1(i,j)  'x(i)=x(j)=0 ==> e(i,j)=0'
   e2(i,j)  'x(i)=x(j)=1 ==> e(i,j)=0'
;

obj2.. z =e= sum(a,w(a)*e(a));
e1(a(i,j)).. e(i,j)=l=x(i)+x(j);
e2(a(i,j)).. e(i,j)=l=2-x(i)-x(j);


model maxcut2 /obj2,e1,e2/;
solve maxcut2 maximizing z using mip;

option e:0;
display x.l,e.l,z.l;

report(maxcut2,"mip")

*---------------------------------------------------------
* as model 2 but relax variables e(i,j)
*---------------------------------------------------------

e.prior(a) = +inf;
solve maxcut2 maximizing z using mip;
report(maxcut2,"mip/relax")
e.prior(a) = 1;

*---------------------------------------------------------
* as model 2 but add: number of x(i) <= n/2
*---------------------------------------------------------

equation extra;
extra.. sum(i, x(i)) =l= sum(i, 1-x(i));

model maxcut3 /maxcut2,extra/;
solve maxcut2 maximizing z using mip;

option e:0;
display x.l,e.l,z.l;

report(maxcut2,"mip/extra")
