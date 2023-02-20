$ontext

    Assign jobs to machines so that the schedule has no overlapping
    jobs on the same machine.
    
    Start and completion times of jobs are given.
    
    The goal is to minimize the number of machines we need.
    

    Reference:
       http://yetanothermathprogrammingconsultant.blogspot.com/2023/02/assigning-jobs-to-machines-without.html

$offtext


*-----------------------------------------------------------------
* size of the problem
*-----------------------------------------------------------------

Set
  d 'days' /day1*day7/
  j 'jobs' /job1*job50/
  m 'machines' /machine1*machine30/
  jd(j,d) 'jobs need to run on certain days'
;

*-----------------------------------------------------------------
* random data
*-----------------------------------------------------------------

Parameters
   start(j) 'start time (minutes since midnight)'
   end(j)   'finish time (minutes since midnight)'
   length(j) 'length of job (minutes)'
;


* times are in minutes sice start of day (0:00)
* minutes per day : 1440
start(j) = uniformint(0,1200);
length(j) = uniformint(2*60,15*60);
end(j) = start(j) + length(j);

jd(j,d) = uniform(0,1)<0.25;

* some jobs have no days. Give them one
scalar day;
loop(j$(sum(jd(j,d),0) = 0),
   day = uniformint(1,7);
   jd(j,d)$(ord(d)=day) = yes;
);


parameter counts(*) 'jobs and individual subjob counts';
* calculate number of jobs from jd (this is an extra check
* we correctly generated the random data)
counts('jobs') = sum(j$sum(jd(j,d),1),1);
counts('subjobs') = card(jd);

abort$(counts('jobs')<>card(j)) "Job count mismatch",j,counts;


option start:0,end:0,length:0,counts:0;
display start,end,length,jd,counts;

*-----------------------------------------------------------------
* map to subjobs
*-----------------------------------------------------------------

set
   k0 'subjobs superset' /subjob1*subjob10000/
   k(k0) 'subjobs in problem'
   map(j,d,k0) 'mapping between jobs/days and subjobs'
;
singleton set kcur(k0) /subjob1/;

abort$(card(k0)<counts('subjobs')) 'increase size of set k0';

loop(jd,
   k(kcur) = yes;
   map(jd,kcur) = yes;
   kcur(k0) = kcur(k0-1);
);
option map:0:0:8;
display map;


*-----------------------------------------------------------------
* timings in minutes since start of week
*-----------------------------------------------------------------

parameters
   start2(k0) 'start time of subjob (minutes since start of week)'
   end2(k0)   'end time of subjob (minutes since start of week)'
;
loop(map(j,d,k),
   start2(k) = start(j)+1440*(ord(d)-1);
   end2(k) = end(j)+1440*(ord(d)-1);
);

option start2:0,end2:0;
display start2,end2;


*-----------------------------------------------------------------
* which jobs overlap
* we only want to compare jobs (k,kk) with k<kk
* this is to prevent double counting resulting in too many
* constraints in the model
*-----------------------------------------------------------------

alias(k,kk);

* we can't do ord on a dynamic set, so we create ordk(k) 
parameter ordk(k0) 'subjob number';
ordk(k0) = ord(k0);

sets
 noOverlap(k0,k0)  'jobs (k<kk) without overlap'
 Overlap(k0,k0)    'jobs (k<kk) with overlap'
;
noOverlap(k,kk)$(ordk(k)<ordk(kk)) = start2(k) > end2(kk) or start2(kk) > end2(k);
overlap(k,kk)$(ordk(k)<ordk(kk)) = not noOverlap(k,kk);

option overlap:0:0:8;
display overlap;

scalar numOverlap 'number of overlapping subjobs';
numOverlap = card(Overlap);
option NumOverlap:0;
display numOverlap;

*-----------------------------------------------------------------
* Model
*-----------------------------------------------------------------

binary variables
    x(k0,m) 'assign job to machine'
    used(m) 'machine is used'
;

variable num 'number of machines needed';

Equations
   mustRun(k0)           'job has to be assigned to exactly one machine'
   dontOverlap(k0,k0,m)  'forbid overlapping jobs on the same machine'      
   usage(k0,m)           'use=0 => x=0'
   numMachines           'objective: minimize number of used machines'
   order(m)              'optional: ordering constraint'
;
   
mustRun(k)..  sum(m,x(k,m)) =e= 1;
dontOverlap(k,kk,m)$overlap(k,kk).. x(k,m)+x(kk,m) =l= 1;
usage(k,m)..  used(m) =g= x(k,m);
numMachines.. num =e= sum(m,used(m));
order(m-1)..  used(m) =l= used(m-1);

model assign1 /mustrun,dontoverlap,usage,nummachines,order/;


*-----------------------------------------------------------------
* Alternative graph coloring formulation
*-----------------------------------------------------------------


Equation
   coloring(k0,k0,m)            'graph coloring constraint'
;

coloring(k,kk,m)$overlap(k,kk).. x(k,m)+x(kk,m) =l= used(m);

model assign2 /mustRun,coloring,numMachines,order/;

*-----------------------------------------------------------------
* fix isolated subjobs to run on machine 1
*
* needed for the graph coloring model
* (not needed for the first model, but is does not hurt)
*
* this is ok even when not using the ordering constraint
*-----------------------------------------------------------------

set isolated(k0) 'jobs that have no overlap with other jobs';
isolated(k) = yes;
isolated(k)$sum(overlap(k,kk),1) = no;
isolated(kk)$sum(overlap(k,kk),1) = no;
display isolated;

singleton set machine1(m) 'first machine';
machine1(m) = ord(m)=1;

x.fx(isolated,machine1) = 1;


*-----------------------------------------------------------------
* we can fix one connected job to machine 1
*-----------------------------------------------------------------

loop(k$(not isolated(k)),
   x.fx(k,machine1) = 1;
   break;
);

display "fixed assignments",x.l;

*-----------------------------------------------------------------
* Solve
*----------------------------------------------------------------- 

option threads = 0;
solve assign1 minimizing num using mip;
option x:0,used:0,num:0;
display x.l,used.l,num.l;

*-----------------------------------------------------------------
* report solution in original space
*-----------------------------------------------------------------

parameter assignments(j,d,m);
assignments(jd,m) = sum(map(jd,k),x.l(k,m));
option assignments:0;
display assignments;

*-----------------------------------------------------------------
* prepare data for plotting and for networkx 
*-----------------------------------------------------------------

parameter plotdata(j,d,k0,m,*);

plotdata(map(j,d,k),m,'start')$(x.l(k,m)>0.5) = start2(k);
plotdata(map(j,d,k),m,'end')$(x.l(k,m)>0.5) = end2(k);
plotdata(map(j,d,k),m,'machine')$(x.l(k,m)>0.5) = ord(m);

execute_unload 'resultdata',plotdata;
execute 'gdxdump resultdata.gdx symb=plotdata format=csv output=plotdata.csv cdim=1';
execute 'gdxdump resultdata.gdx symb=overlap  format=csv output=networkdata.csv';

