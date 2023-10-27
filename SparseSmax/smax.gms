
set
*   i 'cases' /case1*case10/
   i 'cases' /case1*case100000/
   j 'attribute' /j1*j25/
   k 'attribute' /k1*k25/
   t 'type' /typ1*typ2/
;

parameter p(i,j,k,t) 'positive numbers';
* note: for each i we have only one (j,k) 
scalar s1,s2;
loop(i,
    s1 = uniformint(1,card(j));
    s2 = uniformint(1,card(k));
    p(i,j,k,t)$(ord(j)=s1 and ord(k)=s2) = uniform(0,1);   
);

option p:3:3:1;
display$(card(i)<=100) p;

option profile=1;

* version 1  (very slow)
* this calculates the smax for all combinations (i,j,k) (carthesian product)
parameter q(i,j,k) 'smax(t, p(i,j,k,t))';
q(i,j,k) = smax(t,p(i,j,k,t));

option q:3:0:1;
display$(card(i)<=100) q;

* version 2  (fast)
* this skips the smax for non-existent combinations (i,j,k)
* assumption: p>=0
parameter q2(i,j,k);
q2(i,j,k)$sum(t,p(i,j,k,t)) = smax(t,p(i,j,k,t));


* version 3: also works with negative values p (fast)
* here the $sum is counting nonzero values
parameter q3(i,j,k);
q3(i,j,k)$sum(t$p(i,j,k,t),1) = smax(t,p(i,j,k,t));


* version 4. Introduce a set with existing combinations
* (also fast but ijk+q4 takes a bit more time)
set ijk(i,j,k);
ijk(i,j,k) = sum(t$p(i,j,k,t),1);
parameter q4(i,j,k);
q4(ijk) = smax(t,p(ijk,t));
