$ontext

   Maximum Area in Histogram

   Four formulations
     1. Nonconvex MIQP model A
     2. Nonconvex MIQP model A + ordering constraint
     3. Nonconvex MIQP model B
     4. Linear    MIP  model B

   Reference:
   https://yetanothermathprogrammingconsultant.blogspot.com/2020/08/largest-rectangular-area-in-histogram.html


   erwin@amsterdamoptimization.com

$offtext



*---------------------------------------------------------------------
* data
*---------------------------------------------------------------------

set i 'bars' /i1*i100/;

parameter hist(i) 'histogram data';
hist(i) = uniform(0,100);

scalar maxhist 'heighest bar';
maxhist = smax(i, hist(i));

display i,hist,maxhist;


*-------------------------------------------------------
* reporting macros
*-------------------------------------------------------

acronym TimeLimit;
acronym Optimal;
acronym Error;

parameter results(*,*);
$macro report(m,label)  \
    results('points',label) = card(i); \
    results('vars',label) = m.numVar; \
    results('  discr',label) = m.numDVar; \
    results('equs',label) = m.numEqu; \
    results('status',label) = Error; \
    results('status',label)$(m.solvestat=1) = Optimal; \
    results('status',label)$(m.solvestat=3) = TimeLimit; \
    results('obj',label) = area.l; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd; \
    results('gap%',label)$(m.solvestat=3) = 100*abs(m.objest - m.objval)/abs(m.objest); \
    display results;


*---------------------------------------------------------------------
* Model 1: Non-convex MIQP model A
*---------------------------------------------------------------------

positive variable
    start   'first selected bar'
    width   'number of selected bars'
    height  'shortest selected bar'
;
start.lo=1;
start.up = card(i);
width.up = card(i);
height.up = smax(i, hist(i));

binary variables
   select(i) 'selection of bar'
   lr(i)     'unselected bars are left (lr=0) or right (lr=1) of selection'
;

variable area 'width*height';

equations
   start1(i)   'start>=...'
   start2(i)   'start+width<=...'
   countwidth  'width of rectangle'
   maxheight   'height of rectangle'
   obj         'quadratic objective'
   limit       'limit on start+width'
;

$ontext


  start equations:
  select(i)=0 => start>=i+1 OR start+width<=i
  --> start >= i + 1 - M*select(i) -M*lr(i)
      start+width <= i + M*select(i) + M*(1-lr(i))

  height equation:
  select(i)=1 => height <= hist(i)
  -->  height <= hist(i) + M*(1-select(i))

$offtext

start1(i).. start =g= ord(i)+1-card(i)*select(i)-card(i)*lr(i);
start2(i).. start+width =l= ord(i)+card(i)*select(i)+card(i)*(1-lr(i));

countWidth.. sum(i, select(i)) =e= width;
maxHeight(i).. height =l= hist(i)+(maxhist-hist(i))*(1-select(i));

obj.. area =e= height*width;
limit.. start+width-1 =l= card(i);

model m1 /all/;
option miqcp = cplex, optcr = 0, threads = 8;
m1.optfile=1;
solve m1 maximizing area using miqcp;

display select.l,lr.l,start.l,width.l,height.l,area.l;
report(m1,"m1")

$onecho > cplex.opt
optimalityTarget=3
solveFinal=0
$offecho


*---------------------------------------------------------------------
* Model 2: Non-convex MIQP model A + ordering constraint
*---------------------------------------------------------------------

equation order;

order(i-1).. lr(i) =g= lr(i-1);

model m2 /all/;
m2.optfile=1;
solve m2 maximizing area using miqcp;

display select.l,lr.l,start.l,width.l,height.l,area.l;
report(m2,"m2")


*---------------------------------------------------------------------
* Model 3: Non-convex MIQP model B
*---------------------------------------------------------------------

binary variable
    starti(i)   'first selected bar'
    select(i)   'bar is selected'
;


equations
   bndstart     'select(i)>select(i-1) ==> starti(i)=1'
   maxstart     'one start allowed'
   obj3
;

bndstart(i).. starti(i) =g= select(i)-select(i-1);
maxstart.. sum(i, starti(i)) =l= 1;
obj3..  area =e= sum(i, select(i)*height);

model m3 /bndstart,maxstart,maxHeight,obj3/;
m3.optfile=1;
solve m3 maximizing area using miqcp;

display select.l,starti.l,height.l,area.l;
report(m3,"m3")

*---------------------------------------------------------------------
* Model 4: MIP based on model 3
*---------------------------------------------------------------------

positive variable
  adjHeight(i) 'adjusted height: heigth*selected(i)'
;

equations
   bndAdjHeight1  'linearization of heigth*selected(i)'
   bndAdjHeight2  'linearization of heigth*selected(i)'
   bndAdjHeight3  'linearization of heigth*selected(i)'
   obj4           'linearized objective'
;


bndAdjHeight1(i).. adjHeight(i) =l= select(i)*hist(i);
bndAdjHeight2(i).. adjHeight(i) =l= height;
bndAdjHeight3(i).. adjHeight(i) =g= height-maxhist*(1-select(i));
obj4..  area =e= sum(i, adjHeight(i));

model m4 /bndstart,maxstart,maxHeight,bndAdjHeight1,bndAdjHeight2,
         bndAdjHeight3,obj4/;
solve m4 maximizing area using mip;

display select.l,starti.l,height.l,adjHeight.L,area.l;
report(m4,"m4")
