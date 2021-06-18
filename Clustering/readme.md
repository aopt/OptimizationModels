# Clustering Models

This directory contains some clustering models.

1. k-means. This is a standard clustering model. In statistical packages heuristics are used. With good reason: this is a difficult model to solve to optimality using off-the-shelf MIQP solvers.
2. k-medoids. This is clustering model where the center is a data point. The optimization model is a linear MIP model. Not all solvers have an easy time with this model.

Reference: https://yetanothermathprogrammingconsultant.blogspot.com/2021/05/clustering-models.html
