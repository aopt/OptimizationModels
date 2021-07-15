$ontext

   time indexed model M3

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
   t 'time periods' /t1*t100/
   dummy 'for display purposes' /proctime,release,duedate/
;

alias (t,tt),(i,j),(m,mm);

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

parameter objw(objs) /
   completion    0.001
   sumtardy      1
   numtardy      0
   maxtardy      0
   makespan      0
/;


*-----------------------------------------------------------
* Model M1
*-----------------------------------------------------------


binary variable
  x(j,m,t)        'execution of job'
  xstart(j,m,t)   'start of job'
  xend(j,m,t)     'end of job'
;

xstart.prior(j,m,t) = inf;
xend.prior(j,m,t) = inf;


positive variable
   start(j)      'start time of job'
   completion(j) 'completion time of job'
   tardy(j)      'amount a job is tardy'
   obj(objs)     'individual objectives'
   count(m)      'number of jobs on machine'
;

start.lo(j) = release(j);

variable
  z 'overall objective'
;

equations
  eJobLen(j)         'length of each job'
  eStart(j,m,t)      'x(j,m,t) > x(j,m,t-1) => xstart(j,m,t)=1'
  eEnd(j,m,t)        'x(j,m,t) > x(j,m,t+1) => xend((j,m,t)=1'
  eJobStart(j)       'each job must start exactly once'
  eJobEnd(j)         'each job must end exactly once'
  eNoOverlap(m,t)    'only one job on machine m can be executing during t'
  eStartTime(j)      'start time'
  eCompletionTime(j) 'completion time'
  eTardy(j)          'amount job is tardy'
  ePrecedence(i,j)   'precedence constraint'

* objectives
  objCompletion
  objSumTardy
  objMaxTardy(j)
  objNumTardy
  objMakespan(j)
  objective

* extra to reduce symmetry
  ecount(m)
  order(m)
;


eJobLen(j)..
   sum((m,t),x(j,m,t)) =e= proc(j);

* implications
eStart(j,m,t)..
  xstart(j,m,t) =g= x(j,m,t) - x(j,m,t-1);

eEnd(j,m,t)..
  xend(j,m,t) =g= x(j,m,t) - x(j,m,t+1);


*  each job must start and end exactly once
eJobStart(j)..
   sum((m,t), xstart(j,m,t)) =e= 1;

eJobEnd(j)..
   sum((m,t), xend(j,m,t)) =e= 1;


* only one job on machine m can be executing during t
eNoOverlap(m,t)..
   sum(j,x(j,m,t)) =l= 1;

* calculate start time
eStartTime(j)..
   start(j) =e= sum((m,t),ord(t)*xstart(j,m,t));

* calculate completion time
eCompletionTime(j)..
   completion(j) =e= start(j)+proc(j);

* amount a job is tardy
eTardy(j)..
   tardy(j) =g= completion(j) - due(j);

* precedence constraints
ePrecedence(precedence(i,j))..
  completion(i) =l= start(j);

* objectives
objCompletion..
    obj('completion') =e= sum(j,w(j)*completion(j));

objSumTardy..
    obj('sumtardy') =e= sum(j,w(j)*tardy(j));

objNumTardy..
    obj('numtardy') =e= sum((j,m,t)$(ord(t)>=due(j)),xend(j,m,t));

* if objw=0 then value is calculated afterwards
* reason: objective does not drive it down in that case
objMaxTardy(j)$objw('maxtardy')..
    obj('maxtardy') =g= tardy(j);

objMakespan(j)$objw('makespan')..
    obj('makespan') =g= completion(j);

* composite objective
objective.. z =e= sum(objs, objw(objs)*obj(objs));

* extra: order machines by count
ecount(m).. count(m) =e= sum((j,t),xstart(j,m,t));

order(m+1).. count(m) =g= count(m+1);



model sched3 /all/;
option threads=8,optcr=0,reslim=1800;
solve sched3 minimizing z using mip;

* if not calculated in model, do it here
obj.l('maxtardy')$(objw('maxtardy')=0) = smax(j, tardy.l(j));
obj.l('makespan')$(objw('makespan')=0) = smax(j, completion.l(j));

option start:0,obj:0,tardy:0,x:0,xstart:0,xend:0;
display start.l,obj.l,tardy.l,x.l,xstart.l,xend.l;

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

report(sched3,"M3")



