$onText

  The Dantzig Selector for sparse Regression
  
  Compare results of R package GDSARM with
  an LP model.

  See:
  https://yetanothermathprogrammingconsultant.blogspot.com/2024/04/lp-in-statistics-dantzig-selector.html

$offText

* for ordering of results
set dummy /delta, OLS/;

*------------------------------------------------
* data
*------------------------------------------------
Sets
   i 'rows',
   j0 'all columns';

Table data(i<,j0<)
   V1 V2 V3 V4 V5 V6 V7    V8
1   1  1 -1  1  1  1 -1 6.058
2   1 -1  1  1  1 -1 -1 4.733
3  -1  1  1  1 -1 -1 -1 4.625
4   1  1  1 -1 -1 -1  1 5.899
5   1  1 -1 -1 -1  1 -1 7.000
6   1 -1 -1 -1  1 -1  1 5.752
7  -1 -1 -1  1 -1  1  1 5.682
8  -1 -1  1 -1  1  1 -1 6.607
9  -1  1 -1  1  1 -1  1 5.818
10  1 -1  1  1 -1  1  1 5.917
11 -1  1  1 -1  1  1  1 5.863
12 -1 -1 -1 -1 -1 -1 -1 4.809
;
display i,j0,data;

*------------------------------------------------
* scale and center 
*------------------------------------------------

set j(j0) 'independent variables: columns for X';
j(j0) = ord(j0)<card(j0);

parameters
   n 'number of rows'
   mean(j0)
   sd(j0) 'standard deviation'
   scaled_data(i,j0)
;

n = card(i);
mean(j0) = sum(i,data(i,j0))/n; 

* center
scaled_data(i,j0) = data(i,j0)-mean(j0);
* scale (only for X)
sd(j) = sqrt(sum(i,sqr(scaled_data(i,j)))/(card(i)-1));
scaled_data(i,j) = scaled_data(i,j)/sd(j);
display scaled_data;    


*------------------------------------------------
* extract X,y
*------------------------------------------------

parameters
   X(i,j0) 'independent variables'
   y(i)    'dependent variable'
;
X(i,j) = scaled_data(i,j);
y(i) = scaled_data(i,'v8');
display X,y;


*------------------------------------------------
* Tuning parameter
* maxdelta and delta 
*------------------------------------------------

scalar MaxDelta;
MaxDelta = smax(j,abs(sum(i,X(i,j)*Y(i))));
display MaxDelta;

* create equally spaced values 0..MaxDelta
set k /k1*k4/;
parameter delta(k);
delta(k) = MaxDelta*(ord(k)-1) / (card(k)-1);
display delta;


*------------------------------------------------
* OLS regression
*------------------------------------------------

variable
  beta(j0) 'estimators'
  z        'objective'
  r(i)     'residuals'
;

equations
   fit(i)     'linear model'
   qobj       'quadratic objective'
;

qobj..      z =e= sum(i, sqr(r(i)));    
fit(i)..    r(i) =e= y(i) - sum(j,X(i,j)*beta(j));

model ols /qobj,fit/; 

*------------------------------------------------
* Dantzig selector LP model
* we need to set bounds for
*  Xr(i) >= -delta
*  Xr(i) <= delta
* that is done in the solve loop
*------------------------------------------------

variable
  Xr(j0)   'X^T*r' 
;
positive variable
  absb(j0) 'absolute values'
;

equations
   obj        'objective'
   bound1(j0) 'absolute value bound (obj)' 
   bound2(j0) 'absolute value bound (obj)'
   fit(i)     'linear model'
   defXr(j0)  'evaluate X^T*r' 
;

obj.. z =e= sum(j,absb(j));
bound1(j).. absb(j) =g= -beta(j);
bound2(j).. absb(j) =g= beta(j);
defXr(j)..  Xr(j) =e= sum(i,X(i,j)*r(i));

model ds /obj,fit,bound1,bound2,defXr/;


*------------------------------------------------
* run regressions
*------------------------------------------------

parameter results(*,*) 'estimations';

solve ols using qcp minimizing z;
results('OLS',j) = beta.l(j);

results(k,'delta') = delta(k);
loop(k,
   Xr.lo(j) = -delta(k);
   Xr.up(j) = delta(k);
   solve ds using lp minimizing z;
   display beta.l;
   results(k,j) = beta.l(j);
);
display results;


