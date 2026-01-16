$onText

   Towers of Hanoi

   Is solution unique?   
   
$offText


*-----------------------------------------------------------------------------------
* size of problem
*-----------------------------------------------------------------------------------

$set n 4

*-----------------------------------------------------------------------------------
* data
*-----------------------------------------------------------------------------------

* max number of moves
* we can guess (overestimate) or use the known value 2^n-1
*$set tmax 25
$eval tmax 2**%n%-1

sets
   dummy 'for ordering' /initial/
   peg /pegA,pegB,pegC/
   disk  /disk1*disk%n%/
   t 'moves or timesteps' /t1*t%tmax%/
;
display peg,disk,t;

alias (peg,peg1,peg2);

Parameters
    n 'number of disks' /%n%/
    size(disk) 'size of each disk: 1..n'
    maxsize 'maximum size of disk'
;

Sets
  initial(disk,peg) 'initial inventory (state)'
  final(disk,peg) 'final inventory (state)'


abort$(card(t)<2**n-1) "increase size of set t";

size(disk) = ord(disk);
maxsize = smax(disk,size(disk));

* initial state: all disks on peg A
* has t index to make it easier to use in the constraints
initial(disk,'pegA') = yes;

* final state: all disks on peg B
final(disk,'pegB') = yes;

display n,size,maxsize,initial,final;


*-----------------------------------------------------------------------------------
* MIP model
*-----------------------------------------------------------------------------------


binary variable
   move(t,disk,peg,peg)   'disk is moved from one peg to another'
   inv(t,disk,peg)        'inventory after move'
   done(t)                'we are done'   
;
variable smallestPrev(t,peg) 'smallest disk in previous iteration';
smallestPrev.lo(t,peg) = 1;
smallestPrev.up(t,peg) = maxsize;

variable z 'obj';

equations  
   move1disk(t)           'move 1 disk (or 0 if done)'
   bndsmall(t,disk,peg)   'bound on smallest size of disk'
   smallfrom(t,peg)       'need to select smallest disk from source peg' 
   smallto(t,peg)         'size restriction on destination peg' 
   inventory(t,disk,peg)  'inventory balance' 
   isdone(t)              'we are done'
   ordering(t)            'optional'
   assignment(t,disk)     'optional assignment constraint'
   obj                    'objective'  
;


* if done=1: move zero disks
* if done=0: move exactly one disk
move1disk(t).. sum((disk,peg1,peg2),move(t,disk,peg1,peg2)) =e= 1-done(t-1);

* don't move a disk from and to the same peg
move.fx(t,disk,peg,peg) = 0;

* we can only move the smallest disk
parameter initsmallest(t,peg) 'smallest disk on each peg for initial configuration';
initsmallest('t1',peg)$(sum(initial(disk,peg),1)=0) = maxsize;
initsmallest('t1',peg)$(sum(initial(disk,peg),1)>0) = smin(initial(disk,peg),size(disk));
display initsmallest;

smallestPrev.fx('t1',peg) = initsmallest('t1',peg);
bndsmall(t,disk,peg)$(ord(t)>1).. smallestPrev(t,peg) =l= size(disk)*inv(t-1,disk,peg) + n*(1-inv(t-1,disk,peg));
smallfrom(t,peg)..     sum((disk,peg2),size(disk)*move(t,disk,peg,peg2)) =l= smallestPrev(t,peg);
smallto(t,peg)..       sum((disk,peg1),size(disk)*move(t,disk,peg1,peg)) =l= smallestPrev(t,peg);

* inventory balance
inventory(t,disk,peg)..
  inv(t,disk,peg) =e= inv(t-1,disk,peg) - sum(peg2,move(t,disk,peg,peg2)) + sum(peg1,move(t,disk,peg1,peg)) + 1$(initial(disk,peg) and ord(t)=1);
  
* done if all disks are at peg B
isdone(t).. sum((disk,peg)$final(disk,peg),inv(t,disk,peg)) =g= n*done(t);

obj.. z =e= sum(t,done(t));

* optional constraints
ordering(t-1).. done(t) =g= done(t-1);
assignment(t,disk).. sum(peg,inv(t,disk,peg)) =e= 1;

* optional fixes
set lastt(t);
lastt(t) = ord(t)=card(t);
done.fx(lastt) = 1;
inv.fx(lastt,disk,peg) = final(disk,peg); 

model m /all/;

*-----------------------------------------------------------------------------------
* Solve
*-----------------------------------------------------------------------------------

solve m maximizing z using mip;
abort$(m.modelstat <> %modelStat.optimal% and m.modelstat <> %modelstat.integerSolution%) "no solution";

* raw results
option move:0:2:2;
display smallestPrev.l,move.l,inv.l,done.l;

*-----------------------------------------------------------------------------------
* Reporting
*-----------------------------------------------------------------------------------

set sinv(*,disk,peg) 'include initial, and stop after done';
sinv('initial',initial) = yes;
loop(t,
   sinv(t,disk,peg) = inv.l(t,disk,peg)>0.5;
   break$(done.l(t)>0.5);
);
display sinv;

scalar numMoves 'number of moves';
numMoves = sum(t$sum(sinv(t,disk,peg),1),1);
display numMoves;

*-----------------------------------------------------------------------------------
* Is solution unique?
* try to find another solution with N=2^n-1 steps
*-----------------------------------------------------------------------------------

set sol(t,disk,peg,*);
sol(t,disk,peg,'1') = inv.l(t,disk,peg)>0.5;
sol(t,disk,peg,'0') = inv.l(t,disk,peg)<0.5;

equation cut;
cut.. sum(sol(t,disk,peg,'0'),inv(t,disk,peg)) + sum(sol(t,disk,peg,'1'),1-inv(t,disk,peg)) =g= 1;

model m2 /m,cut/;
solve m2 maximizing z using mip;
abort$(m2.modelstat = %modelStat.optimal% or m.modelstat = %modelstat.integerSolution%) "solution not unique";
 