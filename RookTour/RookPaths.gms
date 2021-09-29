$ontext

   A Numbrix-like puzzle.

   Place the numbers 1..64 on an 8x8 board such that:

      1. next values are neighbors. A neighbor is defined as
         below, left, right, or above.
      2. certain cells need to contain a prime number

   Find all possible Hamiltonian paths.

   https://puzzling.stackexchange.com/questions/111818/another-rooks-tour-of-the-chessboard

$offtext

*----------------------------------------------------------------------
* data
*----------------------------------------------------------------------

sets
  i 'rows'    /i1*i8/
  j 'columns' /j1*j8/
  k 'values'  /1*64/
  kprime(k) 'primes' /
             2,3,5,7,11,13,17,19,23,29,
             31,37,41,43,47,53,59,61
    /
;

acronym p;
table board(i,j) 'locations with a p should get a prime value'
        j1 j2 j3 j4 j5 j6 j7 j8
  i1     p           p
  i2        p     p           p
  i3     p                 p
  i4              p           p
  i5           p  p  p
  i6                    p
  i7     p           p     p
  i8                    p     p
;

*----------------------------------------------------------------------
* model
*----------------------------------------------------------------------

set sol /solution1*solution10/;
set solfound(sol) 'solutions found';
parameter solution(sol,i,j,k) 'solutions found so far';
solfound(sol) = no;
solution(sol,i,j,k) = 0;


binary variable x(i,j,k);
variable dummy;

equations
   onevalue(i,j) 'each cell has one value (between 1 and 81)'
   unique(k)     'each value must be in exactly one cell'
   next(i,j,k)   'x(i,j,k)=1 => a neighbor is k+1'
   isprime(i,j)  'we need a prime on (i,j)'
   cut(sol)      'cut off previous solutions'
   obj           'dummy'
;

obj.. dummy =e= 0;

onevalue(i,j).. sum(k, x(i,j,k)) =e= 1;
unique(k)..     sum((i,j),x(i,j,k)) =e= 1;

next(i,j,k+1)..
   x(i-1,j,k+1)+x(i+1,j,k+1)+x(i,j-1,k+1)+x(i,j+1,k+1) =g= x(i,j,k);

isprime(i,j)$(board(i,j)=p)..
   sum(kprime, x(i,j,kprime)) =e= 1;

cut(solfound)..
   sum((i,j,k),solution(solfound,i,j,k)*x(i,j,k)) =l= card(k)-1;

model m /all/;
option mip=cplex,threads=8;

*----------------------------------------------------------------------
* solve loop
*----------------------------------------------------------------------


loop(sol,
    solve m minimizing dummy using mip;
    break$(m.modelstat <> %modelStat.optimal% and m.modelstat <> %modelStat.integerSolution%);
    solfound(sol) = yes;
    solution(sol,i,j,k) = round(x.l(i,j,k));
    display x.l;
);


*----------------------------------------------------------------------
* reporting
*----------------------------------------------------------------------

parameter result(sol,i,j) 'negative numbers indicate prime cells';
result(sol,i,j) = sum(k, k.val*solution(sol,i,j,k));
result(sol,i,j)$(board(i,j)=p) = -result(sol,i,j);
option result:0:1:1;
display result;
