$ontext

   kmeans.gms

   K-means clustering as MIQCP model

   The model below tries both pure k-means and a model that adds an
   ordering constraint.

   See:
   http://yetanothermathprogrammingconsultant.blogspot.com/2021/05/clustering-models.html

   erwin@amsterdamoptimization.com


$offtext

set
  i 'points' /p1*p40/
  c 'coordinates' /x,y/
  k 'clusters'  /cluster1*cluster3/
;

alias (i,j);


* pure random data.
parameter p(i,c) 'points';
p(i,c) = uniform(0,100);
display p;



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

*-------------------------------------------------------
* model: min ||x-mu(i)||^2 for x in cluster i  (k-means)
*-------------------------------------------------------

scalar M 'big-M';
M = smax((i,j),sum(c, sqr(p(i,c)-p(j,c))));

binary variables
   x(i,k) 'assignment'
;

positive variables
   d(i,k) 'distance from centroid of nearest cluster (or zero)'
;

variables
   mu(k,c) 'cluster locations'
   z       'objective'
;
* cluster center is inside convex hull of points
* so for sure inside box formed by points
mu.lo(k,c) = smin(i,p(i,c));
mu.up(k,c) = smax(i,p(i,c));


equations
   edist(i,k) '(squared) distance calculation'
   select(i)  'assign points to clusters'
   obj        'objective'
   order      'optional symmetry breaker'
;

edist(i,k).. d(i,k) =g= sum(c, sqr(p(i,c)-mu(k,c))) - M*(1-x(i,k));

select(i).. sum(k, x(i,k)) =e= 1;

obj.. z =e= sum((i,k), d(i,k));

* order clusters by their x coordinate
order(k+1).. mu(k,'x') =l= mu(k+1,'x');

* compare model with/without ordering constraint
model kmeans  /edist,select,obj/;
model kmeans2 /edist,select,obj,order/;
option miqcp = cplex, optcr = 0, threads = 8, reslim = 3600;


solve kmeans minimizing z using miqcp;
report(kmeans,"standard")

solve kmeans2 minimizing z using miqcp;
report(kmeans2,"with order")
display results;

parameter clusters(*,*);
clusters(k,'points') = sum(i, x.l(i,k));
clusters('total','points') = card(i);
clusters(k,'SoS') = sum((i,c), sqr(p(i,c)-mu.l(k,c))*x.l(i,k));
clusters('total','SoS') = z.l;
clusters(k,'mu(x)') = mu.l(k,'x');
clusters(k,'mu(y)') = mu.l(k,'y');
clusters(k,'avg(x)') = sum(i$(x.l(i,k)>0.5), p(i,'x'))/sum(i, x.l(i,k));
clusters(k,'avg(y)') = sum(i$(x.l(i,k)>0.5), p(i,'y'))/sum(i, x.l(i,k));
display clusters;





