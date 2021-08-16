$ontext

  Stable Marriage Problem

  https://yetanothermathprogrammingconsultant.blogspot.com/2021/08/stable-marriage-problem.html


  I use the formulation from [1] and example 2 data from [2].

  We have problems reproducing the results in [2].

  1. John H. Vande Vate
     LINEAR PROGRAMMING BRINGS MARITAL BLISS
     Operations Research Letters 8 (1989) pp. 147-153

  2. Alvin E. Roth, Uriel G. Rothblum and John H. Vande Vate
     Stable Matchings, Optimal Assignments, and Linear Programming
     Mathematics of Operations Research
     Vol. 18, No. 4 (1993), pp. 803-828



  erwin@amsterdamoptimization.com


$offtext


*----------------------------------------------------------------
* data
*----------------------------------------------------------------

set
  m 'men'    /m1*m3/
  w 'women'  /w1*w3/
;
alias (m,mm),(w,ww);


table mpref(m,w) 'preferences of men for women (ranking,1=best)'
    w1 w2 w3
m1   1  2  3
m2   3  1  2
m3   2  3  1
;

table wpref(w,m) 'preferences of women for men (ranking,1=best)'
    m1 m2 m3
w1   3  2  1
w2   1  3  2
w3   2  1  3
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
* MIP model
*----------------------------------------------------------------

binary variable x(m,w) 'assignment';

variable z 'dummy objective';

equations
   obj            'dummy objective'
   assign1(w)     'assignment constraint'
   assign2(m)     'assignment constraint'
   stability(m,w) 'stability constraint'
;


obj.. z =e= 0;

assign1(w).. sum(m, x(m,w)) =e= 1;
assign2(m).. sum(w, x(m,w)) =e= 1;

* formulation from [1]
* if m marries someone worse than w then w must marry someone better than m
* otherwise we can improve both w and m
stability(m,w)..
  sum(betterWomen(m,w,ww),x(m,ww)) =g= sum(worseMen(w,m,mm),x(mm,w));

model StableMarriage /all/;
solve StableMarriage using mip minimizing z;

option x:0;
display x.l;

*----------------------------------------------------------------
* generate all feasible solutions
*----------------------------------------------------------------

sets
   sol 'max number of solutions' /sol1*sol100/
   s(sol) 'dynamic subset'
;

equation cut(sol) 'no good constraints';

parameter solutions(sol,m,w) 'enumerated solutions';

cut(s).. sum((m,w), solutions(s,m,w)*x(m,w)) =l= n-1;


model Enumerate /all/;

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


*----------------------------------------------------------------
* check solution from [2]
*----------------------------------------------------------------


parameter sol2(m,w) 'solution 3 from [2]' /
       m2.w1 1
       m3.w2 1
       m1.w3 1
/;
option sol2:0;
display sol2;

x.fx(m,w) = sol2(m,w);

solve StableMarriage using mip minimizing z;