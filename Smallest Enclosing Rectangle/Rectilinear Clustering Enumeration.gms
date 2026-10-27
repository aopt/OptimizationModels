$onText

   cluster points using axis-aligned rectangles
   
   1. Enumerate all rectangles
   2. Set Covering type of model

$offText


*---------------------------------------------------------------
* Settings
*---------------------------------------------------------------

option seed=12345;

*---------------------------------------------------------------
* data
*---------------------------------------------------------------

scalars
   maxsize 'size of the outer box' / 10 /
   k 'number of rectangles'   / 5 /
;

sets
   i   'points' /point1*point50/
   r0  'base set rectangles' /rectangle1*rectangle100000/
   c   'coordinates' /x,y/
   lu  'lower/upper values' /min,max/
;

parameter p(i,c) 'points';
p(i,c) = uniform(0,maxsize);
display p;


*---------------------------------------------------------------
* enumeration algorithm
*---------------------------------------------------------------

scalars
    n 'number of points'
    nr 'number of possible rectangles'
;
n = card(i);

sets
  r(r0) 'rectangles'
  contain(i,r0) 'point i is in rect r'
;

Parameter
  rect(r0,c,lu) 'rectangle coordinates'
;

* create dense data structure for export to Python
p(i,c)$(p(i,c)=0) = EPS;

EmbeddedCode Python:

#
# number of points
#

n = int(list(gams.get("n"))[0])

#
# get points and store as list of tuples (id,x,y)
#

pgen = gams.get("p",keyFormat=KeyFormat.FLAT) 
points=[]
for i in range(n):
    px = next(pgen)
    py = next(pgen)
    points.append((px[0],px[2],py[2]))

#
# import enumeration code
#

import sys
sys.path.insert(0,'')

import renumerate as renum

print(f"renumerate {renum.version}")

#
# start working....
#
print(f"points:{n}")
rects, mapped_points = renum.find_all_boundary_rectangles(points)
print(f"rectangles:{len(rects)}")

#
# export to GAMS
#
gams.set('nr',[len(rects)])
gams.set('r',list(rects.keys()))  
gams.set('contain', [(p,r) for r in rects.keys() for p in rects[r]['covered_points']] )

coord = []
for r in rects:
    bounds = rects[r]['bounds']
    coord.append((r,'x','min',bounds['x_min']))
    coord.append((r,'x','max',bounds['x_max']))
    coord.append((r,'y','min',bounds['y_min']))
    coord.append((r,'y','max',bounds['y_max']))
gams.set('rect',coord)  


endEmbeddedCode nr,r,contain,rect

abort$(nr>card(r0)) "set r0 is too small to store all rectangles";

display nr;

*---------------------------------------------------------------
* calculate area and perimeter
*---------------------------------------------------------------

Parameters
    Area(r0) 
    Perimeter(r0)
;

Area(r) = prod(c,rect(r,c,'max')-rect(r,c,'min'));
Perimeter(r) = 2*sum(c,rect(r,c,'max')-rect(r,c,'min'));

*---------------------------------------------------------------
* optimization
*---------------------------------------------------------------

binary variable
    select(r0)        'rectangle selection'
;
variables
    totalArea        'objective'
    totalPerimeter   'objective' 
;

Equations
    obj1
    obj2
    cover(i)
    count
;

obj1.. totalArea =e= sum(r, Area(r)*select(r));
obj2.. totalPerimeter =e= sum(r, Perimeter(r)*select(r));

cover(i)..  sum(contain(i,r), select(r)) =g= 1;

count.. sum(r, select(r)) =e= k;

model m1 /all-obj2/;
model m2 /all-obj1/;

solve m1 using mip minimizing totalArea;