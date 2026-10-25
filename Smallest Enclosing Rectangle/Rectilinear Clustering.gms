$onText

   cluster points using axis-aligned rectangles
   
   Two implementations:
   
      minimize area (nonconvex MIQCP)
      minimize perimeter (linear MIP)

$offText


*---------------------------------------------------------------
* Settings
*---------------------------------------------------------------

option seed=12345;

option mip = copt;
option miqcp = copt;


*---------------------------------------------------------------
* data
*---------------------------------------------------------------

scalars
   maxsize 'size of the outer box' / 10 /
;

sets
   i   'points' /point1*point50/
   k   'rectangles' /rectangle1*rectangle5/
   c   'coordinates' /x,y/
   lu  'lower/upper values' /min,max/
;

parameter p(i,c) 'points';
p(i,c) = uniform(0,maxsize);

option k:0,p:8;
display k,p;

*---------------------------------------------------------------
* derived data
*---------------------------------------------------------------

* bounding box for data points
parameter box(c,lu) 'min/max values';
box(c,'min') = smin(i, p(i,c));
box(c,'max') = smax(i, p(i,c));

display box;

*---------------------------------------------------------------
* non-convex quadratic and linear model 
*---------------------------------------------------------------

binary variables delta(i,k) 'assign point to rectangle';

positive variables
    rect(k,c,lu) 'rectangle coordinates'
    d(k,c)  'width and length of rectangle'
;

variables
   totalArea      'objective (nonconvex quadratic)'
   totalPerimeter 'objectic (linear)'
;

* bounds
rect.lo(k,c,lu) = box(c,'min'); 
rect.up(k,c,lu) = box(c,'max');
d.up(k,c) = box(c,'max')-box(c,'min');

Equations
   obj1                'nonconvex quadratic: min sum area'
   obj2                'linear: min sum perimeter'
   inside_min(i,k,c)   'point i is inside rectangle k'
   inside_max(i,k,c)   'point i is inside rectangle k'
   inside_one(i)       'each point must be inside one rectangle'
   calc_d(k,c)         'calc height/width of rectangle'
   extra(k)            'symmetry breaker'
;

obj1.. totalArea =e= sum(k, prod(c,d(k,c)));
obj2.. totalPerimeter =e= sum(k, 2*sum(c,d(k,c)));

inside_min(i,k,c).. rect(k,c,'min') =l= delta(i,k)*p(i,c) + (1-delta(i,k))*box(c,'max'); 
inside_max(i,k,c).. rect(k,c,'max') =g= delta(i,k)*p(i,c) + (1-delta(i,k))*box(c,'min');

inside_one(i).. sum(k, delta(i,k)) =e= 1;

calc_d(k,c).. d(k,c) =e= rect(k,c,'max') - rect(k,c,'min');

extra(k+1).. rect(k,'x','min') =l= rect(k+1,'x','min');

model mArea      'quadratic' / all - obj2 /;
model mPerimeter 'linear'    / all - obj1 /;

*---------------------------------------------------------------
* Solve and save results 
*---------------------------------------------------------------

set dummy /min,max,len,points,count,area,perimeter/;

parameter
    results(*,*,*,*) 'by cluster'
    assign(*,k)      'assignment=round(delta)'
    rect1            'saved version for postprocessing'
    rect2            'saved version for postprocessing' 
;

option assign:0;

solve mArea minimizing totalArea using miqcp;
abort$(mArea.solvestat<>%solveStat.normalCompletion%) "Abnormal completion";
assign(i,k) = round(delta.l(i,k));
assign('count',k) = sum(i,assign(i,k));
display delta.l, assign, rect.l, d.l, totalArea.l; 

rect1(k,c,lu) = rect.l(k,c,lu);

results('min area obj',k,c,'min') = rect.l(k,c,'min');
results('min area obj',k,c,'max') = rect.l(k,c,'max');
results('min area obj',k,c,'len') = d.l(k,c);
results('min area obj',k,'','points') = sum(i$(delta.l(i,k)>0.5),1);
results('min area obj',k,'','area') = prod(c,d.l(k,c));
results('min area obj',k,'','perimeter') = 2*sum(c,d.l(k,c));
results('min area obj','total','','points') = sum((i,k)$(delta.l(i,k)>0.5),1);
results('min area obj','total','','area') = sum(k,prod(c,d.l(k,c)));
results('min area obj','total','','perimeter') = sum(k,2*sum(c,d.l(k,c)));

solve mPerimeter minimizing totalPerimeter using mip;
abort$(mPerimeter.solvestat<>%solveStat.normalCompletion%) "Abnormal completion";
assign(i,k) = round(delta.l(i,k));
assign('count',k) = sum(i,assign(i,k));
display delta.l, assign, rect.l, d.l, totalPerimeter.l;

rect2(k,c,lu) = rect.l(k,c,lu);

results('min perim obj',k,c,'min') = rect.l(k,c,'min');
results('min perim obj',k,c,'max') = rect.l(k,c,'max');
results('min perim obj',k,c,'len') = d.l(k,c);
results('min perim obj',k,'','points') = sum(i$(delta.l(i,k)>0.5),1);
results('min perim obj',k,'','area') = prod(c,d.l(k,c));
results('min perim obj',k,'','perimeter') = 2*sum(c,d.l(k,c));
results('min perim obj','total','','points') = sum((i,k)$(delta.l(i,k)>0.5),1);
results('min perim obj','total','','area') = sum(k,prod(c,d.l(k,c)));
results('min perim obj','total','','perimeter') = sum(k,2*sum(c,d.l(k,c)));

option results:3;
display results;