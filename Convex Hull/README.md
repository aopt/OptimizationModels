# Convex Hull

Given $n$ 2d points, find the convex hull.

Three methods are used:
  1. A convex hull algorithm from `scipy`
  2. An MINLP model
  3. A linear MIP model


# References

https://yetanothermathprogrammingconsultant.blogspot.com/2026/04/convex-hull-models.html


# Files

| File    | Description |
|-------  | ----------------------|
| `convexhull.gms`      | Scipy, MINLP and MIP model | 
| `convexhullplot.gms`  | Plot convex hull |
| `convexhull_loop.gms` | Calculate convex hull in batches |
