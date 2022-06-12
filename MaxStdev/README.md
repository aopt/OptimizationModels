## Maximum Standard Deviation

This is a small problem: **maximize** the standard deviation of a variable `x(i)` subject to bounds and a linear side constraint. This is a nonconvex problem.

We try five different models:
1. Nonconvex QP
2. Linear approximation model with SOS1 variables. This model has enormous problems.
3. As 2. but with a bound on the objective.
4. As 2. but with a bound on the s(i,+/-) variables.
5. Linear approximation model with binary variables.


Reference:
http://yetanothermathprogrammingconsultant.blogspot.com/2022/06/maximizing-standard-deviation.html
