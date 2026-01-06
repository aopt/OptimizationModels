$onText

   Towers of Hanoi
   
$offText

*-----------------------------------------------------------------------------------
* size of problem
*-----------------------------------------------------------------------------------

$set n 3
$set makeplot 1

*-----------------------------------------------------------------------------------
* recursion in Python
*-----------------------------------------------------------------------------------


$onEmbeddedCode Python:

# returns number of moves
def hanoi(n,A,B,C):
   if n==0: return 0
   n1 = hanoi(n-1,A,C,B)
   print(f"move disk from peg {A} to {B}")
   n2 = hanoi(n-1,C,B,A)
   return n1+1+n2
   
N = %n%
print(f"N={N}")
cnt = hanoi(N,'A','B','C')
print(f"{cnt} moves")

$offEmbeddedCode

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
    initial(t,disk,peg) 'initial inventory (state)'
    final(disk,peg) 'final inventory (state)'
;

abort$(card(t)<2**n-1) "increase size of set t";

size(disk) = ord(disk);
maxsize = smax(disk,size(disk));

* initial state: all disks on peg A
* has t index to make it easier to use in the constraints
initial('t1',disk,'pegA') = 1;

* final state: all disks on peg B
final(disk,'pegB') = 1;

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
parameter initsmallest(t,peg);
initsmallest('t1',peg) = maxsize;
initsmallest('t1','pegA') = smin(disk,size(disk));
display initsmallest;

smallestPrev.fx('t1',peg) = initsmallest('t1',peg);
bndsmall(t,disk,peg)$(ord(t)>1).. smallestPrev(t,peg) =l= size(disk)*inv(t-1,disk,peg) + n*(1-inv(t-1,disk,peg));
smallfrom(t,peg)..     sum((disk,peg2),size(disk)*move(t,disk,peg,peg2)) =l= smallestPrev(t,peg);
smallto(t,peg)..       sum((disk,peg1),size(disk)*move(t,disk,peg1,peg)) =l= smallestPrev(t,peg);

* inventory balance
inventory(t,disk,peg)..
  inv(t,disk,peg) =e= inv(t-1,disk,peg) - sum(peg2,move(t,disk,peg,peg2)) + sum(peg1,move(t,disk,peg1,peg)) + initial(t,disk,peg);
  
* done if all disks are at peg B
isdone(t).. sum(disk,inv(t,disk,'pegB')) =g= n*done(t);

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
sinv('initial',disk,peg) = initial('t1',disk,peg);
loop(t,
   sinv(t,disk,peg) = inv.l(t,disk,peg)>0.5;
   break$(done.l(t)>0.5);
);
display sinv;

*-----------------------------------------------------------------------------------
* Visualization
*-----------------------------------------------------------------------------------

abort.noError$(n>6 or %makeplot%=0) "skipping plot";

$set svg hanoiplots.html

file f /%svg%/;
put f;

put '<style>table,th,td {border-collapse: collapse;}</style>'/;
put '<h2>Towers of Hanoi Results</h2>'/;
put 'Number of disks: %n%'/;

put '<table border="1">'/;
put '<tr>'/;

$eval n2 %n%+2

alias (t1,*);
parameter ndisks(*,peg) 'number of disks on each peg';
ndisks(t1,peg) = sum(sinv(t1,disk,peg),1);
display ndisks;

scalar nd,x,y,w,k /0/;

loop(t1$sum(sinv(t1,disk,peg),1),
   if (k=4,
       put "</tr><tr>"/;
       k = 0;
    );
   k = k + 1;

   put '<td style="text-align: center">'/;
   put '<svg height="100" width="300" viewBox="0 0 12 %n2%">'/;
* draw pegs   
   put '<line x1="3" y1="1" x2="3" y2="%n2%" style="stroke:brown;stroke-width:0.1"/>'/;
   put '<line x1="6" y1="1" x2="6" y2="%n2%" style="stroke:brown;stroke-width:0.1"/>'/;
   put '<line x1="9" y1="1" x2="9" y2="%n2%" style="stroke:brown;stroke-width:0.1"/>'/;

   loop(peg,
      nd = ndisks(t1,peg);
      loop(sinv(t1,disk,peg),
         y = n+1-nd+1;
         w = size(disk)*3/n;
         x = 3*ord(peg)-0.5*w;
*         display x,w,y;
         put '<rect x="',x:4:2,'" y="',y:4:2,'" height="1" width="',w:4:2,'" fill="lightblue"/>'/;
         put '<text x="',(3*ord(peg)):0:0,'" y="',(y+0.6):3:1,'" dominant-baseline="middle" text-anchor="middle" font-size="0.6">',(ord(disk)):0:0,'</text>'/;
         nd = nd-1;
      );
   );
   put '</svg><br>',t1.tl:0/;
   put '</td>'/;
);

put '</tr></table>';
putclose;
executetool 'win32.ShellExecute "%svg%"';