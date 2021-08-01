$ontext

   Spatial Equilibrium

   Quick and dirty model
   (Only "true" complementarity for trade, the rest are equalities)


   Data from:

   D. Lee Bawden
   A Spatial Price Equilibrium Model of International Trade
   American Journal of Agricultural Economics
   Volume 48, November 1966, Pages 862-874


$offtext


*---------------------------------------------------------------
* Data
*---------------------------------------------------------------


set
   dummy 'for better display' /Intercept/
   c 'commodities' /Wheat, FeedGrains, Beef/
   r 'regions' /US, EEC, UKIreland, Other/
   g(c) 'grains' /Wheat, FeedGrains/
;

* demand/supply as (linear) function of prices
table coeff(*,c,r,*) 'coefficients for demand and supply functions'

                            Intercept   Wheat    FeedGrains    Beef
Demand.Wheat.US              15364      -4.96
Demand.Wheat.EEC             14383      -3.40
Demand.Wheat.UKIreland        4427      -1.29
Demand.Wheat.Other           31731

Demand.FeedGrains.US        140556               -1224        48.13
Demand.FeedGrains.EEC        31694                -157        10.68
Demand.FeedGrains.UKIreland  12720                 -63         5.82
Demand.FeedGrains.Other

Demand.Beef.US               14190                            -6.95
Demand.Beef.EEC               6830                            -3.29
Demand.Beef.UKIreland         2178                            -1.42
Demand.Beef.Other

Supply.Wheat.US              18520        427     -190
Supply.Wheat.EEC             12655        213      -74
Supply.Wheat.UKIreland        1441         30       -8
Supply.Wheat.Other

Supply.FeedGrains.US         98438       -694     2163
Supply.FeedGrains.EEC        16531        -85      207
Supply.FeedGrains.UKIreland   5446        -35       68
Supply.FeedGrains.Other       2479

Supply.Beef.US                6536                 -84          5.9
Supply.Beef.EEC               3235                 -24          2.9
Supply.Beef.UKIreland          808                  -6          1.0
Supply.Beef.Other              584
;

alias(r,rr);

table transCost(*,r,rr) 'Transportation Cost Matrix'
                      US     EEC    UKIreland    Other
Beef.US                     84.802   80.702     100.000
Beef.EEC                              4.221     100.000
Beef.UKIreland                                  100.000
Beef.Other

Grain.US                     8.438    8.030      15.000
Grain.EEC                             0.420      15.000
Grain.UKIreland                                  15.000
Grain.Other
;


alias(c,cc);

* set the transportation cost for the individual grains
* and use
transCost(g,r,rr) = transCost('Grain',r,rr);
transCost(c,r,rr)$(transCost(c,r,rr)=0) = transCost(c,rr,r);

display  coeff,transCost;


*-----------------------------------------------------------------------
* spatial equilibrium
*-----------------------------------------------------------------------

positive variables
   Qd(c,r)      'demand quantities at demand regions'
   Qs(c,r)      'supply quantities at supply regions'
   P(c,r)       'price'
   X(c,r,rr)    'quantities traded/shipped'
;

equations
   supply(c,r)     'supply function'
   demand(c,r)     'demand function'
   flows(c,r)      'trade flows'
   trade(c,r,rr)   'prices'
;


supply(c,r)..
   Qs(c,r) =e= coeff('supply',c,r,'intercept')
                + sum(cc,coeff('supply',c,r,cc)*P(cc,r));

demand(c,r)..
     coeff('demand',c,r,'intercept')
     + sum(cc,coeff('demand',c,r,cc)*P(cc,r)) =e= Qd(c,r);

flows(c,r)..
      Qs(c,r) + sum(rr, X(c,rr,r)) =e= Qd(c,r) + sum(rr, X(c,r,rr));

* this is true complementarity equation:
*       trade(r,rr,c) >= 0 compl. X(c,r,rr) >= 0
* only one can be non-binding
trade(c,r,rr)..
   P(c,r) + transCost(c,r,rr) =g= P(c,rr);

* "shipping" means here: trade between different regions
* so fix x=0 if we deal with the same region
x.fx(c,r,r) = 0;


model lcp /supply.Qs, demand.Qd, flows.P, trade.x/;


*-----------------------------------------------------------------------
* check solution from Bawden
*-----------------------------------------------------------------------


table sol(c,*,*)  'solution from Bawden'


                            US     EEC    UKIreland    Other    production  price

Wheat.US                   15032                       24016      39048     66.96
Wheat.EEC                         14155    1282         7715      23152     66.96
Wheat.UKIreland                            3059                    3059     67.38
Wheat.Other                                                                 81.96
Wheat.consumption          15032  14155    4341        31731

FeedGrains.US             128448   7919    7390                  143757     42.43
FeedGrains.EEC                    21370                           21370     50.87
FeedGrains.UKIreland                       6519                    6519     50.46
FeedGrains.Other                   2479                            2479     35.87
FeedGrains.Consumption    128448  31768   13909                  174125

Beef.US                     7854                                   7854    827.59
Beef.EEC                           4203                            4203    754.81
Beef.UKIreland                      144    1112                    1256    750.59
Beef.Other                   584                                    584    727.59
Beef.Consumption            8438   4347    1112

;

display sol;

* set initial values
x.l(c,r,rr)$(not sameas(r,rr)) = sol(c,r,rr);
Qs.l(c,r) = sol(c,r,'production');
Qd.l(c,r) = sol(c,'consumption',r);
P.l(c,r) = sol(c,r,'price');

* iterlim = 0 so solver will only check initial solution
* inspect the listing file
option limrow=9999,iterlim=0;
solve lcp using mcp;

scalar obj;
obj = lcp.objval;
display obj;
$stop

*-----------------------------------------------------------------------
* compute equilibrium
*-----------------------------------------------------------------------

option iterlim=99999;
solve lcp using mcp;


*-----------------------------------------------------------------------
* reporting
*-----------------------------------------------------------------------

parameter mysol(c,*,*)  'our solution';
mysol(c,r,rr) = x.l(c,r,rr);
mysol(c,r,r) = Qs.l(c,r) - sum(rr$(not sameas(r,rr)),x.l(c,r,rr));
mysol(c,r,'production') = Qs.l(c,r);
mysol(c,'consumption',r) = Qd.l(c,r);
mysol(c,r,'price') = P.l(c,r);
display mysol;

