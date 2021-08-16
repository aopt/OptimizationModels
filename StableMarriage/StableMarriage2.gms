$ontext

  Stable Marriage Problem

  https://yetanothermathprogrammingconsultant.blogspot.com/2021/08/stable-marriage-problem.html

  Slightly optimized version for slightly larger data set.
  For even larger data sets use the solution pool.

  For this example we get 9 stable solutions.

  erwin@amsterdamoptimization.com

$offtext

*----------------------------------------------------------------
* data
*----------------------------------------------------------------

set
  m 'men'    /m1*m8/
  w 'women'  /w1*w8/
;
alias (m,mm),(w,ww);

table mpref(m,w) 'preferences of men for women (ranking,1=best)'
    w1 w2 w3 w4 w5 w6 w7 w8
m1   3  4  8  7  1  5  2  6
m2   6  1  2  5  4  8  3  7
m3   3  6  7  4  2  5  8  1
m4   5  2  1  4  8  6  3  7
m5   4  2  5  8  3  6  1  7
m6   1  7  8  6  4  2  3  5
m7   8  1  5  6  2  4  3  7
m8   8  6  1  3  4  7  5  2
;


table wpref(w,m) 'preferences of women for men (ranking,1=best)'
    m1 m2 m3 m4 m5 m6 m7 m8
w1   5  6  2  8  1  4  3  7
w2   7  6  3  8  4  2  5  1
w3   1  4  8  5  2  3  7  6
w4   6  4  3  5  7  8  2  1
w5   6  7  4  2  8  1  3  5
w6   8  1  6  4  3  5  7  2
w7   4  3  8  7  2  6  1  5
w8   3  5  6  2  4  7  1  8
;

abort$(card(m)<>card(w)) "Equal-sized sets expected",m,w;

scalar n 'size of problem';
n = card(w);

*----------------------------------------------------------------
* derived data
*----------------------------------------------------------------

sets
  worseMen(w,m,mm)      'worse men than m for w'
  betterWomen(m,w,ww)   'better women than w for m'
;
worseMen(w,m,mm) = wpref(w,mm)>wpref(w,m);
betterWomen(m,w,ww) = mpref(m,ww)<mpref(m,w);

option mpref:0,wpref:0;
display m,w,mpref,wpref,worseMen,betterWomen;

*----------------------------------------------------------------
* MIP enumeration model
*----------------------------------------------------------------

sets
   sol 'max number of solutions' /sol1*sol100/
   s(sol) 'dynamic subset'
;

binary variable x(m,w) 'assignment';

variable z;

equations
   obj            'dummy objective'
   assign1(w)     'assignment constraint'
   assign2(m)     'assignment constraint'
   stability(m,w) 'stability constraint'
   cut(sol)       'no good constraints'
;

parameter solutions(sol,m,w) 'enumerated solutions';

obj.. z =e= 0;

assign1(w).. sum(m, x(m,w)) =e= 1;
assign2(m).. sum(w, x(m,w)) =e= 1;

stability(m,w)..
  sum(betterWomen(m,w,ww),x(m,ww)) =g= sum(worseMen(w,m,mm),x(mm,w));

cut(s).. sum((m,w), solutions(s,m,w)*x(m,w)) =l= n-1;

model Enumerate /all/;
Enumerate.solprint = %solprint.Silent%;
Enumerate.solvelink = 5;

s(sol) = no;
solutions(sol,m,w) = 0;
loop(sol,
    solve Enumerate using mip minimizing z;
    break$(Enumerate.ModelStat <> %modelStat.optimal% and
        Enumerate.ModelStat <> %modelStat.integerSolution%);

    solutions(sol,m,w) = round(x.l(m,w));
    s(sol) = yes;
);

option solutions:0:1:1;
display solutions;


