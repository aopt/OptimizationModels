$ontext

   Solve MAX CUT using data set g05_60.0
   Optimal solution is 536

$offtext

$set datafile g05_60.0
$set incfile  g05_60.inc

*------------------------------------------------------------------
* convert data file to a GAMS include file
*------------------------------------------------------------------


$onecho > translate.awk
{
  if (NR==1) {
     print "* Source data: %datafile%"
     print "set i /node1*node" $1 "/;"
     print "parameter w(i,i) /"
     next
  }

  print "node" $1 ".node" $2 " " $3

}

END { print "/;"}
$offecho

$call awk -f translate.awk %datafile% > %incfile%



set i;
parameter w(i,i);
$include %incfile%

alias(i,j)
set a(i,j) 'arcs';
a(i,j) = w(i,j);


*---------------------------------------------------------
* maxcut model 1: MIQP
*---------------------------------------------------------

binary variables
   x(i) 'node is in S'
;

variable z 'objective';

equations
   obj
;

obj.. z =e= sum(a(i,j),w(i,j)*sqr(x(i)-x(j)));

x.fx('node1')=1;

model maxcut /obj/;
option miqcp=cplex,threads=0,optcr=0;
maxcut.optfile=1;
solve maxcut maximizing z using miqcp;

$onecho > cplex.opt
qtolin 0
$offecho
