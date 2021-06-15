$ontext

   Find median using a non-smooth NLP model

   This model will have difficulties due to non-differentiability
   of the abs() function.
   
   References:
       https://yetanothermathprogrammingconsultant.blogspot.com/2021/06/median-quantiles-and-quantile.html

   erwin@amsterdamoptimization.com

$offtext

set i /i1*i5/;

parameter y(i) 'data';
y(i) = uniform(0,1);
display y;

variable
   m 'median'
   z 'objective'
;

equation sumabs;

sumabs.. z =e= sum(i, abs(y(i)-m));

* initial value
m.l = 0.5;

model median /sumabs/;
option dnlp=conopt;
solve median minimizing z using dnlp;

display m.l;
