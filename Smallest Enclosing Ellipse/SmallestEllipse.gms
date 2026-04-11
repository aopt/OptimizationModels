$onText


   min area = π/det(A)
   ||Ap + b || <= 1
   A pos def

1. A is symmetric, so we just use a11,a12,a22

2. Objective
   replace obj by max sqrt(det(A))
   then we can form max t, t^2 + a12^2 <= a11*a22, a11,a22>=0
   this is a rotated second order cone

3. ||Ap + b|| <= 1 is ok: it is convex.
   Use intermediate variables to convey this to the solver.
   
4. A is pos.def.
   Constraints: a11,a22 >= 0
                a11*a22 - a12^2 >= 0
   This is already taken care of by 2.             

$offText

option qcp = cplex;
 
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
* socp model
*----------------------------------------------------------------------

variable
   t 'objective'
* matrix A is 2x2 and symmetric   
   a11,a12,a22
   ap1(i),ap2(i)
   b(c)
;
* diagonal elements of A should be >= 0
positive variable a11,a22;

equations
   rcone       'rotated cone for objective'
   q(i)        '||Ap+b||<=1'
   defap1(i)   'first element of Ap+b'
   defap2(i)   'second element of Ap+b'
;

rcone..        sqr(t) + sqr(a12) =l= a11*a22;

defap1(i)..    ap1(i) =e= a11*p(i,'x')+a12*p(i,'y') + b('x');
defap2(i)..    ap2(i) =e= a12*p(i,'x')+a22*p(i,'y') + b('y');
q(i)..         sqr(ap1(i)) + sqr(ap2(i)) =l= 1;

model m /all/;

solve m maximizing t using qcp;

*----------------------------------------------------------------------
* reporting
*----------------------------------------------------------------------

scalar
  detA 'determinant of A'
  area
;

detA = a11.l*a22.l-sqr(a12.l);
area = pi / detA;

display a11.l,a12.l,a22.l,b.l,t.l,detA,area;

