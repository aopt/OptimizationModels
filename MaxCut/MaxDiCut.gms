$ontext

   MAX DIRECTED CUT (MAX CUT for directed graphs)

   Use random sparse graphs

   Reference:
   http://yetanothermathprogrammingconsultant.blogspot.com/2022/06/max-cut.html


$offtext

* allow all cores to be used, and look for optimal solution
option threads=0,optcr=0;

*---------------------------------------------------------
* directed graph
*---------------------------------------------------------


set
  i 'nodes' /node1*node70/
  a(i,i) 'arcs'
;
alias (i,j);

* sparse graph
a(i,j) = uniform(0,1)<0.2;

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
    results('|i|',label) = card(i);  \
    results('|a|',label) = card(a);  \
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
* maxcut model 1
*---------------------------------------------------------

binary variables
   x(i) 'node is in set S'
;

variable z 'objective';

equations
   obj1  'Quadratic objective'
;

obj1.. z =e= sum(a(i,j),w(i,j)*x(i)*(1-x(j)));


model maxcut1 /obj1/;
option miqcp=cplex;
solve maxcut1 maximizing z using miqcp;

parameter ecut(i,j) 'maximum cut';
ecut(a(i,j)) = x.l(i)*(1-x.l(j));

option x:0,ecut:0;
display x.l,ecut,z.l;

report(maxcut1,"miqp")

*---------------------------------------------------------
* as maxcut model 2 but prevent automatic linearlization
*---------------------------------------------------------

$onecho > cplex.opt
qtolin 0
$offecho

maxcut1.optfile=1;
solve maxcut1 maximizing z using miqcp;
report(maxcut1,"miqp/nolin")

*---------------------------------------------------------
* maxcut model 2
*---------------------------------------------------------

binary variables e(i,i) 'arc e is part of cut';

equations
   obj2    'linear objective'
   e1(i,j) 'x(i)=0 ==> e(i,j)=0'
   e2(i,j) 'x(j)=1 ==> e(i,j)=0'
;

obj2.. z =e= sum(a,w(a)*e(a));
e1(a(i,j)).. e(i,j)=l=x(i);
e2(a(i,j)).. e(i,j)=l=1-x(j);

model maxcut2 /obj2,e1,e2/;
solve maxcut2 maximizing z using mip;

option e:0;
display x.l,e.l,z.l;

report(maxcut2,"mip")


*---------------------------------------------------------
* as maxcut model 2 but relax e to be continuous
*---------------------------------------------------------


e.prior(a) = +inf;
solve maxcut2 maximizing z using mip;
report(maxcut2,"mip/relax")
e.prior(a) = 1;


*---------------------------------------------------------
* model 3: linearize x(i)*x(j)
*---------------------------------------------------------

equations
   obj3     'alternative linearization'
   e3(i,j)  'x(i)=x(j)=1 ==> e(i,j)=1'
;

obj3.. z =e= sum(a(i,j),w(i,j)*(x(i)-e(i,j)));
e3(a(i,j)).. e(i,j) =g= x(i)+x(j)-1;
model maxcut3 /obj3,e3/;
solve maxcut3 maximizing z using mip;

display x.l,e.l,z.l;

report(maxcut3,"mip2")

