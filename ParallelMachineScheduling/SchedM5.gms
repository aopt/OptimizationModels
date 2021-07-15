$ontext

   Positional formulation M5

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
   p 'positions' /position1*position20/
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
* Model M1
*-----------------------------------------------------------

binary variable
  x(j,m,p)      'position on machine'
  isTardy(j)    'job j is tardy'
;

positive variable
   start(j)        'start of job'
   completion(j)   'completion of job'
   tardy(j)        'amount job is tardy'
   obj(objs)       'objectives'
   count(m)        'number of jobs assigned to machine m'
   f(m,p)          'finish time'
   nj(m,p)
   complx(j,m,p)   'completion time f(m,p)*x(j,m,p)'
;

variable z        'total objective';

equations
  startEnd(j)        'relate start and completion'
  assign1(j)         'assign each job to a machine/position'
  assign2(m,p)       'assign each job to a machine/position'
  etardy(j)          'tardiness'
  jobIsTardy(j)
  objective
  ePrecedence
  finish(m,p)
  orderp
  compl1
  compl2
  compl3
  compl4

* objectives
  objCompletion
  objSumTardy
  objMaxTardy(j)
  objNumTardy
  objMakespan(j)

* extra
  eCount
  eOrder
;

assign1(j)..
   sum((m,p),x(j,m,p)) =e= 1;

assign2(m,p)..
   nj(m,p) =e= sum(j,x(j,m,p));
nj.up(m,p) = 1;

finish(m,p)..
   f(m,p) =g= f(m,p-1) + sum(j,x(j,m,p)*proc(j));

orderp(m,p+1)..
   nj(m,p+1) =l= nj(m,p);

compl1(j,m,p)..
   complx(j,m,p) =l= T*x(j,m,p);

compl2(j,m,p)..
   complx(j,m,p) =l= f(m,p);

compl3(j,m,p)..
   complx(j,m,p) =g= f(m,p) - T*(1-x(j,m,p));

compl4(j)..
   completion(j) =e= sum((m,p),complx(j,m,p));

startEnd(j)..
   completion(j) =e= start(j) + proc(j);

etardy(j)..
  tardy(j) =g= completion(j) - due(j);

jobIsTardy(j)..
   tardy(j) =l= isTardy(j)*T;

* precedence constraints
ePrecedence(precedence(i,j))..
  completion(i) =l= start(j);

eCount(m)..
   count(m) =e= sum((j,p),x(j,m,p));

eOrder(m+1)..
   count(m) =g= count(m+1);


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


model sched5 /all/;
option threads=8,optcr=0,reslim=1800;
solve sched5 minimizing z using mip;


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

report(sched5,"M5")


