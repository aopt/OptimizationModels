$onText

   Towers of Hanoi
   
   This model finds a solution from a given starting configuration to
   a given final configuration.
   
   This can't be done with a standard recursive Towers of Hanoi algorithm
   
$offText

*-----------------------------------------------------------------------------------
* size of problem 
*-----------------------------------------------------------------------------------

$set n 4
$set makeplot 1

*-----------------------------------------------------------------------------------
* data
*-----------------------------------------------------------------------------------

* max number of moves
$set tmax 25

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
  initial(disk,peg) 'initial inventory (state)' / (disk1,disk2).pegA, (disk3,disk4).pegB /
  final(disk,peg) 'final inventory (state)'     / (disk1,disk2).pegB, (disk3,disk4).pegC /
;

abort$(card(t)<2**n-1) "increase size of set t";

size(disk) = ord(disk);
maxsize = smax(disk,size(disk));

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
  
* done if we reached final state
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
* Visualization
*-----------------------------------------------------------------------------------

abort.noError$(n>6 or %makeplot%=0) "skipping plot";

$set svg hanoiplots3.html

file f /%svg%/;
put f;

put '<style>table,th,td {border-collapse: collapse;}</style>'/;
put '<h2>Towers of Hanoi Extension 1</h2>'/;
put 'Number of pegs: ',card(peg):0:0,'<br>'/;
put 'Number of disks: %n% <br>'/;
put 'Number of moves: ',numMoves:0:0,'<br>'/;
put 'MIP model has ',m.numvar:0:0,' variables (of which ',m.numdvar:0:0,' binary) and ',m.numequ:0:0,' equations<br><br>'/;


put '<table border="1">'/;
put '<tr>'/;

$eval n2 %n%+2

alias (t1,*);
parameter ndisks(*,peg) 'number of disks on each peg';
ndisks(t1,peg) = sum(sinv(t1,disk,peg),1);
display ndisks;

scalar nd,x,y,w,k /0/;
parameter pegpos(peg) 'x position of pegs';
pegpos(peg) = 3*ord(peg);

loop(t1$sum(sinv(t1,disk,peg),1),
   if (k=4,
       put "</tr><tr>"/;
       k = 0;
    );
   k = k + 1;

   put '<td style="text-align: center">'/;
   put '<svg height="100" width="300" viewBox="0 0 12 %n2%">'/;
   
   loop(peg,
* draw peg
      put '<line x1="',pegpos(peg):0:0,'" y1="1" x2="',pegpos(peg):0:0,'" y2="%n2%" style="stroke:brown;stroke-width:0.1"/>'/;
* draw disk
      nd = ndisks(t1,peg);
      loop(sinv(t1,disk,peg),
         y = n+1-nd+1;
         w = size(disk)*3/n;
         x = 3*ord(peg)-0.5*w;
*         display x,w,y;
         put '<rect x="',x:0:2,'" y="',y:0:2,'" height="1" width="',w:0:2,'" fill="lightblue"/>'/;
         put '<text x="',pegpos(peg):0:2,'" y="',(y+0.6):0:2,'" dominant-baseline="middle" text-anchor="middle" font-size="0.6">',(ord(disk)):0:0,'</text>'/;
         nd = nd-1;
      );
   );
   put '</svg><br>',t1.tl:0/;
   put '</td>'/;
);

put '</tr></table>';
putclose;
executetool 'win32.ShellExecute "%svg%"';
