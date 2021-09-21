$ontext

   Multiple-line regression

   Least squares and least absolute deviations can be used
   as objective.

   erwin@amsterdamoptimization.com

$offtext


*---------------------------------------------------------
* data
*---------------------------------------------------------

set
   i 'observations' /i1*i40/
   k 'line'     /line1*line3/
   f /'const.term', slope/
;

table data(i,*)
              x           y
i1       20.202      85.162
i2        0.507       2.103
i3       26.961      55.969
i4       49.985      44.690
i5       15.129      86.515
i6       17.417      79.866
i7       33.064      56.328
i8       31.691      29.422
i9       32.209      64.021
i10      96.398      85.191
i11      99.360      68.235
i12      36.990      57.516
i13      37.289      25.884
i14      77.198      56.157
i15      39.668      58.398
i16      91.310      66.205
i17      11.958      93.742
i18      73.548      28.178
i19       5.542       5.788
i20      57.630      60.830
i21       5.141      53.988
i22       0.601      42.559
i23      40.123      61.928
i24      51.988      42.984
i25      62.888      58.308
i26      22.575       4.414
i27      39.612      67.282
i28      27.601      56.445
i29      15.237       0.218
i30      93.632      11.896
i31      42.266      60.515
i32      13.466      51.721
i33      38.606      65.392
i34      37.463      16.978
i35      26.848      74.588
i36      94.837      -0.803
i37      18.894      60.060
i38      29.751      14.005
i39       7.455      60.066
i40      40.135      62.898
;

parameter x(i),y(i);
x(i) = data(i,'x');
y(i) = data(i,'y');
display x,y;

*---------------------------------------------------------
* model 1: multiple line least squares regression
*---------------------------------------------------------

scalar M 'big-M' /1000/;

free variables
   r(i)         'residuals'
   s(i,k)       'slack (to turn off a fit equation)'
   z            'objective'
   a(k,f)       'coefficients to estimate'
;

binary variable delta(i,k) 'assignment of point to line';

equations
   obj
   fit(i,k)   'standard linear fit + slack'
   impl1      'big-M constraint: delta=1 => s<=0'
   impl2      'big-M constraint: delta=1 => s>=0'
   sum1       'assignment'
   order      'order by constant term'
;

obj..          z =e= sum(i, sqr(r(i)));
fit(i,k)..     r(i) =e= y(i) - a(k,'const.term') - a(k,'slope')*x(i) + s(i,k);
impl1(i,k)..   s(i,k) =l= M*(1-delta(i,k));
impl2(i,k)..   s(i,k) =g= -M*(1-delta(i,k));
sum1(i)..      sum(k, delta(i,k)) =e= 1;
order(k+1)..   a(k,'const.term') =g= a(k+1,'const.term');

option optcr=0, threads=8, mip=cplex, miqcp=cplex;
model m1 /all/;
solve m1 minimizing z using miqcp;

* reporting
parameter report1(*,*) 'least squares results';
report1(k,f) = a.l(k,f);
report1(k,'points') = sum(i$(delta.l(i,k)>0.5),1);
report1(k,'sum(r^2)') = sum(i$(delta.l(i,k)>0.5),sqr(r.l(i)));
report1(k,'sum|r|') = sum(i$(delta.l(i,k)>0.5),abs(r.l(i)));
report1('total','sum(r^2)') = sum(i,sqr(r.l(i)));
report1('total','sum|r|') = sum(i,abs(r.l(i)));
report1('total','points') = card(i);
display report1;

*---------------------------------------------------------
* model 2: multiple line LAD regression
*---------------------------------------------------------

positive variables
   rplus(i)   'positive residuals'
   rmin(i)    'negative residuals'
;

equation
  fit2(i,k)  'LAD fit'
  obj2       'LAD obj'
;

obj2..  z =e= sum(i, rplus(i)+rmin(i));
fit2(i,k)..  rplus(i) - rmin(i) =e= y(i) - a(k,'const.term') -  a(k,'slope')*x(i) + s(i,k);

model m2 /obj2,fit2,impl1,impl2,sum1,order/;
solve m2 minimizing z using mip;

* reporting
parameter report2(*,*) 'least absolute deviations results';
report2(k,f) = a.l(k,f);
report2(k,'points') = sum(i$(delta.l(i,k)>0.5),1);
report2(k,'sum(r^2)') = sum(i$(delta.l(i,k)>0.5),sqr(rplus.l(i)-rmin.l(i)));
report2(k,'sum|r|') = sum(i$(delta.l(i,k)>0.5),rplus.l(i)+rmin.l(i));
report2('total','sum(r^2)') = sum(i,sqr(rplus.l(i)-rmin.l(i)));
report2('total','sum|r|') = sum(i,rplus.l(i)+rmin.l(i));
report2('total','points') = card(i);
display report2;

