$ontext

  portfolio models:

    min risk, s.t. returns >= MINRET   (QP)

    max returns, s.t. risk <= MAXRISK   (QCP)

  Does this makes a difference in performance?

  We compare a continuous portfolio model and a cardinality
  constrained model. The results are a bit inconclusive.
  For the MIP, the QP model seems to be faster.

  Reference:
  https://yetanothermathprogrammingconsultant.blogspot.com/2021/06/portfolio-optimization-with-risk-as.html

  erwin@amsterdamoptimization.com

$offtext


$set script     script.R
$set gdx        data.gdx
$set rcommand   '"c:\Program Files\R\R-4.0.3\bin\Rscript.exe" --vanilla %script%'

$onecho > %script%
options(echo=TRUE)
library(pprobeData)
library(Matrix)
library(reshape2)
library(gdxrrw)

# data in pprobeData:
#    xassetPrices
#    xassetLogReturns
# I rescale the risk/return a bit

r <- xassetLogReturns[1:1000,]
mu <- colSums(r)
summary(mu)
# make sure the Covariance matrix is PD
covmat <- 1000.0*as.matrix(nearPD(cov(r))$mat)
summary(as.vector(covmat))


#
# organize data to be exported to GAMS
#
mudf <- data.frame(
    as.factor(names(mu)),
    mu
)
names(mudf) <- c("i","mu")
attr(mudf,"symName") = "mu"
attr(mudf,"domains") = c("i")
attr(mudf,"domInfo") = "relaxed"


covdf <- melt(covmat)
covdf2 <- data.frame(
    as.factor(covdf$Var1),
    as.factor(covdf$Var2),
    covdf$value
)
names(covdf2) <- c("i","j","cov")
attr(covdf2,"symName") = "cov"
attr(covdf2,"domains") = c("i","i")
attr(covdf2,"domInfo") = "relaxed"

wgdx.lst("%gdx%",mudf,covdf2)
$offecho


$call '%rcommand%'

set dummy 'for ordering' /MinReturn,MaxRisk/;

set i;
parameters
    mu(i)      'returns'
    cov(i,i)   'covariance matrix'
;

$gdxin  %gdx%
$loaddc i<mu.dim1 mu cov

display i;

alias(i,j);

*----------------------------------------------
* models
*----------------------------------------------

scalars
   minret  'minimum return' /0.5/
   maxrisk  'maximum allowed risk'
   num    'number of assets we can choose' /10/
;

positive variable x(i) 'fraction to invest';
binary variable delta(i);
variable z 'objective';

equation
    qobj         'quadratic objective'
    lobj         'linear objective'
    budget       'allocations sum up to 1'
    minreturn    'minimum return constraint (linear)'
    emaxrisk     'maximum risk constraint (quadratic)'
    notused      'delta=0 => x=0'
    numassets    'number of assets in portfolio'
;

* objectives
qobj..
   z =e= sum((i,j),x(i)*cov(i,j)*x(j));
lobj..
   z =e= sum(i,mu(i)*x(i));

* return/risk constraints
minreturn..  sum(i, mu(i)*x(i)) =g= minret;
emaxrisk..  sum((i,j),x(i)*cov(i,j)*x(j)) =l= maxrisk;

* allocations are fractions
budget.. sum(i, x(i)) =e= 1;

* cardinality constraints
notused(i).. x(i) =l= delta(i);
numassets.. sum(i, delta(i)) =e= num;


* continuous models
model m1 /qobj,budget,minreturn/;
model m3 /lobj,budget,emaxrisk/;

* cardinality constrained models
model m1mip /qobj,budget,minreturn,notused,numassets/;
model m3mip /lobj,budget,emaxrisk,notused,numassets/;


*----------------------------------------------
* reporting
*----------------------------------------------

acronym Optimal,NonOptimal;

parameter results(*,*);
$macro report(m,label,ex,exval)  \
    results(ex,label) = exval;   \
    results('num assets',label) = card(i); \
    results('vars',label) = m.numVar; \
    results('  discr',label) = m.numDVar; \
    results('equs',label) = m.numEqu; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('status',label)$(m.solvestat<>1) = NonOptimal; \
    results('obj',label) = z.l; \
    results('time',label) = m.resusd; \
    results('nodes',label)$(m.nodusd<>NA) = m.nodusd; \
    results('iterations',label) = m.iterusd;


*----------------------------------------------
* solve
*----------------------------------------------

option qcp=cplex,miqcp=cplex,optcr=0,threads=8, bratio=1;

solve m1 minimizing z using qcp;
report(m1,'M1','MinReturn',minret)

maxrisk = z.l;
solve m3 maximizing z using qcp;
report(m3,'M3','MaxRisk',maxrisk)

display results;

solve m1mip minimizing z using miqcp;
display x.l,delta.l,z.l;
report(m1mip,'M1mip','MinReturn',minret)

maxrisk = z.l;
solve m3mip maximizing z using miqcp;
display x.l,delta.l,z.l;
report(m3mip,'M3mip','MaxRisk',maxrisk)

display results;

