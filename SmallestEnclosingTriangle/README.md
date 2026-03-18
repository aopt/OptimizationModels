# Smallest Enclosing Triangle


`triangle.gms`

Given $n$ points (in 2d space), find the smallest triangle (in term of area) that contains all points.
Global NLP solvers have problems with this model: the lower bound does not move away from 0.

`triangle_all.gms`

Use different formulations to see if we can get better performance. When using a different
definition of size of the triangle, we can prove optimality for an $n=50$ data set.



References:
- http://yetanothermathprogrammingconsultant.blogspot.com/2023/01/tiny-non-convex-quadratic-model-brings.html
- https://yetanothermathprogrammingconsultant.blogspot.com/2026/03/revisiting-crazy-global-nlp-problem.html