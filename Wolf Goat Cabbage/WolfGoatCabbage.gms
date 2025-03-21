$onText

A farmer with a wolf, a goat, and a cabbage must cross a river by boat. The boat can carry
only the farmer and a single item. If left unattended together, the wolf would eat the goat,
or the goat would eat the cabbage. How can they cross the river without anything being eaten?

https://en.wikipedia.org/wiki/Wolf,_goat_and_cabbage_problem

$offText


*-------------------------------------------------------------------------
* data
*-------------------------------------------------------------------------

sets
** basic sets
   dummy 'for ordering in displays' /initial/
   trip 'trips' /trip1*trip10/
   item /wolf,goat,cabbage/
   side 'left/right bank' /L,R/
   dir 'direction of trip' /'L->R','R->L'/
   case 'forbidden item combinations' /case1,case2/

** derived sets
   tripDir(trip,dir) 'trip direction combos'
   arrival(trip,side) 'this is an arrival'
   departure(trip,side) 'this is a departure'
;

* trips 1,3,5,.. are L->R, trips 2,4,6,..  are R->L
tripDir(trip,'L->R') = mod(ord(trip),2) = 1;
tripDir(trip,'R->L') = mod(ord(trip),2) = 0;
display trip,dir,tripDir;

* arrival or departure
arrival(trip,'L') = tripdir(trip,'R->L');
arrival(trip,'R') = tripdir(trip,'L->R');
departure(trip,side) = not arrival(trip,side);
display arrival,departure;

* all items are on the left bank initially
parameter InvInitial(item,side,trip) 'start inventory before trip1' /
    (wolf, goat, cabbage).L.trip1   1
/;

* the final state is to have all items on the right bank
parameter InvTarget(item,side) 'target inventory' /
    (wolf, goat, cabbage).R   1
/;
    
* these combinations can not be left alone
table Eat(case,item) 'combinations not allowed'
        wolf  goat  cabbage
case1     1     1     
case2           1      1
;
 
*-------------------------------------------------------------------------
* Model
*-------------------------------------------------------------------------

variables
   pax(trip,item)      'passengers: items taken on each trip'
   inv(trip,side,item) 'inventory just after trip'
   done(trip)          'if 1 we are done'
   z                   'objective'
;
binary variable pax,inv,done;

equations
   countPassengers(trip)       'max number of passengers/items on a trip'
   invBal(side,item,trip,dir)  'inventory balance after trip'
   eating(trip,side,case)      'some combinations of items are forbidden when unattended'
   isDone1(trip,item)          "done = prod(item,inv(trip,'R',item))" 
   isDone2(trip)               "done = prod(item,inv(trip,'R',item))"
   ordering(trip)              'done(trip)>=done(trip-1)' 
   obj                         'objective'
;

* capacity constraint 
countPassengers(trip).. sum(item,pax(trip,item)) =l= 1;

* inventory just after trip
invBal(side,item,tripDir(trip,dir))..
    inv(trip,side,item) =e= inv(trip-1,side,item) + pax(trip,item)$arrival(trip,side) - pax(trip,item)$departure(trip,side) + invInitial(item,side,trip); 

* forbidden combinations
eating(departure(trip,side),case)..
    sum(item, Eat(case,item)*inv(trip,side,item)) =l= 1+done(trip);

* done = prod(item,inv(trip,'R',item))
isDone1(trip,item).. done(trip) =l= inv(trip,'R',item);
isDone2(trip).. done(trip) =g= sum(item,inv(trip,'R',item))-2;

* done(trip)>=done(trip-1)
* ordering(trip-1).. makes sure we only generate the constraints that are needed
ordering(trip-1).. done(trip) =g= done(trip-1);

* maximize number of "done" trips
obj.. z =e= sum(trip, done(trip));

* optional
done.fx(trip)$(ord(trip)=card(trip)) = 1;
inv.fx(trip,side,item)$(ord(trip)=card(trip)) = invTarget(item,side);

model m /all/;
solve m maximizing z using mip;
abort$(m.modelstat <> %modelStat.optimal% and m.modelstat <> %modelStat.integerSolution%) "No solution";

*-------------------------------------------------------------------------
* raw results
*-------------------------------------------------------------------------

option pax:0,inv:0:1:2,done:0;
display pax.l,inv.l,done.l,z.l;

*-------------------------------------------------------------------------
* more meaningful trip report
*-------------------------------------------------------------------------

alias(item,item2);

parameter trace(*,*,*,side,item) 'trip report';
trace('initial','','',side,item) = invInitial(item,side,'trip1');
loop(trip,
   trace(tripDir(trip,dir),item,side,item2)$(pax.l(trip,item)>0.5) = inv.l(trip,side,item2);
   trace(tripDir(trip,dir),'',side,item2)$(sum(item,pax.l(trip,item))<0.5) = inv.l(trip,side,item2);
   break$(done.l(trip)>0.5);
);
option trace:0:3:2;
display trace;

*-------------------------------------------------------------------------
* find second solution
* for binary variable x(i):
*   ecut(cut).. sum(i$sol(i,cut),x(i)) - sum(i$(sol(i,cut)=0),x(i)) =l= sum(i$sol(i,cut),1) - 1;
*-------------------------------------------------------------------------

sets
   cut 'static set' /cut1*cut2/ 
   dcut(cut) 'dynamic subset'
   ti(trip,item) 'trip-item combos'
;
ti(trip,item) = yes;

parameter sol(trip,item,cut) 'earlier solutions';

equation ecut(cut) 'no-good cut';

ecut(dcut).. sum(ti$sol(ti,dcut),pax(ti)) - sum(ti$(sol(ti,dcut)=0),pax(ti)) =l= sum(ti$sol(ti,dcut),1) - 1;

* find second solution with same objective value
model m2/m,ecut/;
dcut('cut1') = yes;
sol(ti,'cut1') = round(pax.l(ti));
z.fx = round(z.l);
solve m2 maximizing z using mip;
abort$(m2.modelstat <> %modelStat.optimal% and m2.modelstat <> %modelStat.integerSolution%) "No second solution";
display pax.l;

* there should be no third solution: this model is infeasible 
dcut('cut2') = yes;
sol(ti,'cut2') = round(pax.l(ti));
solve m2 maximizing z using mip;
abort$(m2.modelstat = %modelStat.optimal% or m2.modelstat = %modelStat.integerSolution%) "Expected model to be infeasible";
