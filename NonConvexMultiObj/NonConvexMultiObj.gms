$ontext

  https://or.stackexchange.com/questions/7013/how-to-linearize-a-non-convex-optimization-objective-function

  find efficient frontier point by point

$offtext


*------------------------------------------------------------------------------
* data
*------------------------------------------------------------------------------

scalars
  c0  / 1.4 /
  c1  / 1 /
  c2  / 2 /
  c3  / 3 /
  c4  / 4 /
  c5  / 5 /
  d1  / 1 /
  d2  / 2 /
  d3  / 3 /
  d4  / 4 /
  d5  / 5 /
  e1  / 1 /
  a1  / 12 /
  a2  / 8 /
  a3  / 15 /
;

set dummy /x1,x2/;

*------------------------------------------------------------------------------
* base model
*------------------------------------------------------------------------------

integer variables x1,x2;

set k /obj1*obj3/;
alias (k,k2);

parameter w(k) 'weights';

variables
   f(k)   'objectives'
   f0     'weighted sum'
;

equations
   obj1
   obj2
   obj3
   xsum
   fsum
;

x1.lo = 1;
x1.up = a1;
x2.up = a2;


obj1..  f('obj1') =e= c0 + (c1+c2*x2+c5*sqr(x2))/x1 + c3*x1 + c4*x2;
obj2..  f('obj2') =e= d1*x1 + d2*x2 + d3*sqr(x1) + d4*sqr(x2) + d5*x1*x2;
obj3..  f('obj3') =e= -e1*x2;

xsum.. x1+x2 =l= a3;

fsum.. f0 =e= sum(k2,w(k2)*f(k2));

option optcr=0, minlp=baron, threads=4;

model base /all/;

*------------------------------------------------------------------------------
* determine fbox: min and max f(k)
*------------------------------------------------------------------------------
base.solprint = %solprint.Silent%;

parameters
   fbox(k,*) 'objective box'
   M(k)      'big-M'
;

loop(k,
   w(k) = 1;
   solve base minimizing f0 using minlp;
   fbox(k,'lo') = f.l(k);
   solve base maximizing f0 using minlp;
   fbox(k,'up') = f.l(k);
   w(k) = 0;
);
display fbox;

M(k) = fbox(k,'up')-fbox(k,'lo');
display M;


*------------------------------------------------------------------------------
* non-dominated constraints
*------------------------------------------------------------------------------
sets
   p 'points' /point1*point1000/
   pf(p) 'found points'
;
pf(p) = no;

parameter solutions(p,*) 'non-dominated solutions';
solutions(p,k) = 0;

binary variable
  df(p,k) 'non-dominated check'
;

equations
    fbetter1(k,p) 'obj(k) is better compared to point p'
    fbetter2(p)
;

fbetter1(k,pf).. f(k) =l= solutions(pf,k) - 0.01 + (M(k)+0.01)*(1-df(pf,k));
fbetter2(pf).. sum(k,df(pf,k)) =g= 1;

model ndom /all/;

*------------------------------------------------------------------------------
* big loop
*------------------------------------------------------------------------------


ndom.solprint = %solprint.Silent%;
w(k) = 1;

loop(p,

   solve ndom minimizing f0 using minlp;
   break$(ndom.modelstat <> %modelStat.optimal%);


   solutions(p,'x1') = x1.l;
   solutions(p,'x2') = x2.l;
   solutions(p,k) = f.l(k);

   pf(p) = yes;

);

display solutions;

parameter sums(*) 'checksum';
set c /x1,x2,obj1, obj2, obj3/;
sums(c) = sum(pf,solutions(pf,c));
display sums;
