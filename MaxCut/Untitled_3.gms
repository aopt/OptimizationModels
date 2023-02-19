binary variables x1,x2;
variable z;
equations
  obj
  e;

obj.. z =e= x1;
e.. x1*x2 =e= 1;

model m /all/;
option miqcp=gurobi;
solve m maximizing z using miqcp;
