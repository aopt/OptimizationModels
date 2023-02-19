$onText


    Find a maximal subset of points such that the distance between the
    selected points is larger than some given value.
    

$offText

*-----------------------------------------------------------
* options
*-----------------------------------------------------------

option mip = cplex, miqcp = cplex, threads=0;

*-----------------------------------------------------------
* data
*-----------------------------------------------------------

set
   i 'all points' /i1*i50/
   c '2d coordinates' /x,y/ 
;
alias(i,j);

parameter p(i,c) 'coordinates of points';
p(i,c) = uniform(0,100);
display$(card(p)<=5) p;

scalar mindist /50/;

*-----------------------------------------------------------
* derived data
*-----------------------------------------------------------

set ij(i,j) 'lower triangular part';
ij(i,j) = ord(i) < ord(j);

parameter dist(i,j) 'distances';
dist(ij(i,j)) = sqrt(sum(c,sqr(p(i,c)-p(j,c))));

*------------------------------------------------
* reporting macros
*------------------------------------------------

parameter results(*,*);

acronym TimeLimit;
acronym Optimal;

* macros for reporting
$macro report(m,label) \
    results('n',label) = card(i); \
    results('rows',label) = m.numequ; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('status',label)$(m.solvestat=3) = TimeLimit; \
    results('obj',label) = z.l; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd; \
    display results;

*-----------------------------------------------------------
* MIQCP model
*-----------------------------------------------------------

binary variable x(i) 'selected points';
variable z 'objective variable';

equations
   obj      'objective'
   emindist 'minimum distance constraint'
;

obj.. z =e= sum(i, x(i));
emindist(ij(i,j))..  dist(i,j) =g= mindist*x(i)*x(j);

model m /all/;
solve m maximizing z using miqcp;
report(m,'miqcp')

*-----------------------------------------------------------
* linearized MIP model
*-----------------------------------------------------------

equations
  emindist2 'linearized minimum distance constraint'
;
  
emindist2(ij(i,j))..  dist(i,j) =g= mindist*(x(i)+x(j)-1);

model m2 /obj,emindist2/;
solve m2 maximizing z using mip;
report(m2,'mip')

*-----------------------------------------------------------
* frugal MIP model
*-----------------------------------------------------------

equations
  emindist3 "if distance>mindist, don't allow both in solution"
;
  
emindist3(ij(i,j))$(dist(ij)<mindist)..
      x(i)+x(j) =l= 1;

model m3 /obj,emindist3/;
solve m3 maximizing z using mip;
report(m3,'mip2')


*-----------------------------------------------------------
* The solution is not unique.
* Find number of optimal integer solutions using
* the solution pool.
*-----------------------------------------------------------

m3.optfile=1;
solve m3 maximizing z using mip;


Sets
   index0 'solution pool names' /soln_m3_p1*soln_m3_p10000/ 
   index(index0) 'read from gdx file'  
;
parameter objs(index0) 'objectives in solution pool';
scalar numSolutions 'number of solutions in solution poool';
execute_load "solutions.gdx",index,objs=z;
numSolutions = card(index);
display numSolutions,index,objs;


$onecho > cplex.opt
SolnPoolAGap = 0.5
SolnPoolIntensity = 4
PopulateLim = 10000
SolnPoolPop = 2
solnpoolmerge solutions.gdx
$offecho


