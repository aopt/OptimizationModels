$ontext

   LCP - linear complementarity problem


   find w,x such that
      w,x >= 0
      x'w = 0
      w = Mx + q

   assumption: M is pos def

   Solve in different ways (all but using an LCP solver).

   See:
   https://en.wikipedia.org/wiki/Linear_complementarity_problem
   https://yetanothermathprogrammingconsultant.blogspot.com/2021/05/solving-linear-complementarity-problems.html


   erwin@amsterdamoptimization.com

$offtext


*---------------------------------------------------------
* random data
*---------------------------------------------------------

set
  i /i1*i10/
;

alias (i,j,k);

parameter M(i,j) 'positive definite matrix';
M(i,j) = uniform(-10,10);
M(i,j) = sum(k, M(k,i)*M(k,j));

parameter q(i);
q(i) = uniform(-100,100);

*---------------------------------------------------------
* solve with MCP solver
*
*   find x such that
*        x >= 0 perp Mx + q >= 0
*---------------------------------------------------------

positive variable x(i);
equation e(i);

e(i).. sum(j, M(i,j)*x(j)) + q(i) =g= 0;

model lcp1 /e.x/;
option mcp=path;
solve lcp1 using mcp;

parameter results(i,*);
results(i,'x') = x.l(i);
results(i,'w') = sum(j, M(i,j)*x.l(j)) + q(i);
display results;


*---------------------------------------------------------
* solve with QP solver
*
*   min x'(Mx+q)
*      Mx + q >= 0
*      x >= 0
*---------------------------------------------------------

variable z 'objective';
equations
  qpobj
  qpcon(i)
;

qpobj.. z =e= sum((i,j),M(i,j)*x(i)*x(j)) + sum(i,x(i)*q(i));
qpcon(i).. sum(j,M(i,j)*x(j)) + q(i) =g= 0;

model lcp2 /qpobj,qpcon/;
option qcp=cplex;
solve lcp2 using qcp minimizing z;

results(i,'x') = x.l(i);
results(i,'w') = sum(j, M(i,j)*x.l(j)) + q(i);
display results;


*---------------------------------------------------------
* solve with a conic solver
*
*      x'Mx <= -x'q
*      Mx + q >= 0
*      x >= 0
*---------------------------------------------------------

equations
   edummy
   qcpcon
;

edummy.. z =e= 0;
qcpcon.. sum((i,j),x(i)*M(i,j)*x(j)) + sum(i,x(i)*q(i)) =l= 0;

model lcp3 /edummy,qcpcon,qpcon/;
option qcp=cplex;
solve lcp3 using qcp minimizing z;

results(i,'x') = x.l(i);
results(i,'w') = sum(j, M(i,j)*x.l(j)) + q(i);
display results;


*---------------------------------------------------------
* solve with MIP solver
*
*      x(i) <= d(i) * x.up(i)
*      w(i) <= (1-d(i)) * w.up(i)
*      w = Mx + q
*      x,w >= 0
*---------------------------------------------------------

binary variable d(i);
positive variable w(i);
equation
  wdef(i)
  xbnd(i)
  wbnd(i)
;

x.up(i) = 1000;
w.up(i) = 1000;

xbnd(i).. x(i) =l= d(i)*x.up(i);
wbnd(i).. w(i) =l= (1-d(i))*w.up(i);

wdef(i).. w(i) =e= sum(j, M(i,j)*x(j)) + q(i);

model lcp4 /edummy,xbnd,wbnd,wdef/;
solve lcp4 using mip minimizing z;

results(i,'x') = x.l(i);
results(i,'w') = w.l(i);
display results;

* remove bounds
x.up(i) = inf;
w.up(i) = inf;


*---------------------------------------------------------
* solve with MIP solver using indicator constraints
* Embarrassingly, this is very awkward to do in GAMS.
*
*      d(i) = 0 => x(i) = 0
*      d(i) = 1 => w(i) = 0
*      w = Mx + q
*      x,w >= 0
*---------------------------------------------------------

equations
   xzero(i)
   wzero(i)
   edummy2 'need to have d in the model somewhere'
;
xzero(i).. x(i) =e= 0;
wzero(i).. w(i) =e= 0;
edummy2.. sum(i, d(i)) =g= 0;

$onecho > cplex.opt
indic xzero(i)$d(i) 0
indic wzero(i)$d(i) 1
$offecho

model lcp5 /edummy,xzero,wzero,wdef,edummy2/;
lcp5.optfile=1;
option mip=cplex;
solve lcp5 using mip minimizing z;

results(i,'x') = x.l(i);
results(i,'w') = w.l(i);
display results;

*---------------------------------------------------------
* solve with MIP solver using SOS1 sets
*
*      x(i),w(i) in SOS1
*      w = Mx + q
*      x,w >= 0
*---------------------------------------------------------

set s /x,w/;
sos1 variable xw(i,s);

equation wdef2(i);

wdef2(i).. xw(i,'w') =e= sum(j, M(i,j)*xw(j,'x')) + q(i);

model lcp6 /edummy,wdef2/;
solve lcp6 using mip minimizing z;

display xw.l;
