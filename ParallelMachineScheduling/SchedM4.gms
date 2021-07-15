$ontext

   Continuous time formulation M4

   This is not a very good formulation.

   due date, release date and completion time are measured
   at beginning of period t

   References:

      Yasin Unlu, Scott J. Mason,
      Evaluation of mixed integer programming formulations for
      non-preemptive parallel machine scheduling problems,
      Computers & Industrial Engineering 58 (2010) 785–800.

      Parallel machine scheduling II, three more formulations
      https://yetanothermathprogrammingconsultant.blogspot.com/2021/04/parallel-machine-scheduling-i-three.html


$offtext

*-----------------------------------------------------------
* basic data
*-----------------------------------------------------------

set
   j 'jobs' /job1*job50/
   m 'machines' /machine1*machine4/
   dummy 'for display purposes' /proctime,release,duedate/
;

alias (i,j,k),(m,mm);

parameter jobdata(j,*);
jobdata(j,'proctime') = uniformInt(3,10);
jobdata(j,'duedate') = uniformInt(10,100);
jobdata(j,'release')$(uniform(0,1)<0.5) = max(0, jobdata(j,'duedate') - jobdata(j,'proctime') - uniformInt(5,15));
jobdata(j,'weights') = 1;
option jobdata:0;
display jobdata;

set precedence(i,j) 'precedence constraints: i must execute before j';
precedence(i,j)$(ord(i)<ord(j) and ord(j) <= ord(i)+5 and uniform(0,1)<0.05) = yes;
display precedence;


*-----------------------------------------------------------
* derived data
*-----------------------------------------------------------

parameter
   proc(j)
   due(j)
   release(j)
   w(j)
;
proc(j) = jobdata(j,'proctime');
due(j) = jobdata(j,'duedate');
release(j) = jobdata(j,'release');
w(j) = jobdata(j,'weights');


set ij(i,j) 'i<j';
ij(i,j) = ord(i)<ord(j);

*-----------------------------------------------------------
* different objectives
*-----------------------------------------------------------

set objs /
   completion    'weighted sum of completion dates'
   sumtardy      'weighted sum of tardiness'
   maxtardy      'max tardiness'
   numtardy      'num tardy jobs'
   makespan      'completion time of last job'
/;

parameter objw(objs) 'objective weights' /
   completion    0.001
   sumtardy      1
   numtardy      0
   maxtardy      0
   makespan      0
/;

display objw;

scalar T /100/;

*-----------------------------------------------------------
* Model M4
*-----------------------------------------------------------

binary variable
  x(j,m)        'assign job to machine'
  delta(i,j)    'i is executed before j'
  d(i,j)        'jobs i and j are *NOT* the same machine'
  isTardy(j)    'job j is tardy'
;

d.prior(ij) = inf;

positive variable
   start(j)        'start of job'
   completion(j)   'completion of job'
   tardy(j)        'amount job is tardy'
   obj(objs)       'objectives'
   count(m)        'number of jobs assigned to machine m'
;

variable z        'total objective';

equations
  jobOrdering(i,j)     'jobs i,j on same machine should not overlap'
  transitivity(i,j,k)  'transitivty constraint'
  assign(j)            'assign each job to a machine'
  sameMachine(i,j,m)   'x(i,m)=x(j,m)=1 => s(i,j)=1'
  startEnd(j)          'relate start and completion'
  jobAfter(i,j)        'job j starts after job i finishes'

  etardy(j)            'tardiness'
  jobIsTardy(j)
  ePrecedence          'preceddence constraints'

* objectives
  objCompletion
  objSumTardy
  objMaxTardy(j)
  objNumTardy
  objMakespan(j)
  objective

* extra: ordering constraint
  eCount
  eOrder
;


jobOrdering(ij(i,j))..
   delta(i,j) + delta(j,i) + d(i,j) =e= 1;

transitivity(i,j,k)$(ij(i,j) and ij(j,k))..
   delta(i,j) + delta(i,k) + delta(k,i) =l= 2;

assign(j)..
   sum(m,x(j,m)) =e= 1;

sameMachine(ij(i,j),m)..
   x(i,m) + x(j,m) + d(i,j) =l= 2;


* start at time t=1
start.lo(j) = max(1,release(j));

startEnd(j)..
   completion(j) =e= start(j) + proc(j);

jobAfter(i,j)..
   start(j) =g= completion(i) - T*(1-delta(i,j));

* tardiness
etardy(j)..
  tardy(j) =g= completion(j) - due(j);

jobIsTardy(j)..
   tardy(j) =l= isTardy(j)*T;

* precedence constraints
ePrecedence(precedence(i,j))..
  completion(i) =l= start(j);

* start at time t=1
start.lo(j) = max(1,release(j));


* objectives
objCompletion..
    obj('completion') =e= sum(j,w(j)*completion(j));

objSumTardy..
    obj('sumtardy') =e= sum(j,w(j)*tardy(j));

objNumTardy..
    obj('numtardy') =e= sum(j,isTardy(j));

* if objw=0 then value is calculated afterwards
* reason: objective does not drive it down in that case
objMaxTardy(j)$objw('maxtardy')..
    obj('maxtardy') =g= tardy(j);

objMakespan(j)$objw('makespan')..
    obj('makespan') =g= completion(j);

* composite objective
objective.. z =e= sum(objs, objw(objs)*obj(objs));

eCount(m)..
   count(m) =e= sum(j,x(j,m));

eOrder(m+1)..
   count(m) =g= count(m+1);


model sched4 /all/;
option threads=8,optcr=0,reslim=1800;
solve sched4 minimizing z using mip;


* if not calculated in model, do it here
obj.l('maxtardy')$(objw('maxtardy')=0) = smax(j, tardy.l(j));
obj.l('numtardy')$(objw('numtardy')=0) = sum(j$(tardy.l(j)>0.001),1);
obj.l('makespan')$(objw('makespan')=0) = smax(j, completion.l(j));

option start:0,obj:0,tardy:0;
display start.l,obj.l,tardy.l;


*-----------------------------------------------------------
* reporting
* summary of performance
*-----------------------------------------------------------

acronym TimeLimit;
acronym Optimal;
acronym Error;

parameter results(*,*);
$macro report(m,label)  \
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
    results('gap%',label)$(m.solvestat=3) = 100*abs(m.objest - m.objval)/abs(m.objest); \
    display results;

report(sched4,"M4")

