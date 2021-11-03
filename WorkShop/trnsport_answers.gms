$title  A Transportation Problem (TRNSPORT,SEQ=1)

$onText
This problem finds a least cost shipping schedule that meets
requirements at markets and supplies at factories.


Dantzig, G B, Chapter 3.3. In Linear Programming and Extensions.
Princeton University Press, Princeton, New Jersey, 1963.

This formulation is described in detail in:
Rosenthal, R E, Chapter 2: A GAMS Tutorial. In GAMS: A User's Guide.
The Scientific Press, Redwood City, California, 1988.

The line numbers will not match those in the book because of these
comments.

Keywords: linear programming, transportation problem, scheduling
$offText

Set
   i 'canning plants' / seattle,  san-diego /
   j 'markets'        / new-york, chicago, topeka /;

Parameter
   a(i) 'capacity of plant i in cases'
        / seattle     350
          san-diego   600  /

   b(j) 'demand at market j in cases'
        / new-york    325
          chicago     300
          topeka      275  /;

Table d(i,j) 'distance in thousands of miles'
               new-york       chicago        topeka
   seattle          2.5           1.7           1.8
   san-diego        2.5           1.8           1.4;

Scalar f 'freight in dollars per case per thousand miles' / 90 /;

Parameter c(i,j) 'transport cost in thousands of dollars per case';
c(i,j) = f * d(i,j) / 1000;

Variable
   x(i,j) 'shipment quantities in cases'
   z      'total transportation costs in thousands of dollars';

Positive Variable x;

Equation
   cost      'define objective function'
   supply(i) 'observe supply limit at plant i'
   demand(j) 'satisfy demand at market j';

cost..        z  =e=  sum((i,j), c(i,j)*x(i,j));

supply(i)..   sum(j, x(i,j)) =l= a(i);

demand(j)..   sum(i, x(i,j)) =g= b(j);

Model transport / all /;

solve transport using lp minimizing z;

display x.l, x.m;

*$stop
$ontext

    exercises

      1.1 Run the model and study the listing file.
      1.2 Make a typo in one of the labels (set elements), and
          see how GAMS reacts.
      1.3 Change the demand in NY to 400. What happens?
      1.4 We can protect the model against capacity problems. Add:
          abort$(sum(j,b(j))>sum(i,a(i))+0.0001) "Too much demand";
          If we pass this check, the model should be feasible.
      1.5 Change demand in NY back to 325.
      1.6 Pure network models have 2 nonzero elements in each column.
          Check the column listing for variable x. To view more columns
          in the column listing, add
             option limcol = 100;
          to the model. Notes:
             the objective does not count
             the default value for limcol is 3
             the solver will typically substitute out the objective
             variable, and create an objective function.


$offtext

* question 1.3
b('new-york') = 400;
solve transport using lp minimizing z;
**** MODEL STATUS      4 Infeasible

* question 1.4/1.5
b('new-york') = 325;
scalars
   totalSupply
   totalDemand
;
totalSupply = sum(i,a(i));
totalDemand = sum(j,b(j));

abort$(totalDemand > totalSupply+0.0001) "Too much demand";

* question 1.6
option limcol = 100;
solve transport using lp minimizing z;

$ontext

This should show:

---- x  shipment quantities in cases

x(seattle,new-york)
                (.LO, .L, .UP, .M = 0, 50, +INF, 0)
       -0.225   cost
        1       supply(seattle)
        1       demand(new-york)

x(seattle,chicago)
                (.LO, .L, .UP, .M = 0, 300, +INF, 0)
       -0.153   cost
        1       supply(seattle)
        1       demand(chicago)

x(seattle,topeka)
                (.LO, .L, .UP, .M = 0, 0, +INF, 0.036)
       -0.162   cost
        1       supply(seattle)
        1       demand(topeka)

x(san-diego,new-york)
                (.LO, .L, .UP, .M = 0, 350, +INF, 0)
       -0.225   cost
        1       supply(san-diego)
        1       demand(new-york)

x(san-diego,chicago)
                (.LO, .L, .UP, .M = 0, 0, +INF, 0.00900000000000001)
       -0.162   cost
        1       supply(san-diego)
        1       demand(chicago)

x(san-diego,topeka)
                (.LO, .L, .UP, .M = 0, 275, +INF, 0)
       -0.126   cost
        1       supply(san-diego)
        1       demand(topeka)


$offtext
$stop

*---------------------------------------------------------------
*
*   Here we compare a dual with rerunning the model with
*   a changed rhs.
*
*---------------------------------------------------------------

