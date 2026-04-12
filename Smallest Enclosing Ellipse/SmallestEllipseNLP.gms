$onText

  Solve smallest ellipse problem using an NLP solver
  Use same starting point as smallest circle problem
  
$offText

option nlp = conopt;
 
*----------------------------------------------------------------------
* data
*----------------------------------------------------------------------

set
  i 'points' /point1*point50/
  c  'coordinates' /x,y/
  h(i) 'subset: convex hull'
;

parameter p(i,c) 'points';


$onEmbeddedCode Python:

# returns
#    points p(i,c) drawn from bivariate normal distribution 
#    subset h(i)   points that are part of the convex hull

import numpy as np
import scipy as sp

seti = list(gams.get("i"))
n = len(seti)
setc = list(gams.get("c"))

seed = 1234
print(f"{n=} {seed=}")

μ = np.array([0, 0])
Σ = np.array([[5, 4.5], [4.5, 6]])

rng = np.random.default_rng(seed)
points = rng.multivariate_normal(μ, Σ, size=n)

gams.set("p",[(seti[i],setc[j],points[i,j]) for i in range(n) for j in range(2)])

ipoints2 = sp.spatial.ConvexHull(points).vertices
gams.set("h",[(seti[i]) for i in ipoints2])

$offEmbeddedCode p h

display p,h;

set j(i) 'used points';
*j(i) = yes;
j(h) = yes;


*----------------------------------------------------------------------
* initial circle
*----------------------------------------------------------------------

alias (c,cc);
parameter
   ic(c) 'initial center'
   ir2   'squared initial radius'
;

ic(c) = sum(j,p(j,c))/card(j);
ir2 = smax(j,sum(c, sqr(p(j,c)-ic(c))));
display ic,ir2;

*----------------------------------------------------------------------
* formulation 1
* max det(A)
* s.t. (p-c)'A(p-c) <= 1
*----------------------------------------------------------------------

variable z;
positive variable a11,a22;
variable a12, center(c), pc(i,c);

* initial values A
a11.l = 1/ir2;
a22.l = 1/ir2;
a12.l = 0;
z.l = a11.l*a22.l-sqr(a12.l);

* initial values center
center.l(c) = ic(c);
pc.l(j(i),c) = p(i,c) - center.l(c);

Equations
   determinant 'det(A)'
   pminc(i,c)  'p(i)-c'
   pinside(i)  'point p is inside ellipse' 
;

determinant..  z =e= a11*a22-sqr(a12);
pminc(j(i),c)..   pc(i,c) =e= p(i,c)-center(c);
pinside(j(i))..   a11*sqr(pc(i,'x'))+a22*sqr(pc(i,'y'))+2*a12*pc(i,'x')*pc(i,'y') =l= 1;

model m1 /all/;
solve m1 maximizing z using nlp;
  
display center.l,a11.l,a22.l,a12.l,z.l;
scalar Area;
Area = pi/sqrt(z.l);
display Area;

*----------------------------------------------------------------------
* formulation 2
* max det(A)
* s.t. ||Ap+b|| <= 1
*----------------------------------------------------------------------

variable ap1(i),ap2(i);
variable b(c);

* initial values A
a11.l = 1/sqrt(ir2);
a22.l = 1/sqrt(ir2);
a12.l = 0;
z.l = a11.l*a22.l-sqr(a12.l);

* initial values b = -A*center
b.l('x') = -a11.l*ic('x')-a12.l*ic('y');
b.l('y') = -a12.l*ic('x')-a22.l*ic('y');

* initial values ap = Ap+b
ap1.l(j(i)) = a11.l*p(i,'x')+a12.l*p(i,'y') + b.l('x');
ap2.l(j(i)) = a12.l*p(i,'x')+a22.l*p(i,'y') + b.l('y');

equations
   defap1(i)   'first element of Ap+b'
   defap2(i)   'second element of Ap+b'
   pinside2(i)
;


defap1(j(i))..     ap1(i) =e= a11*p(i,'x')+a12*p(i,'y') + b('x');
defap2(j(i))..     ap2(i) =e= a12*p(i,'x')+a22*p(i,'y') + b('y');
pinside2(j(i))..   sqr(ap1(i)) + sqr(ap2(i)) =l= 1;
 
model m2 /determinant,defap1,defap2,pinside2/;
solve m2 maximizing z using nlp;

display a11.l,a22.l,a12.l,b.l,z.l;
scalar Area;
Area = pi/z.l;
display Area;
