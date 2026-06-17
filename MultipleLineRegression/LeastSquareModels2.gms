$ontext

   Multiple-line regression
 
   We have 3 unknown lines and 40 points. We want to assign each point to a line and 
   estimate the line parameters such that the total sum of squared residuals is minimized. 
   
   We use a heuristic to find a good starting solution.

   Versions:
      model 1, mindic1: indicator constraints (convex MIQP)
      model 2, mindic2: indicator constraints (convex MIQP) + ordering constraint
      model 3, bigM:    binary variables with big M constraint + ordering constraint 
      model 4: mSOS:    SOS1 constraints (convex MIQP) + ordering constraint
      model 5: mnonconvex: nonconvex quadratic model + ordering constraint
      model 6: heuristic using standard OLS       

   erwin@amsterdamoptimization.com

$offtext

option qcp=cplex,miqcp=cplex,minlp=baron;
option qcp=xpress,miqcp=xpress,minlp=xpress;
option qcp=gurobi,miqcp=gurobi,minlp=gurobi;

option reslim=1000;


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
* model 1: indicator constraints (convex MIQP)
*---------------------------------------------------------


free variables
   ssq          'objective: sum of squares'
   r(i)         'residuals'
   alpha(k,j)   'coefficients to estimate for each line'
;

binary variable delta(i,k) 'assignment of point to line';

equations
   obj        'quadratic: min sum of squared errors' 
   fit(i,k)   'linear fit'     
   sum1       'assignment'
;

obj..          ssq =e= sum(i, sqr(r(i)));
fit(i,k)..     y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r(i);
sum1(i)..      sum(k, delta(i,k)) =e= 1;

* gams does not support indicator constraint
* this is somewhat of a hack (with quite a few issues) 
* ignore the messages:
* --- Found infeasibility of 110.693 (larger than tolerance 1e-06).
* --- To improve solution quality, try 'numericalemphasis 1' or fix listed issues of 'datacheck 2'.

$echo indic fit(i,k)$delta(i,k)  1 > cplex.opt
$echo indic fit(i,k)$delta(i,k)  1 > xpress.opt
$echo indic fit(i,k)$delta(i,k)  1 > gurobi.opt

model mindic1 /obj,fit,sum1/;
mindic1.optfile=1;
solve mindic1 minimizing ssq using miqcp;

display ssq.l,delta.l,alpha.l; 

store_results(mindic1,'indic')

*---------------------------------------------------------
* model 2: indicator constraints + ordering constraint
*---------------------------------------------------------

equation order(k)  'order by intercept';

order(k+1)..   alpha(k,'intercept') =l= alpha(k+1,'intercept');

model mindic2 /mindic1,order/;
mindic2.optfile=1;
solve mindic2 minimizing ssq using miqcp;

display alpha.l;

store_results(mindic2,'indic+ord')

*---------------------------------------------------------
* model 3: binary variables
* warning: we cannot establish good bounds for M
*---------------------------------------------------------

scalar M 'big-M' /1000/;

variable
   slack(i,k)
;
equation
   fitM(i,k)
   boundSlack1(i,k)
   boundSlack2(i,k)
;

fitM(i,k)..     y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r(i) + slack(i,k);
boundSlack1(i,k)..  slack(i,k) =l= M*(1-delta(i,k));
boundSlack2(i,k)..  slack(i,k) =g= -M*(1-delta(i,k));


model mbigM /obj,fitM,boundSlack1,boundSlack2,sum1,order/;
mbigM.optfile=0;
solve mbigM minimizing ssq using miqcp;

store_results(mbigM,'bigM+ord')

*---------------------------------------------------------
* model 4: SOS1 sets
* implement indicator constraints by saying that
* delta(i,k) = 1 or r(i,k) <> 0 but not both
*---------------------------------------------------------

set sos_index / indicator, slack /;

sos1 variable sos(i,k,sos_index);
sos.lo(i,k,'slack') = -INF;
sos.up(i,k,'slack') = +INF;
sos.lo(i,k,'indicator') = 0;
sos.up(i,k,'indicator') = 1;

equations
   fitSOS(i,k)
   indicSOS(i,k)
