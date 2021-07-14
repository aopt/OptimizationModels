$ontext

   Continuous time formulation M2

   due date, release date and completion time are measured
   at beginning of period t

   References:

      Yasin Unlu, Scott J. Mason,
      Evaluation of mixed integer programming formulations for
      non-preemptive parallel machine scheduling problems,
      Computers & Industrial Engineering 58 (2010) 785–800.

      Parallel machine scheduling I, two formulations
      https://yetanothermathprogrammingconsultant.blogspot.com/2021/03/parallel-machine-scheduling-i-two.html



$offtext

*-----------------------------------------------------------
* basic data
*-----------------------------------------------------------

set
   j 'jobs' /job1*job50/
   m 'machines' /machine1*machine4/
   dummy 'for display purposes' /proctime,release,duedate/
;

alias (i,j),(m,mm);

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

scalar T /100/;

*-----------------------------------------------------------
* Model M2
*-----------------------------------------------------------

binary variable
  x(j,m)        'assign job to machine'
  delta(i,j)    'i is execute before j (if on same machine)'
  isTardy(j)    'job j is tardy'
;

positive variable
   start(j)        'start of job'
   completion(j)   'completion of job'
   tardy(j)        'amount job is tardy'
   obj(objs)       'objectives'
;

variable z        'total objective';

equations
  startEnd(j)        'relate start and completion'
  NoOverlap1(i,j,m)  'no-overlap big-M constraint'
  NoOverlap2(i,j,m)  'no-overlap big-M constraint'
  assign(j)          'assign each jon to a machine'
  etardy(j)          'tardiness'
  jobIsTardy(j)      'boolean:isTardy'
  ePrecedence        'precedence constraints'

* objectives
  objCompletion
  objSumTardy
  objMaxTardy(j)
  objNumTardy
  objMakespan(j)
  objective          'composite objective'
;

assign(j)..
   sum(m,x(j,m)) =e= 1;

startEnd(j)..
   completion(j) =e= start(j) + proc(j);

NoOverlap1(i,j,m)$(ord(i)<ord(j))..
   completion(i) =l= start(j) + T*(1-x(i,m)) + T*(1-x(j,m)) + T*delta(i,j);

NoOverlap2(i,j,m)$(ord(i)<ord(j))..
   completion(j) =l= start(i) + T*(1-x(i,m)) + T*(1-x(j,m)) + T*(1-delta(i,j));

etardy(j)..
  tardy(j) =g= completion(j) - due(j);

jobIsTardy(j)..
   tardy(j) =l= isTardy(j)*T;

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

model sched2 /all/;
option threads=8,optcr=0,reslim=1000;
solve sched2 minimizing z using mip;


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

report(sched2,"M2")


