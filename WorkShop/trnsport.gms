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

$stop

$ontext

    exercises

      1.1 Run the model and study the listing file.
      1.2 Make a typo in one of the labels (set elements), and
          see how GAMS reacts.
      1.3 Change the demand in NY to 400. What happens?
      1.4 We can protect the model against capacity problems. Add:
          abort$(totalDemand>totalSupply+0.0001) "Too much demand";
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

* repoir
b('new-york') = 325;


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
