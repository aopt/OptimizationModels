$ontext

   Multiple-line regression
 
   We have 3 unknown lines and 40 points. We want to assign each point to a line and 
   estimate the line parameters such that the total sum of absolute deviations is minimized. 
   
   We use a heuristic to find a good starting solution.

   Versions:
      model 1, mindicsplit: indicator constraints, variable splitting (MIP)
      model 2, mindicsplit2: add ordering constraint
      model 3, mindicbnd: linearize by bounding 
      model 4, mindicbnd2: add ordering  
      model 5, bigM+ordering+split
      model 6, bigM+ordering+bounding


   erwin@amsterdamoptimization.com

$offtext

*option lp=xpress,mip=xpress,minlp=xpress;
*option lp=gurobi,mip=gurobi,minlp=gurobi;
option lp=cplex,mip=cplex,minlp=baron;

option reslim=3600;


*---------------------------------------------------------
* data
*---------------------------------------------------------

set
   i 'observations' /case1*case40/
   j 'independent variables' /intercept, slope/
   k 'line'         /line1*line3/
   c 'coordinates'  /x, y/
;

table data(i,c)
              x           y
case1       20.202      85.162
case2        0.507       2.103
case3       26.961      55.969
case4       49.985      44.690
case5       15.129      86.515
case6       17.417      79.866
case7       33.064      56.328
case8       31.691      29.422
case9       32.209      64.021
case10      96.398      85.191
case11      99.360      68.235
case12      36.990      57.516
case13      37.289      25.884
case14      77.198      56.157
case15      39.668      58.398
case16      91.310      66.205
case17      11.958      93.742
case18      73.548      28.178
case19       5.542       5.788
case20      57.630      60.830
case21       5.141      53.988
case22       0.601      42.559
case23      40.123      61.928
case24      51.988      42.984
case25      62.888      58.308
case26      22.575       4.414
case27      39.612      67.282
case28      27.601      56.445
case29      15.237       0.218
case30      93.632      11.896
case31      42.266      60.515
case32      13.466      51.721
case33      38.606      65.392
case34      37.463      16.978
case35      26.848      74.588
case36      94.837      -0.803
case37      18.894      60.060
case38      29.751      14.005
case39       7.455      60.066
case40      40.135      62.898
;
display data;

parameters
   x(i) 'x coordinate'
   y(i) 'y coordinate'
;
x(i) = data(i,'x');
y(i) = data(i,'y');
display x,y;


*---------------------------------------------------------
* reporting macro
*---------------------------------------------------------

parameter results(*,*) 'compare models';
acronym timelimit,ok;
$macro store_results(modelid,modelname) \
   results(modelname,'obj') = modelid.objval; \
   results(modelname,'time') = modelid.resusd; \
   results(modelname,'nodes') = modelid.nodusd; \
   results(modelname,'status')$(modelid.solvestat=3) = timelimit; \
   results(modelname,'status')$(modelid.solvestat=1) = ok; \
   display results;


*---------------------------------------------------------
* model 1: indicator constraints with variable splitting
*---------------------------------------------------------

set pm /'+','-'/;

free variables
   sad          'objective: sum of absolute deviations'
   alpha(k,j)   'coefficients to estimate for each line'
;

positive variables
   rsplit(i,pm) 'residuals split in plus and minus part'
;

binary variable delta(i,k) 'assignment of point to line';

equations
   objsplit        'sum of absolute deviations' 
   fitsplit(i,k)   'linear fit'     
   sum1            'assignment'
;

objsplit..       sad =e= sum((i,pm), rsplit(i,pm));
sum1(i)..        sum(k, delta(i,k)) =e= 1;


