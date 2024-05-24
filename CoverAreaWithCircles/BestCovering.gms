$onText

Place 25 circles (size is endogenous) on a [0,250]x[0,100] square area such that
circles don't overlap and the total area covered is maximized.

Very tough little non-convex NLP.

            Obj
MultiStart  91.183   (1015 trials, w/o symmetry constraint)
Baron       91.183   (no improvement, 1 hour, with symmetry breaker)

Reference:
https://yetanothermathprogrammingconsultant.blogspot.com/2024/05/another-very-small-but-very-difficult.html

$offText

*-------------------------------------------------------------------
* size of problem
*-------------------------------------------------------------------

Set i 'circles' /circle1*circle25/;
alias (i,j);

set ij(i,j) 'compare circles i and j: only i<j';
ij(i,j) = ord(i) < ord(j);

scalars
  sizeX 'size of area' /250/
  sizeY 'size of area' /100/
;

*-------------------------------------------------------------------
* NLP Model
*-------------------------------------------------------------------

positive variables
   x(i) 'x-coordinate'
   y(i) 'y-coordinate'
   r(i) 'radius'
;

x.up(i) = sizeX;
y.up(i) = sizeY;
r.up(i) = min(sizeX,sizeY)/2;

variable z 'covered area (% of area)';

equations
    cover  'calculate total area covered'
    no_overlap(i,j) 'circles cannot overlap'
    xlo(i) 'stay inside [0,250]'
    xup(i) 'stay inside [0,250]'
    ylo(i) 'stay inside [0,100]'
    yup(i) 'stay inside [0,100]'
    symmetry(i) 'symmetry breaker'
;


cover.. z =e= 100*sum(i, pi*sqr(r(i))) / (sizeX*sizeY);
no_overlap(ij(i,j)).. sqr(x(i)-x(j)) + sqr(y(i)-y(j)) =g= sqr(r(i)+r(j));
xlo(i).. x(i) - r(i) =g= 0;
xup(i).. x(i) + r(i) =l= sizeX;
ylo(i).. y(i) - r(i) =g= 0;
yup(i).. y(i) + r(i) =l= sizeY;
symmetry(i-1) .. r(i) =l= r(i-1);


* improves logging of gap, but may slow things down
* (nl obj becomes a constraint)
z.up = 100;


model circlesw  'with symmetry' /all/ ;
model circleswo 'w/o symmetry' /circlesw - symmetry/ ;


*-------------------------------------------------------------------
* select algorithm
*-------------------------------------------------------------------

$set MultiStart 1
$set Global     0


*-------------------------------------------------------------------
* multistart approach using local NLP solver
* best used without symmetry breaker
* we get a solution:  91.183 @ trial1015
*-------------------------------------------------------------------

$ifThen %MultiStart% == 1

set k /trial1*trial1015/;
option qcp = conopt;
parameter best(i,*) 'best solution';
scalar zbest 'best objective' /0/;
parameter trace(k) 'keep track of improvements';
circleswo.solprint = %solprint.Silent%;
circleswo.solvelink = 5;
* abort expensive solves
option reslim = 10; 
loop(k,
     x.l(i) = uniform(10,sizeX-10);
     y.l(i) = uniform(10,sizeY-10);
     r.l(i) = uniform(10,40);
     
     solve circleswo maximizing z using qcp;
     if(circleswo.modelstat=%modelStat.locallyOptimal% and z.l>zbest,
         zbest = z.l;
         best(i,'x') = x.l(i);
         best(i,'y') = y.l(i);
         best(i,'r') = r.l(i);
         trace(k) = z.l;
    );
 );

display zbest,best,trace;

* ugly code to sort on r so we can use symmetry constraint in
* subsequent solve.
set rem(i) 'remaining';
rem(i) = yes;
option strictSingleton = 0;
singleton set cur(i) 'current';
scalar largest;
loop(i,
   largest = smax(rem,best(rem,'r'));
   cur(rem) = best(rem,'r')=largest;
   x.l(i) = best(cur,'x');
   y.l(i) = best(cur,'y');
   r.l(i) = best(cur,'r');
   rem(cur) = no;
);
z.l = zbest;

* reset to default for next solves
circleswo.solprint = %solprint.On%;


$endIf


*-------------------------------------------------------------------
* Global NLP solver
* with or without symmetry breaker
*-------------------------------------------------------------------

$ifThen %Global% == 1

option qcp=baron, reslim=3600;
option threads=-1;
solve circlesw maximizing z using qcp;

$endIf

*-------------------------------------------------------------------
* Reporting
*-------------------------------------------------------------------

display z.l;

parameter results(i,*);
results(i,'x') = x.l(i);
results(i,'y') = y.l(i);
results(i,'r') = r.l(i);
display results;

