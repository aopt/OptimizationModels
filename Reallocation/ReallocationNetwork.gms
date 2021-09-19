$ontext

   Small LP about reallocating persons
   Formulated as a network model

   https://yetanothermathprogrammingconsultant.blogspot.com/2021/09/reallocate-people-very-small-but.html

   erwin@amsterdamoptimization.com


$offtext


set
   dummy  'for ordering (printing)' /initial,added,final/
   c0     'category superset'       /catA*catD, all/
   c(c0)  'category'                /catA*catD/
   z0     'zone superset'           /zone1*zone4, sink/
   z(z0)  'zone'                    /zone1*zone4/
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
* network topology
*----------------------------------------------------------------

alias (z,z1,z2),(c,c1,c2);

set
  n(c0,z0) 'nodes' /
       (catA*catD,all).(zone1*zone4)
       all.sink
   /
   a(c0,z0,c0,z0) 'arcs'
;

a(c,z1,'all',z2) = yes;
a('all',z,'all','sink') = yes;

option a:0:2:2;
display n,a;

parameter
   acost(c0,z0,c0,z0)     'cost of an arc'
   inflow(c0,z0)          'exogenous in- or outflow'
   cap(c0,z0,c0,z0)       'capacity of an arc'
;

acost(c,z1,'all',z2)$(not sameas(z1,z2)) = cost(c,z2);
inflow(c,z) = popdata(c,z,'final');
inflow('all','sink') = -sum((c,z),popdata(c,z,'final'));
cap('all',z,'all','sink') = capacity(z);

option acost:1:2:2,inflow:0,cap:0:2:2;
display acost,inflow,cap;


*----------------------------------------------------------------
* min cost flow network model
*----------------------------------------------------------------

positive variable flow(c0,z0,c0,z0) 'flows along arcs';
variable totcost 'total cost';

equations
   nodbal(c0,z0) 'node balance'
   objective
;

alias(n,n1,n2);

objective.. totcost =e= sum(a,acost(a)*flow(a));

nodbal(n1)..  sum(a(n2,n1),flow(a)) + inflow(n1) =e= sum(a(n1,n2),flow(a));

flow.up(a)$cap(a) = cap(a);


model mincostflow /all/;
solve mincostflow minimizing totcost using lp;


option flow:0:2:2;
display flow.l, totcost.l;

parameter moves(c,z,z) 'computed from flows';
moves(c,z1,z2)$(not sameas(z1,z2)) = flow.l(c,z1,'all',z2);
option moves:0;
display moves;