* indicator constraint
fitsplit(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + rsplit(i,'+') - rsplit(i,'-');

$echo indic fitsplit(i,k)$delta(i,k)  1 > cplex.opt
$echo indic fitsplit(i,k)$delta(i,k)  1 > xpress.opt
$echo indic fitsplit(i,k)$delta(i,k)  1 > gurobi.opt

model mindicsplit /objsplit,fitsplit,sum1/;
mindicsplit.optfile=1;
solve mindicsplit minimizing sad using mip;

display sad.l,delta.l,alpha.l; 

store_results(mindicsplit,'indic+split')


*---------------------------------------------------------
* model 2: add ordering constraint
*---------------------------------------------------------


equation order(k)  'order by intercept';

order(k+1)..   alpha(k,'intercept') =l= alpha(k+1,'intercept');

model mindicsplit2 /mindicsplit,order/;
mindicsplit2.optfile=1;
solve mindicsplit2 minimizing sad using mip;

display alpha.l;

store_results(mindicsplit2,'indic+split+ord')


*---------------------------------------------------------
* model 3: indicator constraints with absolute value bounding
*---------------------------------------------------------

free variables
   r(i) 'residuals'
;

positive Variables
   rho(i) '|r(i)|'
;

equations
   objabs     'sum of absolute deviations' 
   fit(i,k)   'linear fit'
   bnd1(i)    'linearize abs()'
   bnd2(i)    'linearize abs()'
;

objabs..    sad =e= sum(i,rho(i));
bnd1(i)..   rho(i) =g= -r(i);
bnd2(i)..   rho(i) =g= r(i);

* indicator constraint
fit(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r(i);

$echo indic fit(i,k)$delta(i,k)  1 > cplex.op2
$echo indic fit(i,k)$delta(i,k)  1 > xpress.op2
$echo indic fit(i,k)$delta(i,k)  1 > gurobi.op2

model mindicbnd /objabs,fit,sum1,bnd1,bnd2/;
mindicbnd.optfile=2;
solve mindicbnd minimizing sad using mip;
   
display sad.l,delta.l,alpha.l;

store_results(mindicbnd,'indic+bnd')

*---------------------------------------------------------
* model 4: add ordering constraint
*---------------------------------------------------------

model mindicbnd2 /mindicbnd,order/;
mindicbnd2.optfile=2;
solve mindicbnd2 minimizing sad using mip;
   
display sad.l,delta.l,alpha.l;

store_results(mindicbnd2,'indic+bnd+ord')


*---------------------------------------------------------
* model 5: bigM + order + split
*---------------------------------------------------------

scalar M 'big-M' /1000/;

free variables slack(i,k);

equation
   fitbigm(i,k)
   boundSlack1(i,k)
   boundSlack2(i,k)
;

fitbigm(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + rsplit(i,'+') - rsplit(i,'-') + slack(i,k);
boundSlack1(i,k)..  slack(i,k) =l= M*(1-delta(i,k));
boundSlack2(i,k)..  slack(i,k) =g= -M*(1-delta(i,k));

model mbigm /objsplit,fitbigm,sum1,boundslack1,boundslack2,order/;
mbigm.optfile=0;
solve mbigm minimizing sad using mip;
   
display sad.l,delta.l,alpha.l;

store_results(mbigm,'bigM+split+ord')


*---------------------------------------------------------
* model 5: bigM + order + bounding
*---------------------------------------------------------

equation 
   fitbigm2(i,k)
;

fitbigm2(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r(i) + slack(i,k);

model mbigm2 /objabs,fitbigm2,sum1,boundslack1,boundslack2,bnd1,bnd2,order/;
mbigm2.optfile=0;
solve mbigm2 minimizing sad using mip;
   
display sad.l,delta.l,alpha.l;

store_results(mbigm2,'bigM+bnd+ord')

*---------------------------------------------------------
* model 6: SOS1 + split + ord
*---------------------------------------------------------

sos1 variable sos(i,k,*);
sos.lo(i,k,'slack') = -INF;
sos.up(i,k,'slack') = INF;
sos.lo(i,k,'indic') = 0;
sos.up(i,k,'indic') = 1;

equation
   fitsos(i,k)
   sosindic
;

fitsos(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + rsplit(i,'+') - rsplit(i,'-') + sos(i,k,'slack');
sosindic(i,k).. sos(i,k,'indic') =e= delta(i,k);

model msos /objsplit,fitsos,sosindic,sum1,order/;
msos.optfile=0;
solve msos minimizing sad using mip;
   
display sad.l,delta.l,alpha.l;

store_results(msos,'sos1+split+ord')

*---------------------------------------------------------
* model 7: SOS1 + bnd + ord
*---------------------------------------------------------

equation
   fitsos2(i,k)
;

fitsos2(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r(i) + sos(i,k,'slack');

model msos2 /objabs,fitsos2,sosindic,sum1,bnd1,bnd2,order/;
msos2.optfile=0;
solve msos2 minimizing sad using mip;
   
display sad.l,delta.l,alpha.l;

store_results(msos2,'sos1+bnd+ord')

*---------------------------------------------------------
* model 8: nonconvex+split+order
*---------------------------------------------------------

variable
   r2(i,k)
;
equation
   fitnonconvex(i,k)
   nonconvex(i)
;

fitnonconvex(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r2(i,k);
nonconvex(i)..  rsplit(i,'+') - rsplit(i,'-') =e= sum(k, r2(i,k)*delta(i,k));

delta.l(i,k) = 0;

model mnonconvex /objsplit,fitnonconvex,nonconvex,sum1,order/;
mnonconvex.optfile=0;
solve mnonconvex minimizing sad using minlp;
   
display sad.l,delta.l,alpha.l;

store_results(mnonconvex,'nonconvex+split+ord')

*---------------------------------------------------------
* model 9: nonconvex+bnd+order
*---------------------------------------------------------


equation
   nonconvex2(i)
;

nonconvex2(i)..  r(i) =e= sum(k, r2(i,k)*delta(i,k));

delta.l(i,k) = 0;

model mnonconvex2 /objabs,fitnonconvex,nonconvex2,bnd1,bnd2,sum1,order/;
mnonconvex2.optfile=0;
solve mnonconvex2 minimizing sad using minlp;

store_results(mnonconvex2,'nonconvex+bnd+ord')


*---------------------------------------------------------
* heuristic
*---------------------------------------------------------



sets 
   trials /trial1*trial10/
   is(i) 'subset of points assigned to line k'
;

parameters 
   assign(i,k) 'assignment of point to line'
   assignbest(i,k) 'best assignment found'
   rand        'random value'
   nump(k)     'number of points assigned to line'
   abest(k,j)  'best LAD estimates'
   numtrial    'current trial number' 
   smad        'sum of absolute residuals for current solution'
   newsmad     'new sum of absolute deviations after reassigning points'
   smadbest    'best sum of absolute deviations found' /1e10/  
   dist(i,k)   'distance of point i to line k'
   mindist(i)  'minimum distance of point i to any line'
   numreg      'counter: number of regressions performed' /0/
   starttime
;


* regression model
equation hfit(i,k);
hfit(i,k)$assign(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + rsplit(i,'+') - rsplit(i,'-');

model mad /objsplit,hfit/;
mad.solprint = %solprint.Silent%;
mad.solvelink = %solveLink.loadLibrary%;
mad.optfile = 0;
starttime = TimeElapsed;

$ontext
  
  For each trial:
     1. randomly assign points to lines
     2. repeat until no improvement:
         a. estimate line parameters by LAD regression
         b. reassign points to closest line
         c. calculate new sum of absolute residuals, if no improvement stop inner loop

   Record best solution across all trials.

$offtext


loop(trials,

  numtrial = ord(trials);
  display numtrial;

* random assignment
   loop(i,
      rand = uniformint(1,card(k));
      assign(i,k) = ord(k)=rand;
   );

* make sure all lines have at least 2 points assigned
   nump(k) = sum(i, assign(i,k));
   abort$(smin(k,nump(k))<=card(j)) nump,"too few points. try again with different seed";

* improvement heuristic
   smad = 1e10;
   while(1,

* OLS regression  
* we do all lines in one swoop
* calling a solver is faster than calling executeTool [linalg.]OLS
      solve mad minimizing sad using lp;  
      numreg = numreg + card(k);
   
* reassign points to closest line
      dist(i,k) = abs(y(i) - alpha.l(k,'intercept') - alpha.l(k,'slope')*x(i));
      mindist(i) = smin(k, dist(i,k));
      assign(i,k) = 0;
      loop(i,         
         loop(k$(dist(i,k) = mindist(i)),
            assign(i,k) = 1;
            break;
         );
      );

      newsmad = sum((i,k)$assign(i,k),abs(y(i) - alpha.l(k,'intercept') - alpha.l(k,'slope')*x(i)));
      display newsmad;
      abort$(newsmad > smad+0.01) "we should not deteriorate, something is wrong",newsmad,smad;
      if(newsmad < smad-0.01,
         smad = newsmad;
      else
         display "no improvement, stop improvement loop";
         break;
      );

   );

   if(smad < smadbest-0.01,
      smadbest = smad;
      assignbest(i,k) = assign(i,k); 
      abest(k,j) = alpha.l(k,j);
      display ">>>>",smadbest,assignbest,abest;
   );

);

results('heuristic','obj') = smadbest;
results('heuristic','time') = timeElapsed-starttime;
results('heuristic','numreg') = numreg;
display results;


*---------------------------------------------------------
* sort heuristic solution by constant term
*---------------------------------------------------------
set unsorted(k);

parameter
   sortedassign(i,k) 'sorted assignment'
   minintercept      'sort on intercept' 
;

alias (k,kk);

unsorted(k) = yes;

loop(kk,
   minintercept = smin(unsorted(k), abest(k,'intercept'));
   loop(k$(unsorted(k) and abest(k,'intercept')=minintercept),
      sortedassign(i,kk) = assignbest(i,k);
      unsorted(k) = no;
   );
);
display abest,assignbest,sortedassign;


*---------------------------------------------------------
* nonconvex + restart
*---------------------------------------------------------

delta.l(i,k) = sortedassign(i,k);

$echo loadmipsol 1 > xpress.op3
$echo mipstart 1   > gurobi.op3

mnonconvex.optfile = 3;
solve mnonconvex minimizing sad using minlp;

store_results(mnonconvex,'nonconvex+split+ord+mipstart')

*--------------------------------------------------------
* export data
*--------------------------------------------------------

parameter plotdata(i,*) 'for use in R';
plotdata(i,'x') = x(i);
plotdata(i,'y') = y(i);
plotdata(i,'assign') = round(sum(k, delta.l(i,k)*ord(k)));
display plotdata;


