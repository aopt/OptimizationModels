$ontext

   Total Least Squares as optimization problem

     Ivan Markovsky, Sabine Van Huffel, Overview of total least squares methods,
     Signal Processing, Volume 87, Issue 10, October 2007, Pages 2283-2302

     compare to R function tls (package tls)

     This model is written as a non-convex NLP. This turns out to be
     very challenging to solve.

     Reference:
     http://yetanothermathprogrammingconsultant.blogspot.com/2021/06/total-least-squares-nonconvex.html


     erwin@amsterdamoptimization.com

$offtext

set
   i 'observations' /i1*i25/
   j0 'statistical variables'  /y,x1*x2/
   j(j0) 'explanatory variables' /x1*x2/
;


table data(i,j0)
            Y        X1       X2
i1    5.658390  0.4978076  3.435376
i2   10.206082  1.5457447  9.413754
i3   11.735484  1.6531337  9.476257
i4   10.994595  2.8867848  9.694459
i5    8.178234  2.3530392 10.770926
i6   10.586022  2.7681198  5.760277
i7    4.481738  2.0639606  2.004087
i8    7.495135  3.5429598  3.440644
i9   10.959411  2.1747406  6.331947
i10   4.809324  2.8024155  1.620228
i11  13.290220  3.4065109 10.506181
i12   9.774514  3.5603761  5.563656
i13  12.084065  3.4039173  8.248807
i14   7.992731  4.4814979  2.519736
i15  12.111285  3.9963628  7.249193
i16  14.487092  3.9706833  9.410644
i17  11.062400  3.7342514  7.364956
i18   7.592865  4.7534969  4.695553
i19  11.244580  3.4450848  6.214768
i20   7.837413  6.7824328  6.367412
i21  12.199275  4.1444857  7.570009
i22  13.872630  5.4544764 10.463741
i23  10.461876  5.0577928  4.034925
i24  14.713012  5.6723841  7.914547
i25  10.751043  4.1856209  7.648005
;


option decimals=6;
display data;

parameter
  y(i)
  X(i,j)
;
y(i) = data(i,'y');
X(i,j) = data(i,j);

variables
   beta(j)      'parameter to estimate'
   epsilon(i)   'error in y'
   E(i,j)       'error in X'
   z            'objective variable'
;

equations
   obj          'objective'
   fit(i)       'equation to fit'
;

obj..    z =e= sum(i, sqr(epsilon(i))) + sum((i,j), sqr(E(i,j)));
fit(i).. y(i) + epsilon(i) =e= sum(j, (X(i,j)+E(i,j))*beta(j));

beta.lo(j) = -10; beta.up(j) = 10;
epsilon.lo(i) = -10; epsilon.up(i) = 10;
E.lo(i,j) = -10; E.up(i,j) = 10;

model tls /all/;
option optcr=0, threads=8, reslim=1000, minlp=baron;
solve tls using minlp minimizing z;

display beta.l;
