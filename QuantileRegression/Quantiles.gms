$ontext

   find quantiles using an LP model

   References:
      http://yetanothermathprogrammingconsultant.blogspot.com/2021/06/median-quantiles-and-quantile.html

   erwin@amsterdamoptimization.com


$offtext

set
  i 'observations' /i1*i25/
  t 'quantile levels' /'0','0.25','0.5','0.75','1'/
;

parameter y(i) 'data';
y(i) = uniform(10,100);

display y,t;

*-------------------------------------------------------------
* variable splitting LP Model
*-------------------------------------------------------------

set
  pm /'+','-'/
;

scalar tau 'quantile level';

positive variables e(i,pm) 'absolute value';

variable
   z 'objective variable'
   q 'quantile'
;


equations
   obj      'objective'
   split(i)  'variable splitting'
;

obj.. z =e= sum(i, tau*e(i,'+') + (1-tau)*e(i,'-'));
split(i).. e(i,'+')-e(i,'-') =e= y(i)-q;

model quantileLP /obj,split/;


*-------------------------------------------------------------
* solve loop
*-------------------------------------------------------------

parameter quantiles(t) 'Solution';

loop(t,
   tau = t.val;
   solve quantileLP minimizing z using lp;
   quantiles(t) = q.l;
);
display quantiles;