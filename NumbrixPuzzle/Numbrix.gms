$ontext

   Numbrix.gms

   Solve the Numbrix puzzle.

   See:
   https://yetanothermathprogrammingconsultant.blogspot.com/2020/12/numbrix-puzzle-via-mip.html

   erwin@amsterdamoptimization.com


$offtext


sets
  i 'rows'    /i1*i9/
  j 'columns' /j1*j9/
  k 'values'  /1*81/
;

table board(i,j)
        j1 j2 j3 j4 j5 j6 j7 j8 j9
  i1
  i2       25 20 13 14 15  8 41
  i3       26                40
  i4        1                39
  i5       30                38
  i6       67                37
  i7       70                50
  i8       73 72 79 60 61 52 53
  i9
;


binary variable x(i,j,k);
variable dummy;

equations
   onevalue(i,j) 'each cell has one value (between 1 and 81)'
   unique(k)     'each value must be in exactly one cell'
   next(i,j,k)   'x(i,j,k)=1 => a neighbor is k+1'
   obj           'dummy'
;

obj.. dummy =e= 0;
onevalue(i,j).. sum(k, x(i,j,k)) =e= 1;
unique(k)..     sum((i,j),x(i,j,k)) =e= 1;
next(i,j,k+1).. x(i-1,j,k+1)+x(i+1,j,k+1)+x(i,j-1,k+1)+x(i,j+1,k+1) =g= x(i,j,k);

x.fx(i,j,k)$(board(i,j)=k.val) = 1;

model m /all/;
option mip=cplex;
solve m minimizing dummy using mip;
display x.l;

parameter result(i,j);
result(i,j) = sum(k, k.val*x.l(i,j,k));
option result:0;
display result;