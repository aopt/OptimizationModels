$ontext

  A variant of an assignment problem.

  References:
     https://stackoverflow.com/questions/68482524/assignment-problem-with-2-workers-per-job
     https://yetanothermathprogrammingconsultant.blogspot.com/2021/07/a-variant-of-assignment-problem.html


  We can assign to each job j:
      an individual worker (either type A or type B worker)
      a team consisting of a typpe A worker and a type B worker
  A worker (either individually or as part of a team) can only be assigned to a single job.

  erwin@amsterdamoptimization.com    

$offtext




*------------------------------------------------------------------
* basic data
*------------------------------------------------------------------

set
    i 'workers+teams' /a1*a10, b1*b10, team1*team100/
    w(i) 'workers' /a1*a10,b1*b10/
    a(w) 'type-A workers' /a1*a10/
    b(w) 'type-B workers' /b1*b10/
    t(i)  'teams' /team1*team100/
    team(t,w) 'composition of teams'
    j 'jobs' /job1*job15/
;

display i,w,a,b,t,j;

*------------------------------------------------------------------
* enumerate possible teams
*------------------------------------------------------------------

set t1(t) /team1/;
loop((a,b),
   team(t1,a) = yes;
   team(t1,b) = yes;
* next element:
   t1(t) = t1(t-1);
);
option team:0:0:8;
display team;



*------------------------------------------------------------------
* random cost coefficients
*------------------------------------------------------------------

parameter c(i,j) 'cost coefficients';
c(i,j) = uniform(0,100);
display c;


*------------------------------------------------------------------
* reporting macros
*------------------------------------------------------------------

acronym TimeLimit, Optimal, Error;
acronym MIP,RMIP;

parameter results(*,*) 'compare statistics';
$macro report(m,label,modeltype)  \
    results('type',label) = modeltype; \
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
    results('gap%',label)$(m.solvestat=3) = 100*abs(m.objest - m.objval)/abs(m.objest);   \
    display results;


*------------------------------------------------------------------
* assignment problem (don't use teams)
* model uses w instead of i
*------------------------------------------------------------------

binary variable x(i,j) 'assignment';
variable z 'total cost';

equations
   obj1          'assignment objective'
   assign1a(w)   'assignment constraint'
   assign1b(j)   'assignment constraint'
;

obj1..        z =e= sum((w,j),c(w,j)*x(w,j));
assign1a(w)..  sum(j, x(w,j)) =l= 1;
assign1b(j)..  sum(w ,x(w,j)) =e= 1;

model assign1 /all/;

* solve as RMIP: automatically integer
solve assign1 minimizing z using rmip;

option x:0;
display x.l,z.l;

report(assign1,'assign',RMIP)

*------------------------------------------------------------------
* assignment problem with side constraint
* assignment constraints now use i
*------------------------------------------------------------------

equations
   obj2         'assignment objective'
   assign2a(i)   'assignment constraint'
   assign2b(j)   'assignment constraint'
   side(w)      'side-constraint'
;

obj2..         z =e= sum((i,j),c(i,j)*x(i,j));
assign2a(i)..  sum(j, x(i,j)) =l= 1;
assign2b(j)..  sum(i ,x(i,j)) =e= 1;
side(w)..      sum(j, x(w,j) + sum(team(t,w),x(t,j))) =l= 1;


option optcr=0,threads=8;

model assign2 /all-assign1/;
solve assign2 minimizing z using mip;

display x.l,z.l;

report(assign2,'sidecon',MIP)


*------------------------------------------------------------------
* drop first assignment constraint
*------------------------------------------------------------------

model assign3 /assign2-assign2a/;
solve assign3 minimizing z using mip;

display x.l,z.l;

report(assign3,'final',MIP)

*------------------------------------------------------------------
* solution report with team composition
*------------------------------------------------------------------

set sol(*,w,j) 'alternative solution report';
sol(team(t,w),j)$(x.l(t,j)>0.5) = yes;
sol('-',w,j)$(x.l(w,j)>0.5) = yes;
display sol;