;

fitSOS(i,k).. y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r(i) + sos(i,k,'slack');
indicSOS(i,k).. delta(i,k) =e= sos(i,k,'indicator');

model mSOS /obj,fitSOS,indicSOS,sum1,order/;
mSOS.optfile=0;
solve mSOS minimizing ssq using miqcp;

store_results(mSOS,'SOS1+ord')

*---------------------------------------------------------
* model 5: nonconvex model
*---------------------------------------------------------

variable 
   rho(i,k)
;
equations
   fitRho(i,k)
   nonconvex(i)
;

fitRho(i,k).. y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + rho(i,k);
nonconvex(i).. r(i) =e= sum(k, rho(i,k)*delta(i,k));

* reset values (baron would pick them up)
delta.l(i,k)=0;
alpha.l(k,j)=0;
r.l(i)=0;

model mnonconvex /obj,fitRho,nonconvex,sum1,order/;
mnonconvex.optfile=0;
solve mnonconvex minimizing ssq using minlp;

store_results(mnonconvex,'nonconvex+ord')

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
   abest(k,j)  'best OLS estimates'
   numtrial    'current trial number' 
   sosq        'sum of squared residuals for current solution'
   newsosq     'new SoS after reassigning points'
   sosqbest    'best SoS found' /1e10/  
   dist(i,k)   'distance of point i to line k'
   mindist(i)  'minimum distance of point i to any line'
   numreg      'counter: number of regressions performed' /0/
   starttime
;


* regression model
equation hfit(i,k);
hfit(i,k)$assign(i,k)..  y(i) =e= alpha(k,'intercept') + alpha(k,'slope')*x(i) + r(i);

model ols /obj,hfit/;
ols.solprint = %solprint.Silent%;
ols.solvelink = %solveLink.loadLibrary%;
ols.optfile = 0;
starttime = TimeElapsed;

$ontext
  
  For each trial:
     1. randomly assign points to lines
     2. repeat until no improvement:
         a. estimate line parameters by OLS regression
         b. reassign points to closest line
         c. calculate new sum of squared residuals, if no improvement stop inner loop

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
   sosq = 1e10;
   while(1,

* OLS regression  
* we do all lines in one swoop
* calling a solver is faster than calling executeTool [linalg.]OLS
      solve ols minimizing ssq using qcp;  
      numreg = numreg + card(k);
   
* reassign points to closest line
      dist(i,k) = sqr(y(i) - alpha.l(k,'intercept') - alpha.l(k,'slope')*x(i));
      mindist(i) = smin(k, dist(i,k));
      assign(i,k) = 0;
      loop(i,         
         loop(k$(dist(i,k) = mindist(i)),
            assign(i,k) = 1;
            break;
         );
      );

      newsosq = sum((i,k)$assign(i,k),sqr(y(i) - alpha.l(k,'intercept') - alpha.l(k,'slope')*x(i)));
      display newsosq;
      abort$(newsosq > sosq+0.01) "we should not deteriorate, something is wrong",newsosq,sosq;
      if(newsosq < sosq-0.01,
         sosq = newsosq;
      else
         display "no improvement, stop improvement loop";
         break;
      );

   );

   if(sosq < sosqbest-0.01,
      sosqbest = sosq;
      assignbest(i,k) = assign(i,k); 
      abest(k,j) = alpha.l(k,j);
      display ">>>>",sosqbest,assignbest,abest;
   );

);

results('heuristic','obj') = sosqbest;
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

$onecho > cplex.op2
mipstart 1   
$offecho
$onecho > xpress.op2
loadmipsol 1   
$offecho
$onecho > gurobi.op2
mipstart 1   
$offecho

mnonconvex.optfile = 2;
solve mnonconvex minimizing ssq using miqcp;

store_results(mnonconvex,'nonconvex+ord+mipstart')


*--------------------------------------------------------
* export data
*--------------------------------------------------------

parameter plotdata(i,*) 'for use in R';
plotdata(i,'x') = x(i);
plotdata(i,'y') = y(i);
plotdata(i,'color') = round(sum(k, delta.l(i,k)*ord(k)));
display plotdata;


