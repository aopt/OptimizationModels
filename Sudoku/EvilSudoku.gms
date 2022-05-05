$ontext

   Evil Sudoku from sudoku.com

   Reference:
   http://yetanothermathprogrammingconsultant.blogspot.com/2016/10/mip-modeling-from-sudoku-to-kenken.html


$offtext

set
  a      'all areas (rows,columns,squares)' /r1*r9,c1*c9,s1*s9/
  i(a)   'rows' /r1*r9/
  j(a)   'columns' /c1*c9/
  s(a)   'squares' /s1*s9/
  u(a,i,j) 'areas with unique values a=area name, (i,j) are the cells'
  k      'values' /1*9/;
;

*
* populate u(a,i,j)
*
u(i,i,j) = yes;
u(j,i,j) = yes;
u(s,i,j)$(ord(s)=3*ceil(ord(i)/3)+ceil(ord(j)/3)-3) = yes;
display u;

*
* given values
*
table v0(i,j)
   c1 c2 c3 c4 c5 c6 c7 c8 c9
r1                 9     5
r2  7                    1
r3        8  2        7     9
r4  6              4  9     8
r5     4     1
r6                          5
r7        2     3
r8  8              1  6     4
r9                       7
;

*
* MIP model
*
binary variable x(i,j,k);
x.fx(i,j,k)$(v0(i,j)=k.val) = 1;
variable z 'dummy objective';

equations
   dummy 'objective'
   unique(a,k) 'all-different'
   values(i,j) 'one value per cell'
;

dummy.. z =e= 0;
unique(a,k).. sum(u(a,i,j), x(i,j,k)) =e= 1;
values(i,j).. sum(k, x(i,j,k)) =e= 1;

model sudoku /all/;

*
* solve
*
solve sudoku minimizing z using mip;

*
* display solution
*
parameter v(i,j) 'solution';
v(i,j) = sum(k, k.val*x.l(i,j,k));
option v:0;
display v;

