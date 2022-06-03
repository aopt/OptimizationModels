$ontext

   Select K out of N

   Select K points such that they are as close as possible to a given point.

   See:
   https://yetanothermathprogrammingconsultant.blogspot.com/2022/06/a-subset-selection-problem.html 

$offtext

*------------------------------------------------------------
* data
*------------------------------------------------------------

set
   i 'data points' /i1*i100/
   j 'unique values' /1,2,3/
   pm /'+','-'/
 ;

*
* data drawn from set j
*
parameter p(i) 'data';
p(i) = uniformint(1,card(j));
p(i) = sum(j$(ord(j)=p(i)),j.val);
option p:0:0:8;

scalars
   k 'number to select' /50/
   t 'target for mean of selected values' /2.12345/
;
option k:0,t:5;

display p,k,t;


*------------------------------------------------------------
* model 1
* binary variables delta(i)
*------------------------------------------------------------

variables
   z          'objective'
   delta(i)   'selection of points'
   dev(pm)    'deviation'
;
binary variable delta;
positive variable dev;

Equations
   obj         'objective'
   deviation   'deviation of mean from target'
   count       'number of selected points'
;

obj.. z =e= sum(pm,dev(pm));
deviation.. dev('+')-dev('-') =e= sum(i,delta(i)*p(i))/k-t;
count.. sum(i,delta(i)) =e= k;

model m1 /obj,deviation,count/;
solve m1 minimizing z using mip;

parameter value(i) 'selected values';
value(i) = p(i)*delta.l(i);

parameter vcount(j) 'count of each value';
vcount(j) = sum(i$(value(i)=j.val), 1);

option delta:0:0:6, value:0:0:6, vcount:0;
option dev:6,z:6;
display delta.l,value,vcount,dev.l,z.l;

*------------------------------------------------------------
* model 2
* integer variable num(j)
*------------------------------------------------------------


parameter tab(j) 'tabulation';
tab(j) = sum(i$(p(i)=j.val),1);
option tab:0;
display tab;

integer variable num(j) 'number selected from bin j';

  
equation idev, icount;
idev.. dev('+')-dev('-') =e= sum(j,num(j)*j.val)/k-t;
icount.. sum(j,num(j)) =e= k;

num.up(j) = tab(j);

model m2 /obj,idev,icount/;
solve m2 minimizing z using mip;

option num:0;
display num.l,dev.l,z.l;

*------------------------------------------------------------
* model 3
* best k=1...Kmax using a loop
*------------------------------------------------------------

scalar kmax;
kmax = k;

* fast solve loop
option solprint=silent, solvelink=5;

parameter
  bestObj 'best objective' /INF/ 
  bestNum 'best selection'
  traceObj 'trace objective values'
;
for(k=1 to kmax,

   solve m2 minimizing z using mip;
   traceObj(i)$(ord(i)=k) = z.l;
   if (z.l<bestObj,
       bestObj=z.l;
       bestNum(j) = num.l(j);
   ); 
   
);
  
option bestObj:6,bestNum:0,traceObj:6:0:4;
display "**** Loop",traceObj,bestObj,bestNum;

option solprint = on;
*------------------------------------------------------------
* model 4
* best k=1...Kmax using single model
*------------------------------------------------------------

Scalar U 'maximum deviation';
U = kmax*(smax(i,p(i))-smin(i,p(i)));

positive variable
    y(i,pm)  'dev(i,pm)*delta(i)'
;

integer Variable
    kvar 'k as variable'
;
kvar.lo = 1;
kvar.up = kmax;

Equation
    LinDev 'linearized version'         
    Linearization1(i,pm) 
    Linearization2(i,pm)
    Linearization3(i,pm)
    kdef
;
LinDev..         sum(i,y(i,'+')-y(i,'-')) =e= sum(i,delta(i)*p(i))-t*kvar;

Linearization1(i,pm).. y(i,pm) =l= delta(i)*U;
Linearization2(i,pm).. y(i,pm) =l= dev(pm);
Linearization3(i,pm).. y(i,pm) =g= dev(pm) - (1-delta(i))*U;

kdef.. sum(i,delta(i)) =e= kvar; 

model m4 /obj,lindev,linearization1,linearization2,linearization3,kdef/;
solve m4 minimizing z using mip;

value(i) = p(i)*delta.l(i);
vcount(j) = sum(i$(value(i)=j.val), 1);

option kvar:0;
display kvar.l, vcount, z.l;
