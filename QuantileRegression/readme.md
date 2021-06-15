# Quantile Regression

These are GAMS models that derive informally the LP mode that implements a Quantile Regression problem.

We have:

1. MedianNLP.gms. This is a simple, but nasty NLP model to find the median of a data vector.
2. MedianLP.gms. This is the correct way to calculate the median: LP version with two different formulations for the absolute value.
3. Quantiles.gms. Extending the previous LP model, we show here how to calculate quantiles of a data vector.
4. QuantileRegression.gms. This is the final model that implements a Quantile Regression problem.

A complete description can be found here: https://yetanothermathprogrammingconsultant.blogspot.com/2021/06/median-quantiles-and-quantile.html
