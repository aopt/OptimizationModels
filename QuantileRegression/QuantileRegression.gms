$ontext

   Quantile regression optimization problem as LP
   Both primal and dual models.

   Data from:
      https://sites.google.com/site/econometricsacademy/econometrics-models/quantile-regression

   References:
      http://yetanothermathprogrammingconsultant.blogspot.com/2021/06/median-quantiles-and-quantile.html

   erwin@amsterdamoptimization.com


$offtext


*-------------------------------------------------------------
* data from csv file
*-------------------------------------------------------------

$set csv quantile_health.csv
$set gdx quantile_health.gdx

sets
   i 'observations'
   j0 'column names in csv file'
;

parameter data(i,*) 'all data';

$call csv2gdx %csv% output=%gdx% id=data useHeader=T index=1 values=(2..8)

$gdxin %gdx%
$loaddc i=Dim1 j0=Dim2 data

display i,j0,data;

*-------------------------------------------------------------
* setup of regression data y,X
*-------------------------------------------------------------

set
  j 'independent variables' /intercept,suppins,totchr,age,female,white/
;

parameter
   y(i)   'dependent variable'
   X(i,j) 'independent variables'
;

y(i) = data(i,'totexp');
X(i,j) = data(i,j);
X(i,'intercept') = 1;


*-------------------------------------------------------------
* quantile regression LP model (primal)
*-------------------------------------------------------------

set
  pm /'+','-'/
;

scalar tau 'quantile';

positive variables e(i,pm) 'absolute value';

variables
   z 'objective variable'
   beta(j) 'estimates'
;

equations
   obj      'objective'
   split(i)  'variable splitting'
;

obj.. z =e= sum(i, tau*e(i,'+') + (1-tau)*e(i,'-'));
split(i).. e(i,'+')-e(i,'-') =e= y(i)-sum(j,X(i,j)*beta(j));

model quantileLP /obj,split/;


*-------------------------------------------------------------
* solve loop
*-------------------------------------------------------------

set q 'quantile levels' /'0.25','0.5','0.75'/;

parameter estimates(q,j);

loop(q,
   tau = q.val;
   solve quantileLP minimizing z using lp;
   estimates(q,j) = beta.l(j);
);

display estimates;

*-------------------------------------------------------------
* quantile regression LP model (dual)
*-------------------------------------------------------------

variable d(i) 'variables of dual problem';

equations
   obj2        'objective of dual'
   eqdual(j)   'constraint of dual problem'
;

obj2.. z =e= sum(i, y(i)*d(i));
eqdual(j).. sum(i, x(i,j)*d(i)) =e= 0;

* still missing are the bounds on d.
* we populate them in the solve loop below

model quantileDual /obj2,eqdual/;

*-------------------------------------------------------------
* solve loop
*-------------------------------------------------------------

parameter estimates2(q,j) 'from dual';

loop(q,
   tau = q.val;
   d.lo(i) = tau-1;
   d.up(i) = tau;
   solve quantileDual maximizing z using lp;
   estimates2(q,j) = eqdual.m(j);
);

display estimates2;