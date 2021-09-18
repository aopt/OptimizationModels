$ontext

   Small LP about reallocating persons

   https://yetanothermathprogrammingconsultant.blogspot.com/2021/09/reallocate-people-very-small-but.html

   erwin@amsterdamoptimization.com


$offtext


set
   dummy 'for ordering (printing)' /initial,added,final/
   c 'category' /catA*catD/
   z 'zone'     /zone1*zone4/
;

*----------------------------------------------------------------
* data
*----------------------------------------------------------------

table popdata(c,z,*) 'population data'
                    initial   final
    catA.zone1         115     138
    catA.zone2         121     145
    catA.zone3         112     134
    catA.zone4          76      91
    catB.zone1          70      99
    catB.zone2          59      83
    catB.zone3          86     121
    catB.zone4         139     196
    catC.zone1         142     160
    catC.zone2          72      81
    catC.zone3          29      33
    catC.zone4          58      66
    catD.zone1          22      47
    catD.zone2          23      49
    catD.zone3          16      34
    catD.zone4          45      96
;
popdata(c,z,'added') = popdata(c,z,'final')-popdata(c,z,'initial');
option popdata:0;
display popdata;

parameter capacity(z) 'total capacity per zone' /
    zone1   465
    zone2   393
    zone3   500
    zone4   331
/;
option capacity:0;
display capacity;


parameter cost(c,z) 'cost moving to target zone' /
        catA.zone1   0.1
        catA.zone2   0.1
        catA.zone3   0.1
        catA.zone4   1.3
        catB.zone1  16.2
        catB.zone2  38.1
        catB.zone3   1.5
        catB.zone4   0.1
        catC.zone1   0.1
        catC.zone2  12.7
        catC.zone3  97.7
        catC.zone4  46.3
        catD.zone1  25.3
        catD.zone2   7.7
        catD.zone3  67.3
        catD.zone4   0.1
/;
option cost:1;
display cost;

*----------------------------------------------------------------
* summary data
*----------------------------------------------------------------

parameter counts(*,*) 'summary data';
counts('initial',z) = sum(c,popdata(c,z,'initial'));
counts('initial','total') = sum(z,counts('initial',z));
counts('final',z) = sum(c,popdata(c,z,'final'));
counts('final','total') = sum(z,counts('final',z));
counts('capacity',z) = capacity(z);
counts('capacity','total') = sum(z,capacity(z));
option counts:0;
display counts;


*----------------------------------------------------------------
* optimal reallocation
*----------------------------------------------------------------


alias(z,z1,z2);

parameter
   demand(c,z) 'current demand'
   cap(z)      'capacity (net)'
;

demand(c,z) = popdata(c,z,'final');
cap(z) = capacity(z);


positive variable move(c,z1,z2) 'moves needed to meet capacity';
positive variable alloc(c,z)  'new allocation';
variable totcost 'total cost';

equations
 eobj             'objective'
 ealloc(c,z)      'allocation bookkeeping'
 ecap             'capacity limits'
;



eobj.. totcost =e= sum((c,z1,z2),move(c,z1,z2)*cost(c,z2));
ealloc(c,z).. alloc(c,z) =e= demand(c,z) + sum(z1,move(c,z1,z)) - sum(z2,move(c,z,z2));
ecap(z).. sum(c,alloc(c,z)) =l= cap(z);

* not needed
move.fx(c,z,z) = 0;

model m /all/;
solve m minimizing totcost using lp;

option move:0, alloc:0;
display move.l,alloc.l,totcost.l;

counts('newalloc',z) = sum(c,alloc.l(c,z));
counts('newalloc','total') = sum(z,counts('newalloc',z));
display counts;

*----------------------------------------------------------------
* this is wrong: substitute out alloc
*----------------------------------------------------------------

equations
  ecap2(z)      'capacity constraint (WRONG!)'
;

ecap2(z).. sum(c, demand(c,z) + sum(z1,move(c,z1,z)) - sum(z2,move(c,z,z2))) =l= cap(z);

model m2 /eobj,ecap2/;
solve m2 minimizing totcost using lp;

parameter alloc2(c,z) 'recalculate allocations';
alloc2(c,z) = demand(c,z) + sum(z1,move.l(c,z1,z)) - sum(z2,move.l(c,z,z2))

display move.l,totcost.l,alloc2;


*----------------------------------------------------------------
* optimal reallocation while keeping initial population where
* they were.
*----------------------------------------------------------------

demand(c,z) = popdata(c,z,'added');
cap(z) = capacity(z) - sum(c,popdata(c,z,'initial'));

solve m minimizing totcost using lp;

option move:0, alloc:0;
display move.l,alloc.l,totcost.l;

counts('newalloc',z) = counts('initial',z) + sum(c,alloc.l(c,z));
counts('newalloc','total') = sum(z,counts('newalloc',z));
display counts;

