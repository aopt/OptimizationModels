$ontext

   time indexed model M1

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
   t 'time periods' /t1*t100/
   dummy 'for display purposes' /release,proctime,due,start,completion/
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


set occupy(j,t,tt) 'job (j,t) executes at tt';
occupy(j,t,tt) = ord(tt)>=ord(t) and ord(tt)<ord(t)+proc(j);

set isLate(j,t) 'job j is late if started at t';
isLate(j,t) = ord(t)+proc(j) > due(j);

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
  x(j,m,t)   'start of job'
;

positive variable
   start(j)      'start time of job'
   completion(j) 'completion time of job'
   tardy(j)      'amount a job is tardy'
   obj(objs)     'individual objectives'
   count(m)      'number of jobs on machine m'
;

start.lo(j) = release(j);

variable
  z 'overall objective'
;

equations
  eJobStart(j)       'each job must start exactly once'
  eNoOverlap(m,t)    'only one job on machine m can be executing during t'
  eStartTime(j)      'start time'
  eCompletionTime(j) 'completion time'
  eTardy(j)          'amount job is tardy'
  ePrecedence(i,j)   'precedence constraint'
  eCount(m)          'number of jobs on machine m (optional)'
  eOrder             'ordering of machines (optional)'

* objectives
  objCompletion
  objSumTardy
  objMaxTardy(j)
  objNumTardy
  objMakespan(j)
  objective
;

*  each job must start exactly once
eJobStart(j)..
   sum((m,t), x(j,m,t)) =e= 1;

* only one job on machine m can be executing during t
eNoOverlap(m,t)..
   sum(occupy(j,tt,t), x(j,m,tt)) =l= 1;

* calculate start time
eStartTime(j)..
   start(j) =e= sum((m,t),ord(t)*x(j,m,t));

* calculate completion time
eCompletionTime(j)..
   completion(j) =e= start(j)+proc(j);

* amount a job is tardy
eTardy(j)..
   tardy(j) =g= completion(j) - due(j);

* precedence constraints
ePrecedence(precedence(i,j))..
  completion(i) =l= start(j);


* ordering constraints
* renumber machines so machine with most jobs is first
eCount(m)..
   count(m) =e= sum((j,t),x(j,m,t));

eOrder(m+1)..
   count(m) =g= count(m+1);


* objectives
objCompletion..
    obj('completion') =e= sum(j,w(j)*completion(j));

objSumTardy..
    obj('sumtardy') =e= sum(j,w(j)*tardy(j));

objNumTardy..
    obj('numtardy') =e= sum((m,isLate(j,t)),x(j,m,t));

* if objw=0 then value is calculated afterwards
* reason: objective does not drive it down in that case
objMaxTardy(j)$objw('maxtardy')..
    obj('maxtardy') =g= tardy(j);

objMakespan(j)$objw('makespan')..
    obj('makespan') =g= completion(j);


* composite objective
objective.. z =e= sum(objs, objw(objs)*obj(objs));


*-----------------------------------------------------------
* solve model
*-----------------------------------------------------------

model sched1 /all/;
option threads=8,optcr=0,reslim=1800;
solve sched1 minimizing z using mip;

* if not calculated in model, do it here
obj.l('maxtardy')$(objw('maxtardy')=0) = smax(j, tardy.l(j));
obj.l('makespan')$(objw('makespan')=0) = smax(j, completion.l(j));

option start:0,obj:0,tardy:0,x:0:0:4;
display start.l,obj.l,tardy.l,x.l;


*-----------------------------------------------------------
* reporting
* prepare data for plotting
*-----------------------------------------------------------


alias(*,attr);

set assign(j,m);
assign(j,m) = sum(t$(x.l(j,m,t)>0.5),1);

parameter
  jobSchedule(j,t)
  machineSchedule(m,t)
  plot(j,m,attr)
;
loop((j,m,t)$(x.l(j,m,t)>0.5),
   jobSchedule(j,tt)$occupy(j,t,tt) =
      ord(m)$(ord(tt)<=due(j)) - ord(m)$(ord(tt)>due(j));
   machineSchedule(m,tt)$occupy(j,t,tt) =
      ord(j)$(ord(tt)<=due(j)) - ord(j)$(ord(tt)>due(j));
);
plot(assign(j,m),'release') = release(j);
plot(assign(j,m),'proctime') = jobdata(j,'proctime');
plot(assign(j,m),'due') = due(j);
plot(assign(j,m),'completion') = completion.l(j);
plot(assign(j,m),'start') = start.l(j);

display plot;

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

report(sched1,"M1")
