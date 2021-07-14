# Compare QP (risk in objective) with QCP (risk in constraints)

This model tries to compare a standard portfolio model:

    min risk 
    return >= minreturn
 
and 

    max return
    risk <= maxrisk  
    
The first is a QP and the second model is a QCP model. We also try a cardinality constrained version.

Reference: https://yetanothermathprogrammingconsultant.blogspot.com/2021/06/portfolio-optimization-with-risk-as.html
