$ontext

   kmedoids.gms

   K-Medoids clustering as MIP model

   The model below tries both pure k-medoids and a model that adds an
   ordering constraint.

   Cplex is doing rather poorly on this model.

   See:
   http://yetanothermathprogrammingconsultant.blogspot.com/2021/05/clustering-models.html

   erwin@amsterdamoptimization.com



$offtext


*-------------------------------------------------------------------
* data
*-------------------------------------------------------------------


set
  i 'points' /p1*p25/
  c 'coordinates' /x,y/
  k 'clusters'  /cluster1*cluster3/
;

alias (i,j);


* pure random data.
parameter p(i,c) 'points';
p(i,c) = uniform(0,100);
display p;

parameter d(i,j) 'distance matrix between all points';
* we can choose a metric
*d(i,ii) = sum(c, abs(p(i,c)-p(ii,c)));
d(i,j) = sqrt(sum(c, sqr(p(i,c)-p(j,c))));


*-------------------------------------------------------
* reporting macros
*-------------------------------------------------------

acronym TimeLimit;
acronym Optimal;
acronym Error;

parameter results(*,*);
$macro report(m,label)  \
    results('points',label) = card(i); \
    results('clusters',label) = card(k); \
    results('vars',label) = m.numVar; \
    results('  discr',label) = m.numDVar; \
    results('equs',label) = m.numEqu; \
    results('status',label) = Error; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('status',label)$(m.solvestat=3) = TimeLimit; \
    results('obj',label) = z.l; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd; \
    results('gap%',label)$(m.solvestat=3) = 100*abs(m.objest - m.objval)/abs(m.objest);




*-------------------------------------------------------------------
* model
*-------------------------------------------------------------------


binary variables
   x(i,k)    'assignment'
   y(i,k)    'cluster medoid'
   xy(i,j,k) 'x(i,k)*y(j,k)'
;

variable
   z 'objective'
   center(k,c) 'center coordinates'
;

equations
   select1(i)  'assignment'
   select2(k)  'medoid'
   allow(i,k)  'x=0=>y=0: medoid must be point inside cluster'
   ecenter(k,c) 'calc center coordinates (for ordering)'
   order(k)     'optional: ordering'
   nlobj       'nonlinear (quadratic) objective'
   linobj      'linearized objective'
   defxy       'linearization'
;

select1(i).. sum(k, x(i,k)) =e= 1;

select2(k).. sum(i, y(i,k)) =e= 1;

allow(i,k).. y(i,k) =l= x(i,k);

ecenter(k,c).. center(k,c) =e= sum(i,y(i,k)*p(i,c));

order(k+1).. center(k,'x') =l= center(k+1,'x');

nlobj.. z =e= sum((i,j,k), d(i,j)*x(i,k)*y(j,k));

linobj.. z =e= sum((i,j,k), d(i,j)*xy(i,j,k));

defxy(i,j,k)$d(i,j)..
   xy(i,j,k) =g= x(i,k) + y(j,k) - 1;


model quadratic1 /select1,select2,nlobj/;
model quadratic2 /select1,select2,nlobj,ecenter,order/;
model linear1 /select1,select2,linobj,defxy/;
model linear2 /select1,select2,linobj,defxy,ecenter,order/;


option miqcp = cplex, mip = cplex, optcr = 0, threads = 8, reslim = 3600;

* note: cplex will linearize the model under the hood

solve quadratic1 minimizing z using miqcp;
report(quadratic1,"MIQP")
solve quadratic2 minimizing z using miqcp;
report(quadratic2,"MIQP+ord")

solve linear1 minimizing z using mip;
report(linear1,"MIP")
solve linear2 minimizing z using mip;
report(linear2,"MIP+ord")
display results;


