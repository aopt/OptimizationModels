$ontext

   MAX CUT (undirected graphs)

   Use random sparse graphs

   Reference:
   http://yetanothermathprogrammingconsultant.blogspot.com/2022/06/max-cut.html

$offtext

* allow all cores to be used, and look for optimal solution
option threads=0,optcr=0;

*---------------------------------------------------------
*  undirected graph
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
* maxcut model 1: unconstrained MIQP
* may be linearized by Cplex
*---------------------------------------------------------

binary variables
   x(i) '1: node is in S, 0: node is not in S'
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

binary variables e(i,i) 'arc e has one node in S and one not in S';

equations
   obj2     'linear objective'
   e1(i,j)  'implication: x(i)=x(j)=0 ==> e(i,j)=0'
   e2(i,j)  'implication: x(i)=x(j)=1 ==> e(i,j)=0'
;

obj2.. z =e= sum(a,w(a)*e(a));
e1(a(i,j)).. e(i,j) =l= x(i)+x(j);
e2(a(i,j)).. e(i,j) =l= 2-x(i)-x(j);


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
* as model 2 but add: sum(x) <= floor(n/2)
* same as sum(x)<=sum(1-x)
*---------------------------------------------------------

equation extra;
extra.. sum(i, x(i)) =l= sum(i, 1-x(i));
* extra.. sum(i,x(i)) =l= floor(card(i)/2);

model maxcut2e /maxcut2,extra/;
solve maxcut2e maximizing z using mip;

report(maxcut2e,"mip/extra")

*---------------------------------------------------------
* as model 2 but fix node1 to 1
*---------------------------------------------------------

x.fx('node1') = 1;
solve maxcut2 maximizing z using mip;
display x.l,e.l,z.l;

report(maxcut2,"mip/fix")

* to unfix do:
*x.lo('node1') = 0;
*x.up('node1') = 1;
* let's keep it fixed

*---------------------------------------------------------
* model 3: different quadratic formulation
*---------------------------------------------------------

equations
   obj3 'model 3 quadratic objective'
;

obj3.. z =e= sum(a(i,j),w(i,j)*(x(i)+x(j)-2*x(i)*x(j)));

model maxcut3 /obj3/;
solve maxcut3 maximizing z using miqcp;

display x.l,z.l;

report(maxcut3,"miqp2/fix")


*---------------------------------------------------------
* model 4: linearization of model 3
*---------------------------------------------------------

equations
   obj4 'linearization of obj3'
   e4(i,j) 'x(i)=x(j)=1 => e(i,j)=1'
;

obj4.. z =e= sum(a(i,j),w(i,j)*(x(i)+x(j)-2*e(i,j)));
e4(a(i,j)).. e(i,j) =g= x(i)+x(j)-1;

model maxcut4 /obj4,e4/;
solve maxcut4 maximizing z using mip;

ecut(a(i,j)) = w(i,j)*sqr(x.l(i)-x.l(j));

display x.l,e.l,z.l;

report(maxcut4,"mip2/fix")