parameter dualcheck(*,*) 'increase demand of NYC by one unit';

dualcheck('before','demand') = b('new-york');
* results from previous solve
dualcheck('before','dual') = demand.m('new-york');
dualcheck('before','obj') = z.l;

b('new-york') = b('new-york') + 1;
solve transport using lp minimizing z;

dualcheck('after','demand') = b('new-york');
dualcheck('after','obj') = z.l;
dualcheck('diff','demand') = b('new-york') - dualcheck('before','demand');
dualcheck('diff','obj') = z.l - dualcheck('before','obj');

display dualcheck;


$stop

$ontext

  exercises

    2.1 check the output of dualcheck
        these numbers can also be found in the solution listing directly
    2.2 what happens if we increase NYC demand by 10 or 100?
        add
        abort$(transport.modelstat <> %modelstat.optimal%) "Model was not solved to optimality";
        to the model to alert about problems
    2.3 looking at the original solution (without changing demand)
        would it make sense to increase supply? How can you see this by looking
        at the duals.
        note: the actual delta in objective may be smaller than predicted
        by the dual if another constraint becomes binding.

$offtext


$ontext

  question 2.1

  We should see:


----    182 PARAMETER dualcheck  increase demand of NYC by one unit

            demand        dual         obj

before     325.000       0.225     153.675
after      326.000                 153.900
diff         1.000                   0.225

note the difference in the objective is the same as predicted by
the dual price.

$offtext

* question 2.2
b('new-york') = 325;
*b('new-york') = 325 + 10;
*b('new-york') = 325 + 100;

solve transport using lp minimizing z;
abort$(transport.modelstat <> %modelstat.optimal%) "Model was not solved to optimality";

* repair
b('new-york') = 325;


$ontext

   question 2.3

---- EQU supply  observe supply limit at plant i

                 LOWER          LEVEL          UPPER         MARGINAL

seattle          -INF          350.0000       350.0000         EPS
san-diego        -INF          550.0000       600.0000          .


   Adding capacity is not useful.

   San-Diego is not used at full capacity (basic between bounds)
   Seattle is at its capacity (non-basic at bound) but its dual is zero
   indicating that adding capacity does not lead to an improved objective

   You can verify this using
      solve ....
      a('seattle') = 351;
      solve ---
   and compare the objectives.

$offtext

*---------------------------------------------------------------
* run a larger model
*---------------------------------------------------------------


set k /k1*k10/;
positive variables xk(i,j,k) 'variables are duplicated k times';
* implement rest of the model

$ontext

   exercise

   3.   let's solve some larger models by duplicating the model k times.
        Introduce a set k /k1*k10/
        and add the index k to all variables and equations
        (except the objective -- why?).
        This model solves very fast even for larger k, say 1000

$offtext

Equation
   cost2        'define objective function'
   supply2(i,k) 'observe supply limit at plant i'
   demand2(j,k) 'satisfy demand at market j';

cost2..          z  =e=  sum((i,j,k), c(i,j)*xk(i,j,k));
supply2(i,k)..   sum(j, xk(i,j,k)) =l= a(i);
demand2(j,k)..   sum(i, xk(i,j,k)) =g= b(j);

model transport2 / cost2,supply2,demand2 /;
solve transport2 using lp minimizing z;


parameter stats(*) 'statistics';
stats('number of variables') = transport2.numvar;
stats('number of equations') = transport2.numequ;
stats('number of iterations') = transport2.iterusd;
stats('solution time') = transport2.resusd;
display stats;

$stop



*---------------------------------------------------------------
* dual model
*
*   max sum(i, a(i)*u(i)) + sum(j, b(j)*v(j))
*       u(i)+v(j) <= c(i,j)
*       u(i) <= 0, v(j) >= 0
*
*---------------------------------------------------------------

* implement the dual model

$ontext

  exercise:
   4. solve the dual formulation and see how we can
      extract the shipping pattern


$offtext

negative variable u(i) 'dual of supply';
positive variable v(j) 'dual of demand';
equation
  dualobj    'dual objective'
  e(i,j)     'dual constraint'
;

dualobj.. z =e=  sum(i,a(i)*u(i)) + sum(j,b(j)*v(j)) ;
e(i,j).. u(i)+v(j) =l= c(i,j);

model dual /dualobj,e/;
solve dual maximizing z using lp;

display "shipping pattern",e.m;

display "compare with original primal model";
solve transport minimizing z using lp;
display x.l,e.m;
display supply.m,u.l;
display demand.m,v.l;
