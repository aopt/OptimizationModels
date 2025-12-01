$onText

  MIP model

  Find a way to reorganize the list
      BDADDDBCCC → ABBCCCDDDD
  (sorting) using as few swaps as
  passible.  

  We can use a numerical version:
      2414442333 → 1223334444  
  
$offText


*---------------------------------------------------------------
* data
*---------------------------------------------------------------

Set
  i 'items' /item1*item10/
  k 'max iterations' /iter0*iter10/
;

alias(i,j);

Parameter
   init(i) 'initial ordering 2414442333' /
      item3 1
      (item1, item7) 2 
      (item8*item10) 3
      (item2, item4*item6) 4
   /;
   
display init;

*---------------------------------------------------------------
* linear MIP model
*---------------------------------------------------------------

variables
    x(k,i) 'values'
    itcount 'to minimize'
    
;

x.lo(k,i) = smin(j,init(j));
x.up(k,i) = smax(j,init(j));
x.fx('iter0',i) = init(i);


Scalar M 'big-M';
M = smax(i,init(i))-smin(i,init(i));


binary Variables
   s(k,i) 's(k,i)=1 : x(k,i) stays the same'
   d(k)   'd(k)=1 : we are done. No change needed anymore.'
;   
s.fx('iter0',i) = 0; 


equations
  count_same(k) 'number of x(k,i) that should stay the same'
  calc_itcount  'calc iteration count (obj)'
  same1(k,i)    'big-M constraint for x(k,i) staying the same'         
  same2(k,i)    'big-M constraint for x(k,i) staying the same'
  swap1(k,i,j)  'big-M constraint for x(k,i) being swapped'
  swap2(k,i,j)  'big-M constraint for x(k,i) being swapped'
  isSorted(k,i) 'big-M constraint for detecting x(k,i) is sorted'

* optional constraints
  order(k)      'optional: d(k) is ordered'
  extra(k)      'optional: x always adds up to the same number'
;

* counts
* done(k)=0 => sum(i, same(k,i)) = n-2
* done(k)=1 => sum(i, same(k,i)) = n
count_same(k)$(ord(k)>1).. sum(i, s(k,i)) =e= card(i)-2*(1-d(k));

* same
* same(k,i)=1 ==> x(k,i) = x(k-1,i)
same1(k,i)$(ord(k)>1)..x(k,i) =l= x(k-1,i) + M*(1-s(k,i));
same2(k,i)$(ord(k)>1)..x(k,i) =g= x(k-1,i) - M*(1-s(k,i));

* swap
* same(k,i)=0 & same(k,j)=0 ==> x(k,i) = x(k-1,j), x(k,j) = x(k-1,i)
* we will allow useless swaps 
swap1(k,i,j)$(ord(i)<>ord(j) and ord(k)>1).. x(k,i) =l= x(k-1,j) + M*(s(k,i)+s(k,j));
swap2(k,i,j)$(ord(i)<>ord(j) and ord(k)>1).. x(k,i) =g= x(k-1,j) - M*(s(k,i)+s(k,j));

* done
isSorted(k,i)$(ord(i)>1 and ord(k)>1).. x(k-1,i) =g= x(k-1,i-1) - M*(1-d(k));

* optional constraints (they help performance)
order(k)$(ord(k)>1).. d(k) =g= d(k-1);

extra(k).. sum(i, x(k,i)) =e= sum(i,init(i));

* obj
calc_itcount.. itcount =e= sum(k$(ord(k)>1), 1-d(k));

model sort /all/;
solve sort minimizing itcount using mip; 
display x.l, s.l, d.l, itcount.l;

* make a little report
parameter trace(k,*);
trace(k,i)$(d.l(k)<0.5) = x.l(k,i);
display trace;

