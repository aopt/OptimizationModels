$ontext

    Ragnar Relay Race

$offtext


* choose small or large
$set small 1
$set large 0

set i 'legs' /leg1*leg36/;
parameter legLen(i) /
       leg1 3.3,  leg2  4.2, leg3  5.2, leg4  3,   leg5  2.7, leg6  4,
       leg7 5.3,  leg8  4.5, leg9  3,   leg10 5.8, leg11 3.3, leg12 4.9,
       leg13 3.1, leg14 3.2, leg15 4,   leg16 3.5, leg17 4.9, leg18 2.3,
       leg19 3.2, leg20 4.6, leg21 4.5, leg22 4,   leg23 5.3, leg24 5.9,
       leg25 2.8, leg26 1.9, leg27 2.1, leg28 3,   leg29 2.5, leg30 5.6,
       leg31 1.3, leg32 4.6, leg33 1.5, leg34 1.2, leg35 4.1, leg36 8.1
       /;

$ifthen %small%==1
set j 'runs' /run1*run6/;
parameter runLen(j) /
    run1  3.2, run2 12.3, run3 5.2, run4  2.9, run5 2.9, run6 5.5
/;
$endif

$ifthen %large%==1
set j 'runs' /run1*run8/;
parameter runLen(j) /
    run1 20.0, run2  5.4, run3 3.3, run4 26.4, run5 2.4, run6 8.6, run7 14.6, run8 20
/;
$endif

binary variable
   assign(i,j) 'assign leg to runner'
   covered(i)  'leg is covered'
;
variable numLegs 'number of covered legs';

equations
    objective  'maximize covered legs'
    eassign    'assignment'
    isCovered  'leg is covered'
    order      'ordering of legs'
;

objective..     numLegs =e= sum(i, covered(i));

eassign(j)..    sum(i, legLen(i)*assign(i,j)) =l= runLen(j);

isCovered(i)..  covered(i) =l= sum(j,assign(i,j));

order(i-1)..    covered(i-1) =g= covered(i);

model m /all/;
option optcr=0;
solve m maximizing numLegs using mip;

option assign:0,covered:0;
display assign.l, covered.l, numLegs.l;

parameter report(*,*)  'results';
report(i,j) = assign.L(i,j)*covered.l(i)*legLen(i);
report('total',j) = sum(i,report(i,j));
report('runLen',j) = runLen(j);
option report:1;
display report;




