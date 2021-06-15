$ontext

   Find Median using an LP model

   Use two formulations for the absolute values


   References:
      http://yetanothermathprogrammingconsultant.blogspot.com/2021/06/median-quantiles-and-quantile.html


   erwin@amsterdamoptimization.com

$offtext

set
  i /i1*i5/
;

parameter y(i) 'data';
y(i) = uniform(0,1);
display y;


*-------------------------------------------------------------
* formulation 1: bounding
*-------------------------------------------------------------

variables
   m    'median'
   z    'objective'
;
positive variables
   e(i) 'absolute value, formulation 1'
;

equations
   obj1      'objective, formulation 1'
   bound1(i)
   bound2(i)
;

obj1.. z =e= sum(i, e(i));
bound1(i).. e(i) =g= m-y(i);
bound2(i).. e(i) =g= -(m-y(i));

model medianLP1 /obj1,bound1,bound2/;
solve medianLP1 minimizing z using lp;

display m.l;

*-------------------------------------------------------------
* formulation 2: variable splitting
*-------------------------------------------------------------
set
  pm /'+','-'/
;

positive variables
   e2(i,pm) 'absolute value, formulation 2'
;

equations
   obj2      'objective, formulation 2'
   split(i)  'variable splitting'
;

obj2.. z =e= sum((i,pm), e2(i,pm));
split(i).. e2(i,'+')-e2(i,'-') =e= m-y(i);

model medianLP2 /obj2,split/;
solve medianLP2 minimizing z using lp;

display m.l;

display e2.l;
