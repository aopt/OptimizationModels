$onText

  Simple demo of lifted MTZ
  
  References:
      Miller, C., A. Tucker, R. Zemlin. 1960.
      Integer programming formulation of traveling
      salesman problems. J. ACM 7 326-329


      Desrochers, M., Laporte, G.,
      Improvements and extensions to the Miller-Tucker-Zemlin
      subtour elimination constraints,
      Operations Research Letters, 10 (1991) 27-36.

$offText


* use all cores
option threads = 0;

*-------------------------------------------------------
* data
*-------------------------------------------------------

sets
   i 'cities' /city1*city58/
   xy /x,y/
;
alias(i,j);

scalar n 'number of cities';
n = card(i);

parameter coord(i,xy) 'random coordinates';
coord(i,xy) = uniform(0,100);

parameter dist(i,j) 'distance matrix';
dist(i,j) = sqrt(sum(xy,sqr(coord(i,xy)-coord(j,xy))));

set arcs(i,j) 'travel allowed between cities';
arcs(i,j) = not sameas(i,j);

display n,i,coord,dist,arcs;

*-------------------------------------------------------
* reporting macro
*-------------------------------------------------------

parameter stats(*,*) 'collected statistics';

$macro statistics(label,model_)  \
  stats(label,'obj') = model_.objval;  \
  stats(label,'iterations') = model_.iterusd; \
  stats(label,'nodes') = model_.nodusd;  \
  stats(label,'seconds') = model_.resusd;  \
  display stats;


*-------------------------------------------------------
* Original MTZ formulation
* Integer ordering variables
*-------------------------------------------------------

variable totdist 'total distance';
binary variable x(i,j) 'assignment variables: if 1 we travel i->j';
integer variable u(i) 'ordering';
u.up(i) = card(i)-1;
* start in city 1
u.fx('city1') = 0; 


equations
    objective  'sum of distances traveled'
    assign1(i) 'assignment constraint'
    assign2(j) 'assignment constraint'
    sequence(i,j) 'ordering constraint'
;

objective.. totdist =e= sum(arcs, dist(arcs)*x(arcs));

* I am being a bit cute here:
* first one sums over j, second one sums over i
* although the equations look the same, they are different
* because of the ∀i vs ∀j (for all i vs for all j)
assign1(i).. sum(arcs(i,j), x(arcs)) =e= 1;
assign2(j).. sum(arcs(i,j), x(arcs)) =e= 1;

* MTZ ordering constraint
* x(i,j)=1 => u(j) = u(i) + 1
* we implement this as a big-M constraint
sequence(arcs(i,j))$(not sameas(j,'city1'))..
     u(j) =g= u(i) + 1 - n*(1-x(i,j));
* this is also often written as
*     u(i) - u(j) + n*x(i,j) <- n-1  

model mtz /all/;
solve mtz using mip minimizing totdist;

display "%%% original MTZ formulation, integer u %%%",totdist.l,x.l,u.l;

statistics('MTZ(int u)',mtz)

*-------------------------------------------------------
* Original MTZ formulation
* relaxed ordering variables
*-------------------------------------------------------

* relax u
u.prior(i) = inf;
solve mtz using mip minimizing totdist;

display "%%% original MTZ formulation, relaxed u %%%",totdist.l,x.l,u.l;

statistics('MTZ(relaxed u)',mtz)

*-------------------------------------------------------
* Lifted MTZ formulation
*-------------------------------------------------------

* make u integer again
u.prior(i) = 1;

equation lifted(i,j) 'lifted version of sequence constraint';

lifted(arcs(i,j))$(not sameas(j,'city1'))..
     u(i)-u(j) + (n-1)*x(i,j) + (n-3)*x(j,i) =l= n-2;
       
model liftedmtz /mtz-sequence+lifted/
solve liftedmtz using mip minimizing totdist;

statistics('lifted(int u)',liftedmtz)


* relax u
u.prior(i) = inf;
solve liftedmtz using mip minimizing totdist;

statistics('lifted(int u)',liftedmtz)

*-------------------------------------------------------
* Add valid inequalities
*-------------------------------------------------------

* make u integer again
u.prior(i) = 1;

equations
   valid1(j) 'valid inequalities'
   valid2(j) 'valid inequalities' 
;

valid1(j)$(not sameas(j,'city1'))..
   u(j) =g= 1 + (1-x('city1',j)) + (n-3)*x(j,'city1'); 
valid2(j)$(not sameas(j,'city1'))..
   u(j) =l= (n-1) - (n-3)*x('city1',j) - (1-x(j,'city1')); 

model liftedmtz2 /liftedmtz,valid1,valid2/;

solve liftedmtz2 using mip minimizing totdist;

statistics('lift+vi(int u)',liftedmtz2)


* relax u
u.prior(i) = inf;
solve liftedmtz2 using mip minimizing totdist;

statistics('lift+vi(relaxed u)',liftedmtz2)


*-------------------------------------------------------
* Plot results
*-------------------------------------------------------

file f /tour.html/;
put f '<svg width="1000" height="800" viewBox="-10 -10 110 110">'/;
loop(arcs(i,j)$(x.l(arcs)>0.5),
   put '<line x1="',coord(i,'x'):0,'" y1="',coord(i,'y'):0,
       '" x2="',coord(j,'x'):0,'" y2="',coord(j,'y'):0,
       '" stroke="darkred" stroke-width="0.1"/>'/;
);
loop(i,
   put '<circle cx="',coord(i,'x'):0,'" cy="',coord(i,'y'):0,
       '" r="0.5" fill="blue"/>'/;
);
putclose '</svg>'/;
execute 'shellexecute tour.html';
