# Smallest Enclosing Circle and Ellipse

See: https://yetanothermathprogrammingconsultant.blogspot.com/2026/04/minimum-enclosing-ellipse.html

## Files


| File | Description |
|------|------|
| `SmallestCircle.gms` | Find smallest circle containing $n$ given points. The NLP formulation uses a good starting point. A convex conic model is also presented. |
| `sdp example.ipynb`  | Find smallest enclosing ellipse. SDP formulation solved with CVXPY/SCS. |
| `SmallestEllipse.gms` | SOCP Formulation using GAMS/Cplex. |
| `SmallestEllipseNLP.gms` | NLP Formulation using GAMS/Conopt. Use same starting point as `SmallestCircle.gms`. |


