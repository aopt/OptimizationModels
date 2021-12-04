$ontext

  Enumerate all optimal LP bases
  Use Cplex solution pool

$offtext


Sets
     k                       /seattle, san-diego, new-york, chicago, topeka/
     i(k)   canning plants   / seattle, san-diego /
     j(k)   markets          / new-york, chicago, topeka /
;

Parameters

     a(i)  capacity of plant i in cases
       /    seattle     350
            san-diego   600  /

     b(j)  demand at market j in cases
       /    new-york    325
            chicago     300
            topeka      275  / ;

Table d(i,j)  distance in thousands of miles
                  new-york       chicago      topeka
    seattle          2.5           1.7          1.8
    san-diego        2.5           1.8          1.4  ;

Scalar f  freight in dollars per case per thousand miles  /90/ ;

Parameter c(i,j)  transport cost in thousands of dollars per case ;

          c(i,j) = f * d(i,j) / 1000 ;
Scalars
     nb  'number of basic variables'
     nnb 'number of non-basic variables'
  ;
nb = card(i)+card(j);
nnb = card(i)*card(j);

parameter Mx(i,j), Mk(k);
Mx(i,j) = min(a(i),b(j));
Mk(i) = a(i);
Mk(j) = b(j);

set bs(*,*);
bs(i,j)=yes;
bs('-',k) = yes;

Variables
     x(i,j)  shipment quantities in cases
     z       total transportation costs in thousands of dollars
     s(k)       'slacks'
     beta(*,*)  'basis'
;

Positive Variable x,s;
Binary Variable beta;

Equations
     cost        define objective function
     supply(i)   observe supply limit at plant i
     demand(j)   satisfy demand at market j
     basisx(i,j)  'x=nb => x=0'
     basiss(k)    's=nb => s=0'
     basis        'basis accounting'
;

cost ..        z  =e=  sum((i,j), c(i,j)*x(i,j)) ;
supply(i) ..   sum(j, x(i,j)) + s(i) =e=  a(i) ;
demand(j) ..   sum(i, x(i,j)) - s(j) =e=  b(j) ;

basis..        sum(bs,beta(bs)) =e= nb;
basisx(i,j)..  x(i,j) =l= Mx(i,j)*beta(i,j);
basiss(k)..    s(k) =l= Mk(k)*beta('-',k);

Model transport /all/ ;

option optcr=0;
option mip=cplex;

$onecho > cplex.opt
SolnPoolAGap = 0.0
SolnPoolIntensity = 4
PopulateLim = 10000
SolnPoolPop = 2
solnpoolmerge solutions.gdx
$offecho

transport.optfile=1;
Solve transport using mip minimizing z ;

*
* read solutions from solutions.gdx
* produce similar report as in trnsportall.gms
*

sets
  idx 'long name' /soln_transport_p1*soln_transport_p100/
  shrt 'short name' /p1*p100/
  mapidx(idx,shrt) /#idx:#shrt/
  index(idx)
;
parameters xs(idx,i,j),ss(idx,k),zs(idx),betas(idx,*,*);
execute_load "solutions.gdx",xs=x,ss=s,zs=z,betas=beta,index;

parameter reportv(*,*,*,*);
parameter reportb(*,*,*,*);
option reportv:2:3:1;
option reportb:0:3:1;

loop(mapidx(index,shrt),
  reportv('x',i,j,shrt) =  xs(index,i,j);
  reportv('s','-',k,shrt) = ss(index,k);
  reportv('z','-','-',shrt) = zs(index);
  reportb('x',i,j,shrt) = betas(index,i,j);
  reportb('s','-',k,shrt) = betas(index,'-',k);
);

Display reportv, reportb;
