$ontext

   References:

   A scheduling problem: a modeling approach
   https://yetanothermathprogrammingconsultant.blogspot.com/2021/07/a-scheduling-problem-modeling-approach.html

   Scheduling minimization Integer Programming problem formulation
   https://or.stackexchange.com/questions/6606/scheduling-minimization-integer-programming-problem-formulation

$offtext

*---------------------------------------------------------------------------
* populate data set with random data
*---------------------------------------------------------------------------

set
  dummy 'for prettier output' /release,due,proctime/
  j 'jobs' /job1*job60/
  t 'weeks' /week1*week52/
;

parameters
  release(j)    'release date'
  due(j)        'due date'
  proctime(j)   'processing time (weeks)'
  resource(j,t)  'resource usage'
;

proctime(j) = uniformint(1,5);
release(j)$(uniform(0,1)<=0.2) = uniformint(1,30);
due(j)$(uniform(0,1)<=0.3) = min(release(j)+proctime(j)+uniformint(5,25),card(t));
resource(j,t)$(ord(t)<=proctime(j)) = uniformint(1,5);

*---------------------------------------------------------------------------
* display data
*---------------------------------------------------------------------------

parameter data(j,*) 'job data and resource usage';
data(j,'release') = release(j);
data(j,'proctime') = proctime(j);
data(j,'due') = due(j);
data(j,t) = resource(j,t);
option data:0;
display j,t,data;


*---------------------------------------------------------------------------
* re-interpret empty due date
*---------------------------------------------------------------------------

due(j)$(due(j)=0) = card(t)+1;


*---------------------------------------------------------------------------
* reporting macros
*---------------------------------------------------------------------------

acronym TimeLimit, Optimal, Error;

parameter results(*,*) 'compare statistics';
$macro report(m,label)  \
    results('vars',label) = m.numVar; \
    results('  discr',label) = m.numDVar; \
    results('equs',label) = m.numEqu; \
    results('status',label) = Error; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('status',label)$(m.solvestat=3) = TimeLimit; \
    results('obj',label) = m.objval; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd; \
    results('gap%',label)$(m.solvestat=3) = 100*abs(m.objest - m.objval)/abs(m.objest);   \
    display results;



*---------------------------------------------------------------------------
* model 1: formulation without precalculating data
*---------------------------------------------------------------------------

alias(t,tt);

binary variable x(j,t) 'start of job';
variable maxres 'maximum resource usage';

equation
   assign(j)  'a job can be started at one time'
   bound(t)   'maximum of resource usage'
   erelease(j) 'release date constraint'
   edue(j)     'due date constraint'
;

assign(j)..    sum(t, x(j,t)) =e= 1;
bound(tt)..    maxres =g= sum((j,t)$(ord(t)>=ord(tt)-proctime(j)+1 and ord(t)<=ord(tt)),  resource(j,tt-(ord(t)-1))*x(j,t));
erelease(j)..  sum(t, ord(t)*x(j,t)) =g= release(j);
edue(j)..      sum(t, (ord(t)+proctime(j)-1)*x(j,t)) =l= due(j)-1;

model m1 /all/;
option optcr=0,threads=8;
solve m1 minimizing maxres using mip;

option x:0;
display maxres.l,x.l;

report(m1,"model 1")

*---------------------------------------------------------------------------
* precalculate sets/parameters resmap and ok.
*---------------------------------------------------------------------------


parameter resmap(j,t,tt) 'resource mapper';
resmap(j,t,tt)$(ord(t)>=release(j) and ord(t)+proctime(j)<=due(j)) = resource(j,tt-(ord(t)-1));
option resmap:0;
display resmap;


set ok(j,t) 'allowed slots for jobs to start';
ok(j,t) = sum(tt$resmap(j,t,tt),1);
display ok;

*---------------------------------------------------------------------------
* model 2: formulation with precalculating data
*---------------------------------------------------------------------------


positive variable use(t) 'resource usage';

equation
   assign2(j) 'a job can be started at one time'
   usage(tt) 'keep track of resource usage in each period'
   bound2(t)  'maximum of resource usage'
;

assign2(j).. sum(ok(j,t), x(j,t)) =e= 1;
usage(tt).. use(tt) =e= sum((j,t),resmap(j,t,tt)*x(j,t));
bound2(t)..  maxres =g= use(t);

model m2 /all-m1/;
solve m2 minimizing maxres using mip;

option x:0,use:0,maxres:0;
display x.l,use.l,maxres.l;


parameter solution(j,*) 'reporting';
solution(j,'release') = release(j)+1$(release(j)=0);
solution(j,'proctime') = proctime(j);
solution(j,'due') = due(j);
solution(j,'start') = sum(t,ord(t)*x.l(j,t));
solution(j,'finish') = sum(t,(ord(t)+proctime(j)-1)*x.l(j,t));
option solution:0;
display solution;

report(m2,"model 2")




